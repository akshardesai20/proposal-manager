// Polls the existing business mailbox over IMAP for new (unseen) messages.
// Each one is checked against cases already being tracked:
//
//   1. Header-based threading (reliable): if the email's In-Reply-To or
//      References header matches the message_id of something we sent
//      from a case (case_emails), or the message_uid of the original
//      inquiry that became a case (inbound_inquiries.created_case_id),
//      it's attached directly to that case's Emails thread.
//   2. Sender fallback (safe, not guessed): if no header match, but the
//      sender's address belongs to an existing customer who has exactly
//      one open (not won/lost) case, attach it there too — one case, one
//      customer, no ambiguity. If a customer has multiple open cases,
//      this is deliberately skipped rather than guessing wrong.
//   3. Otherwise, same as before: lands in the inbound_inquiries review
//      queue — see migration 013 for why nothing is auto-converted.
//
// AI classification of a matched email (negotiation vs order vs other) is
// NOT run here either — on-demand only, via the case's Emails section.
//
// Configuration (Render env vars):
//   INBOX_IMAP_HOST      e.g. mail.yourcompany.com — ask your host/cPanel for
//                         the exact mail server hostname if unsure.
//   INBOX_IMAP_PORT      defaults to 993 (IMAP over implicit SSL/TLS)
//   INBOX_IMAP_USER      the full mailbox address to poll
//   INBOX_IMAP_PASSWORD  the mailbox password
//   INBOX_IMAP_FOLDER    defaults to "INBOX"
//   INBOX_IMAP_SECURE    "true" (default) for implicit TLS on connect
//                         (typically port 993). Set to "false" if your
//                         host instead uses STARTTLS on a plaintext port
//                         (typically 143) — check cPanel's "Connect
//                         Devices" page for your mailbox to see which
//                         your host expects. A "Failed to receive
//                         greeting from server" error usually means this
//                         is set wrong for your host, or the hostname/port
//                         itself is wrong.
//
// This is triggered by an external scheduler hitting POST
// /api/internal/poll-inbox (see routes/inboxPoll.js) — Render's free tier
// sleeps the service after 15 minutes idle, so an in-process setInterval
// alone would not run reliably. A free service like cron-job.org hitting
// that endpoint every 10 minutes both wakes the service and triggers a
// poll in the same request.
import { ImapFlow } from "imapflow";
import { simpleParser } from "mailparser";
import { query } from "../db.js";

// Tries to find an existing case this inbound email belongs to. Returns a
// case id, or null if nothing matched (caller falls back to the review
// queue in that case).
export async function matchToExistingCase({ threadIds, fromAddr }) {
  if (threadIds.length) {
    const bySentEmail = await query(
      `SELECT case_id FROM case_emails WHERE message_id = ANY($1::text[]) LIMIT 1`,
      [threadIds]
    );
    if (bySentEmail.rows[0]) return bySentEmail.rows[0].case_id;

    const byOriginalInquiry = await query(
      `SELECT created_case_id AS case_id FROM inbound_inquiries
       WHERE message_uid = ANY($1::text[]) AND created_case_id IS NOT NULL LIMIT 1`,
      [threadIds]
    );
    if (byOriginalInquiry.rows[0]) return byOriginalInquiry.rows[0].case_id;
  }

  if (fromAddr) {
    const openCases = await query(
      `SELECT c.id FROM cases c JOIN customers cu ON cu.id = c.customer_id
       WHERE LOWER(cu.email) = LOWER($1) AND c.stage NOT IN ('won', 'lost')`,
      [fromAddr]
    );
    if (openCases.rows.length === 1) return openCases.rows[0].id;
  }

  return null;
}

