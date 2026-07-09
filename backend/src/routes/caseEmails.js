import { Router } from "express";
import { query } from "../db.js";
import { requireAuth } from "../middleware/auth.js";
import { sendMail } from "../mail/sendMail.js";
import { offerPdfBuffer } from "../pdf/offerPdf.js";
import { companyProfile } from "../config/companyProfile.js";

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

// POST /api/cases/:caseId/emails/send — body: { to, subject, body, offer_id? }
// offer_id is optional: when present, that offer's PDF is generated fresh
// and attached (same rendering as the download button). Records the sent
// email in case_emails either way, storing its message_id so a customer's
// reply can be auto-matched back to this case later.
caseEmailsRouter.post("/send", async (req, res) => {
  const { to, subject, body, offer_id } = req.body;
  if (!to || !to.trim()) return res.status(400).json({ error: "Recipient email is required" });
  if (!subject || !subject.trim()) return res.status(400).json({ error: "Subject is required" });
  if (!body || !body.trim()) return res.status(400).json({ error: "Email body is required" });

  let attachments;
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
    attachments = [{ filename: `${offer.ref.replace(/\//g, "-")}.pdf`, content: pdfBuffer }];
  }

  try {
    const { messageId } = await sendMail({ to: to.trim(), subject: subject.trim(), text: body, attachments });

    const { rows } = await query(
      `INSERT INTO case_emails (case_id, direction, to_email, from_email, subject, body, message_id, offer_id, created_by)
       VALUES ($1,'outbound',$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [
        req.params.caseId, to.trim(),
        process.env.OUTBOUND_SMTP_USER || process.env.INBOX_IMAP_USER || null,
        subject.trim(), body, messageId, offer_id || null, req.user.id,
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error("[case-emails:send]", err);
    res.status(502).json({ error: err.message || "Failed to send email" });
  }
});
