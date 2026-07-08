import { Router } from "express";
import { query, pool } from "../db.js";
import { requireAuth } from "../middleware/auth.js";
import { createCaseWithinTransaction } from "../cases/createCaseWithinTransaction.js";
import { analyzeInquiry } from "../ai/analyzeInquiry.js";

const router = Router();
router.use(requireAuth);

// GET /api/inquiries?status=pending — review queue, newest first.
// Defaults to pending only; pass status=all to see converted/dismissed too.
router.get("/", async (req, res) => {
  const status = req.query.status || "pending";
  const where = status === "all" ? "" : `WHERE i.status = $1`;
  const params = status === "all" ? [] : [status];
  const { rows } = await query(
    `SELECT i.*, cu.name AS matched_customer_name, aicu.name AS ai_matched_customer_name
     FROM inbound_inquiries i
     LEFT JOIN customers cu ON cu.id = i.matched_customer_id
     LEFT JOIN customers aicu ON aicu.id = i.ai_matched_customer_id
     ${where}
     ORDER BY i.received_at DESC`,
    params
  );
  res.json(rows);
});

// POST /api/inquiries/:id/convert — turns a pending inquiry into a real
// case. Body mirrors POST /api/cases: { customer, requirement_text,
// inquiry_type?, scheduled_offer_date?, segment? }. Reuses the exact same
// case-creation logic as the normal "+ New case" flow.
router.post("/:id/convert", async (req, res) => {
  const { customer, requirement_text, inquiry_type, scheduled_offer_date, segment } = req.body;
  if (!customer || (!customer.id && !customer.name)) {
    return res.status(400).json({ error: "customer.id or customer.name is required" });
  }
  if (segment && !["ww", "industries", "instrument_service"].includes(segment)) {
    return res.status(400).json({ error: "segment must be ww, industries, or instrument_service" });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const inquiry = (await client.query(
      `SELECT * FROM inbound_inquiries WHERE id = $1 FOR UPDATE`, [req.params.id]
    )).rows[0];
    if (!inquiry) { await client.query("ROLLBACK"); return res.status(404).json({ error: "Inquiry not found" }); }
    if (inquiry.status !== "pending") {
      await client.query("ROLLBACK");
      return res.status(409).json({ error: `This inquiry was already ${inquiry.status}` });
    }

    const created = await createCaseWithinTransaction(
      client, { customer, requirement_text, inquiry_type, scheduled_offer_date, segment }, req.user.id
    );

    await client.query(
      `UPDATE inbound_inquiries SET status = 'converted', created_case_id = $1 WHERE id = $2`,
      [created.id, req.params.id]
    );

    await client.query("COMMIT");
    res.status(201).json(created);
  } catch (err) {
    await client.query("ROLLBACK");
    console.error(err);
    res.status(500).json({ error: "Failed to convert inquiry" });
  } finally {
    client.release();
  }
});

// POST /api/inquiries/:id/analyze — manually (re-)run AI analysis on one
// inquiry. Useful if it wasn't configured yet at poll time, failed, or you
// just want a fresh pass. Overwrites any previous AI fields.
router.post("/:id/analyze", async (req, res) => {
  const inquiry = (await query(`SELECT * FROM inbound_inquiries WHERE id = $1`, [req.params.id])).rows[0];
  if (!inquiry) return res.status(404).json({ error: "Inquiry not found" });

  const ai = await analyzeInquiry({
    fromName: inquiry.from_name, fromEmail: inquiry.from_email,
    subject: inquiry.subject, bodyText: inquiry.body_text,
  });

  // Fuzzy customer match by NAME, separate from matched_customer_id
  // (which is an exact match on the sender's email address). Covers the
  // common case of someone emailing from a personal address whose
  // company is already in the system under a different contact. Strips
  // punctuation and common legal-entity suffixes (Pvt/Private/Ltd/
  // Limited/etc.) before comparing, so "Nish Techno Projects Pvt Ltd."
  // correctly matches an existing "Nish Techno Projects Private Limited"
  // — plain substring matching alone misses this since neither string
  // literally contains the other. Skipped entirely if there's already an
  // exact email match — no need to guess.
  let aiMatchedCustomerId = null;
  if (!inquiry.matched_customer_id && ai.suggested_customer_name) {
    const NORMALIZE = `regexp_replace(UPPER($1), '[^A-Z0-9]|PVT|PRIVATE|LIMITED|LTD|LLP|INC|CORP', '', 'g')`;
    const fuzzy = await query(
      `SELECT id FROM customers
       WHERE regexp_replace(UPPER(name), '[^A-Z0-9]|PVT|PRIVATE|LIMITED|LTD|LLP|INC|CORP', '', 'g') LIKE '%' || ${NORMALIZE} || '%'
          OR ${NORMALIZE} LIKE '%' || regexp_replace(UPPER(name), '[^A-Z0-9]|PVT|PRIVATE|LIMITED|LTD|LLP|INC|CORP', '', 'g') || '%'
       ORDER BY LENGTH(name) ASC LIMIT 1`,
      [ai.suggested_customer_name]
    );
    aiMatchedCustomerId = fuzzy.rows[0]?.id || null;
  }

  const { rows } = await query(
    `UPDATE inbound_inquiries SET
       ai_summary = $1, ai_industry_type = $2, ai_suggested_segment = $3,
       ai_suggested_customer_name = $4, ai_suggested_customer_phone = $5, ai_email_type = $6,
       ai_analyzed_at = $7, ai_error = $8, ai_matched_customer_id = $9
     WHERE id = $10 RETURNING *`,
    [
      ai.summary || null, ai.industry_type || null, ai.suggested_segment || null,
      ai.suggested_customer_name || null, ai.suggested_customer_phone || null, ai.email_type || null,
      ai.error ? null : ai.analyzed_at, ai.error || null, aiMatchedCustomerId, req.params.id,
    ]
  );

  if (ai.error) return res.status(502).json({ error: ai.error, inquiry: rows[0] });
  res.json(rows[0]);
});

// POST /api/inquiries/:id/dismiss — not every inbound email is a real
// inquiry (spam, newsletters, unrelated correspondence). This just marks
// it out of the queue without creating anything.
router.post("/:id/dismiss", async (req, res) => {
  const { rows } = await query(
    `UPDATE inbound_inquiries SET status = 'dismissed' WHERE id = $1 AND status = 'pending' RETURNING *`,
    [req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: "Inquiry not found or already handled" });
  res.json(rows[0]);
});

export default router;