export async function pollInbox() {
  const { INBOX_IMAP_HOST, INBOX_IMAP_PORT, INBOX_IMAP_USER, INBOX_IMAP_PASSWORD, INBOX_IMAP_FOLDER, INBOX_IMAP_SECURE } = process.env;
  if (!INBOX_IMAP_HOST || !INBOX_IMAP_USER || !INBOX_IMAP_PASSWORD) {
    throw new Error("Inbox polling is not configured — set INBOX_IMAP_HOST, INBOX_IMAP_USER, and INBOX_IMAP_PASSWORD");
  }

  const secure = INBOX_IMAP_SECURE !== "false"; // default true (implicit TLS, typically port 993)
  const client = new ImapFlow({
    host: INBOX_IMAP_HOST,
    port: Number(INBOX_IMAP_PORT) || 993,
    secure,
    // STARTTLS hosts (secure:false) still require an upgrade to TLS after
    // the plaintext greeting — imapflow does this automatically, but only
    // if it isn't told to skip it.
    requireTLS: !secure,
    auth: { user: INBOX_IMAP_USER, pass: INBOX_IMAP_PASSWORD },
    logger: false,
    greetingTimeout: 15000,
    socketTimeout: 30000,
  });

  let checked = 0, created = 0, skipped = 0;
  const errors = [];

  try {
    await client.connect();
  } catch (err) {
    if (/greeting/i.test(err.message)) {
      throw new Error(
        `${err.message} — this usually means INBOX_IMAP_HOST/PORT is wrong, or INBOX_IMAP_SECURE needs to be flipped ` +
        `(currently ${secure ? "true, i.e. implicit TLS on connect" : "false, i.e. STARTTLS"}). ` +
        `Check cPanel's "Connect Devices" page for the exact settings your host expects.`
      );
    }
    throw err;
  }
  try {
    const lock = await client.getMailboxLock(INBOX_IMAP_FOLDER || "INBOX");
    try {
      const uids = await client.search({ seen: false }, { uid: true });
      for (const uid of uids) {
        checked++;
        try {
          const msg = await client.fetchOne(uid, { source: true }, { uid: true });
          if (!msg || !msg.source) { skipped++; continue; }

          const parsed = await simpleParser(msg.source);
          // Message-ID is globally unique per email — falls back to a
          // uid+mailbox composite on the rare message that lacks one.
          const messageUid = parsed.messageId || `${INBOX_IMAP_USER}-uid-${uid}`;
          const fromAddr = parsed.from?.value?.[0]?.address || null;
          const fromName = parsed.from?.value?.[0]?.name || null;
          const bodyText = (parsed.text || "").trim().slice(0, 20000);
          const threadIds = [parsed.inReplyTo, ...(parsed.references || [])].filter(Boolean);

          const matchedCaseId = await matchToExistingCase({ threadIds, fromAddr });

          if (matchedCaseId) {
            const inserted = await query(
              `INSERT INTO case_emails (case_id, direction, to_email, from_email, subject, body, message_id, in_reply_to)
               VALUES ($1,'inbound',$2,$3,$4,$5,$6,$7)
               ON CONFLICT (message_id) DO NOTHING
               RETURNING id`,
              [matchedCaseId, INBOX_IMAP_USER, fromAddr, parsed.subject || null, bodyText, messageUid, parsed.inReplyTo || null]
            );
            if (inserted.rows.length) created++; else skipped++;
            await client.messageFlagsAdd(uid, ["\\Seen"], { uid: true });
            continue;
          }

          let matchedCustomerId = null;
          if (fromAddr) {
            const match = await query(`SELECT id FROM customers WHERE LOWER(email) = LOWER($1) LIMIT 1`, [fromAddr]);
            matchedCustomerId = match.rows[0]?.id || null;
          }

          const inserted = await query(
            `INSERT INTO inbound_inquiries (message_uid, from_email, from_name, subject, body_text, received_at, matched_customer_id)
             VALUES ($1,$2,$3,$4,$5,$6,$7)
             ON CONFLICT (message_uid) DO NOTHING
             RETURNING id`,
            [messageUid, fromAddr, fromName, parsed.subject || null, bodyText, parsed.date || new Date(), matchedCustomerId]
          );

          if (inserted.rows.length) created++; else skipped++;

          // Mark as seen either way, so a message that failed to insert
          // (e.g. a genuine duplicate) doesn't get re-fetched forever.
          await client.messageFlagsAdd(uid, ["\\Seen"], { uid: true });
        } catch (err) {
          errors.push({ uid, message: err.message });
        }
      }
    } finally {
      lock.release();
    }
  } finally {
    await client.logout().catch(() => {});
  }

  return { checked, created, skipped, errors };
}
