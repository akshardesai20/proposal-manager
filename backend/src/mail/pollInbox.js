// Polls the existing business mailbox over IMAP for new (unseen) messages
// and drops each one into the inbound_inquiries review queue. Nothing is
// auto-converted into a case — see migration 013 for why.
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
import { analyzeInquiry } from "../ai/analyzeInquiry.js";

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

          if (inserted.rows.length) {
            created++;
            // Enrichment, not a requirement — a failure here (bad/missing
            // API key, rate limit, model hiccup) must never break email
            // capture itself. The inquiry is already safely in the review
            // queue at this point regardless of what happens next.
            const inquiryId = inserted.rows[0].id;
            try {
              const ai = await analyzeInquiry({ fromName, fromEmail: fromAddr, subject: parsed.subject, bodyText });
              await query(
                `UPDATE inbound_inquiries SET
                   ai_summary = $1, ai_industry_type = $2, ai_suggested_segment = $3,
                   ai_suggested_customer_name = $4, ai_email_type = $5, ai_analyzed_at = $6, ai_error = $7
                 WHERE id = $8`,
                [
                  ai.summary || null, ai.industry_type || null, ai.suggested_segment || null,
                  ai.suggested_customer_name || null, ai.email_type || null,
                  ai.error ? null : ai.analyzed_at, ai.error || null, inquiryId,
                ]
              );
            } catch (aiErr) {
              // Even the UPDATE failing shouldn't surface as a poll error —
              // log it via the errors array but keep going.
              errors.push({ uid, message: `AI analysis failed: ${aiErr.message}` });
            }
          } else {
            skipped++;
          }

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
