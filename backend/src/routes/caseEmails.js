import { Router } from "express";
import { query } from "../db.js";
import { requireAuth } from "../middleware/auth.js";
import { sendMail } from "../mail/sendMail.js";
import { offerPdfBuffer } from "../pdf/offerPdf.js";
import { companyProfile } from "../config/companyProfile.js";
import { buildSignature, textToHtml } from "../mail/emailSignature.js";
import { analyzeInquiry } from "../ai/analyzeInquiry.js";

// Mounted at /api/cases/:caseId/emails
export const caseEmailsRouter = Router({ mergeParams: true });
caseEmailsRouter.use(requireAuth);

// GET /api/cases/:caseId/emails — full thread (sent + auto-matched
// received), oldest first so it reads top-to-bottom like a conversation.
caseEmailsRouter.get("/", async (req, res) => {
  const { rows } = await query(
    `SELECT e.*, u.name AS created_by_name FROM case_emails e
     LEFT JOIN users u ON u.id = e.created_by
     WHERE e.case_id = $1 ORDER BY e.created_at ASC`,
    [req.params.caseId]
  );
  res.json(rows);
});

// POST /api/cases/:caseId/emails/send — body: { to, subject, body, offer_id?, in_reply_to? }
// offer_id is optional: when present, that offer's PDF is generated fresh
// and attached (same rendering as the download button). in_reply_to,
// when set, threads this as a reply to that Message-ID (typically the
// original inquiry email that started the case) — both in the actual
// email headers and by prefixing "Re:" onto the subject if not already
// present, so it lands in the customer's inbox as part of the same
// conversation instead of a brand-new email.
//
// The logged-in user's name/designation/phone/email — plus the company
// name and logo — are appended automatically as a signature; the body
// the frontend sends should just be the message itself, without a
// hand-typed sign-off.
caseEmailsRouter.post("/send", async (req, res) => {
  const { to, subject, body, offer_id, in_reply_to } = req.body;
  if (!to || !to.trim()) return res.status(400).json({ error: "Recipient email is required" });
  if (!subject || !subject.trim()) return res.status(400).json({ error: "Subject is required" });
  if (!body || !body.trim()) return res.status(400).json({ error: "Email body is required" });

  const sender = (await query(
    `SELECT name, designation, phone, email FROM users WHERE id = $1`, [req.user.id]
  )).rows[0] || { name: req.user.name };
  const signature = buildSignature(sender);

  const finalSubject = in_reply_to && !/^re:/i.test(subject.trim()) ? `Re: ${subject.trim()}` : subject.trim();
  const finalText = `${body.trimEnd()}${signature.text}`;
  const finalHtml = `<div style="font-family:Arial,sans-serif;font-size:13px;color:#222;">${textToHtml(body.trimEnd())}</div>${signature.html}`;

  const attachments = [];
  if (signature.logoAttachment) attachments.push(signature.logoAttachment);

  if (offer_id) {
    const offer = (await query(`SELECT * FROM offers WHERE id = $1 AND case_id = $2`, [offer_id, req.params.caseId])).rows[0];
    if (!offer) return res.status(404).json({ error: "Offer not found on this case" });

    const caseRow = (await query(
      `SELECT c.requirement_text, cu.name AS customer_name, cu.contact_person, cu.address, cu.gst_number
       FROM cases c JOIN customers cu ON cu.id = c.customer_id WHERE c.id = $1`,
      [req.params.caseId]
    )).rows[0];
    const preparedByRow = (await query(
      `SELECT name, designation, phone, email FROM users WHERE id = $1`, [offer.prepared_by]
    )).rows[0] || { name: companyProfile.name };

    const pdfBuffer = await offerPdfBuffer({
      ref: offer.ref, revision: offer.revision,
      date: new Date(offer.generated_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
      customer: caseRow, requirementText: caseRow.requirement_text,
      items: offer.items_snapshot, preparedBy: preparedByRow,
      terms: offer.terms_snapshot, notes: offer.notes_snapshot,
    });
    attachments.push({ filename: `${offer.ref.replace(/\//g, "-")}.pdf`, content: pdfBuffer });
  }

  // Separated from the DB insert below on purpose: whether this succeeds
  // or fails, we still want a record of the attempt — a failed send used
  // to just vanish with nothing persisted anywhere, which made the Outbox
  // useless for exactly the case it matters most (knowing something
  // didn't go out so it can be retried).
  let messageId = null;
  let sendError = null;
  try {
    // Defense in depth on top of sendMail.js's own SMTP-level timeouts —
    // guarantees this request always resolves within ~25s even if
    // something outside the SMTP handshake itself hangs (e.g. DNS).
    const result = await Promise.race([
      sendMail({
        to: to.trim(), subject: finalSubject, text: finalText, html: finalHtml,
        attachments: attachments.length ? attachments : undefined,
        inReplyTo: in_reply_to || undefined,
      }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Timed out after 25s trying to send — the mail server may be unreachable or slow to respond. Try again in a moment.")), 25000)
      ),
    ]);
    messageId = result.messageId;
  } catch (err) {
    console.error("[case-emails:send]", err);
    sendError = err.message || "Failed to send email";
  }

  const { rows } = await query(
    `INSERT INTO case_emails (case_id, direction, to_email, from_email, subject, body, message_id, in_reply_to, offer_id, created_by, status, error_message)
     VALUES ($1,'outbound',$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
    [
      req.params.caseId, to.trim(),
      process.env.OUTBOUND_SMTP_USER || process.env.INBOX_IMAP_USER || null,
      finalSubject, body, messageId, in_reply_to || null, offer_id || null, req.user.id,
      sendError ? "failed" : "sent", sendError,
    ]
  );

  if (sendError) return res.status(502).json({ error: sendError, email: rows[0] });
  res.status(201).json(rows[0]);
});

// POST /api/cases/:caseId/emails/:emailId/analyze — classifies an inbound
// email that got auto-matched to this case (see pollInbox.js): is it a
// follow-up, a negotiation, an order confirmation, or something else.
// On-demand only, same as inbound_inquiries — never automatic on poll.
// Only makes sense for inbound emails; outbound ones (things we sent)
// aren't classified.
caseEmailsRouter.post("/:emailId/analyze", async (req, res) => {
  const email = (await query(
    `SELECT * FROM case_emails WHERE id = $1 AND case_id = $2`, [req.params.emailId, req.params.caseId]
  )).rows[0];
  if (!email) return res.status(404).json({ error: "Email not found on this case" });
  if (email.direction !== "inbound") return res.status(400).json({ error: "Only inbound emails can be analyzed" });

  const catalogFamilies = (await query(
    `SELECT trade_name, family, instrument_type, description FROM siemens_families ORDER BY family`
  )).rows;

  const ai = await analyzeInquiry({
    fromName: null, fromEmail: email.from_email, subject: email.subject, bodyText: email.body,
    catalogFamilies,
  });

  const { rows } = await query(
    `UPDATE case_emails SET ai_summary = $1, ai_email_type = $2, ai_analyzed_at = $3, ai_error = $4, ai_model_recommendation = $5
     WHERE id = $6 RETURNING *`,
    [ai.summary || null, ai.email_type || null, ai.error ? null : ai.analyzed_at, ai.error || null, ai.recommended_models || null, req.params.emailId]
  );

  if (ai.error) return res.status(502).json({ error: ai.error, email: rows[0] });
  res.json(rows[0]);
});
