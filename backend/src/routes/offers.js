import { Router } from "express";
import PDFDocument from "pdfkit";
import { pool, query } from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { writeOfferPdf, STANDARD_TERMS } from "../pdf/offerPdf.js";
import { companyProfile } from "../config/companyProfile.js";

const router = Router();
router.use(requireAuth);

const STAGE_ORDER = ["enquiry", "costing", "costing_complete", "offer_prepared", "offer_sent", "negotiation", "negotiation_complete", "won", "lost"];

// POST /api/cases/:caseId/offer — generate a new offer, or the next
// revision if one already exists for this case. The running reference
// number (SI/nnnn/...) is allocated once per case and reused across
// revisions (R0 -> R1 -> R2); only the revision number increments.
router.post("/cases/:caseId/offer", async (req, res) => {
  const { caseId } = req.params;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const caseRow = (await client.query(
      `SELECT c.*, cu.name AS customer_name, cu.code AS customer_code
       FROM cases c JOIN customers cu ON cu.id = c.customer_id WHERE c.id = $1 FOR UPDATE`,
      [caseId]
    )).rows[0];
    if (!caseRow) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Case not found" });
    }

    const items = (await client.query(
      `SELECT * FROM costing_items WHERE case_id = $1 ORDER BY sort_order, id`, [caseId]
    )).rows;
    if (!items.length) {
      await client.query("ROLLBACK");
      return res.status(400).json({ error: "Add at least one costing line before generating an offer" });
    }

    // The offer's number is whatever the case's own reference is — the
    // exact same value shown in the Cases list (custom-set, or the default
    // CASE-0001 format if never customized). This used to be a separate
    // auto-incrementing counter (offer_sequence); that's no longer used for
    // ref numbering so the two can't drift apart — one number, one source.
    const caseRef = caseRow.reference || `CASE-${String(caseRow.id).padStart(4, "0")}`;
    const prev = (await client.query(
      `SELECT COALESCE(MAX(revision), -1) AS r FROM offers WHERE case_id = $1`, [caseId]
    )).rows[0];
    const revision = prev.r + 1;

    const codeForRef = (caseRow.customer_code || caseRow.customer_name || "CUSTOMER")
      .toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 20) || "CUSTOMER";
    const ref = `SI/${caseRef}/${codeForRef}/R${revision}`;

    const itemsSnapshot = items.map((it) => ({
      description: it.description, instrument_name: it.instrument_name, product_name: it.product_name,
      range_value: it.range_value, qty: it.qty, final_unit_price: it.final_unit_price, model_code: it.model_code,
    }));

    const offerRow = (await client.query(
      `INSERT INTO offers (case_id, ref, revision, prepared_by, items_snapshot, terms_snapshot, notes_snapshot, generated_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7, now()) RETURNING *`,
      [caseId, ref, revision, req.user.id, JSON.stringify(itemsSnapshot), JSON.stringify(STANDARD_TERMS), caseRow.notes || null]
    )).rows[0];

    // Only move the stage forward — generating a later revision on a case
    // that's already progressed (e.g. Negotiation) shouldn't push it back.
    if (STAGE_ORDER.indexOf(caseRow.stage) < STAGE_ORDER.indexOf("offer_prepared")) {
      await client.query(`UPDATE cases SET stage = 'offer_prepared', offer_prepared_at = now() WHERE id = $1`, [caseId]);
      await client.query(
        `INSERT INTO case_events (case_id, from_stage, to_stage, changed_by, note)
         VALUES ($1,$2,'offer_prepared',$3,'Offer generated')`,
        [caseId, caseRow.stage, req.user.id]
      );
    }

    await client.query("COMMIT");
    res.status(201).json(offerRow);
  } catch (err) {
    await client.query("ROLLBACK");
    console.error(err);
    res.status(500).json({ error: "Failed to generate offer" });
  } finally {
    client.release();
  }
});

// GET /api/cases/:caseId/offers — revision history
router.get("/cases/:caseId/offers", async (req, res) => {
  const { rows } = await query(
    `SELECT o.id, o.ref, o.revision, o.generated_at, u.name AS prepared_by_name
     FROM offers o LEFT JOIN users u ON u.id = o.prepared_by
     WHERE o.case_id = $1 ORDER BY o.revision DESC`,
    [req.params.caseId]
  );
  res.json(rows);
});

// GET /api/offers/:id/pdf — regenerates the PDF from the stored snapshot
// on every request (no file storage needed since the snapshot is durable).
router.get("/offers/:id/pdf", async (req, res) => {
  const offer = (await query(`SELECT * FROM offers WHERE id = $1`, [req.params.id])).rows[0];
  if (!offer) return res.status(404).json({ error: "Offer not found" });

  const caseRow = (await query(
    `SELECT c.requirement_text, cu.name AS customer_name, cu.contact_person, cu.address, cu.gst_number
     FROM cases c JOIN customers cu ON cu.id = c.customer_id WHERE c.id = $1`,
    [offer.case_id]
  )).rows[0];

  const preparedByRow = (await query(
    `SELECT name, designation, phone, email FROM users WHERE id = $1`, [offer.prepared_by]
  )).rows[0] || { name: companyProfile.name };

  res.setHeader("Content-Type", "application/pdf");
  res.setHeader("Content-Disposition", `inline; filename="${offer.ref.replace(/\//g, "-")}.pdf"`);

  const doc = new PDFDocument({ size: "A4", margin: 50 });
  doc.pipe(res);
  writeOfferPdf(doc, {
    ref: offer.ref,
    revision: offer.revision,
    date: new Date(offer.generated_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
    customer: caseRow,
    requirementText: caseRow.requirement_text,
    items: offer.items_snapshot,
    preparedBy: preparedByRow,
    terms: offer.terms_snapshot,
    notes: offer.notes_snapshot,
  });
  doc.end();
});

// DELETE /api/offers/:id — admin only. Doesn't touch the case's stage;
// just removes this particular generated revision.
router.delete("/offers/:id", requireRole("admin"), async (req, res) => {
  const { rows } = await query(`DELETE FROM offers WHERE id = $1 RETURNING id`, [req.params.id]);
  if (!rows[0]) return res.status(404).json({ error: "Offer not found" });
  res.status(204).end();
});

export default router;
