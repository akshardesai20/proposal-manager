// Sends outbound email — offer PDFs and follow-ups — via SMTP.
//
// Reuses the same Gmail account/App Password already configured for
// inbound polling (INBOX_IMAP_USER/PASSWORD) by default, since Gmail's
// same App Password works for both IMAP (receiving) and SMTP (sending).
// Override with OUTBOUND_SMTP_USER/PASSWORD if you ever want a different
// sending account than the one being polled.
import nodemailer from "nodemailer";

function getConfig() {
  const host = process.env.OUTBOUND_SMTP_HOST || "smtp.gmail.com";
  const port = Number(process.env.OUTBOUND_SMTP_PORT) || 587;
  const user = process.env.OUTBOUND_SMTP_USER || process.env.INBOX_IMAP_USER;
  const pass = process.env.OUTBOUND_SMTP_PASSWORD || process.env.INBOX_IMAP_PASSWORD;
  if (!user || !pass) {
    throw new Error(
      "Outbound email is not configured — set OUTBOUND_SMTP_USER/OUTBOUND_SMTP_PASSWORD, " +
      "or INBOX_IMAP_USER/INBOX_IMAP_PASSWORD if reusing the same mailbox."
    );
  }
  return { host, port, user, pass };
}

// to, subject, text: required. html: optional richer body (falls back to
// text). attachments: nodemailer's format, e.g. [{ filename, content: Buffer }].
// inReplyTo: an outbound email's own message_id, if this is meant to
// thread as a reply (used for follow-ups referencing an earlier email).
// Returns { messageId } — save this against the case_emails row so a
// customer's reply can later be matched back via its In-Reply-To header.
export async function sendMail({ to, subject, text, html, attachments, inReplyTo }) {
  const { host, port, user, pass } = getConfig();
  const transporter = nodemailer.createTransport({
    host, port, secure: port === 465, auth: { user, pass },
  });

  const info = await transporter.sendMail({
    from: user,
    to,
    subject,
    text,
    html: html || undefined,
    attachments: attachments || undefined,
    inReplyTo: inReplyTo || undefined,
    references: inReplyTo || undefined,
  });

  return { messageId: info.messageId };
}
