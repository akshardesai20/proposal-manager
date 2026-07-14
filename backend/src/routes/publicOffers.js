import { Router } from "express";
import { query } from "../db.js";
import { companyProfile } from "../config/companyProfile.js";

// Deliberately NOT behind requireAuth — this is the one part of the app a
// customer accesses directly, with no login, via a link in the offer
// email. Security rests entirely on the token being long and random
// (see crypto.randomBytes(24) in offers.js) — treat it like a password,
// never log it, never expose it anywhere except the one email it's sent in.
const router = Router();

// GET /api/public/offers/:token — minimal, safe-to-show summary. No
// costing breakdown, no internal notes, no customer contact details
// beyond their own name — just enough for them to recognize the quote
// and confirm.
router.get("/:token", async (req, res) => {
  const offer = (await query(
    `SELECT o.ref, o.revision, o.items_snapshot, o.generated_at, o.accepted_at, o.accepted_by_name,
            c.id AS case_id, c.stage, cu.name AS customer_name
     FROM offers o
     JOIN cases c ON c.id = o.case_id
     JOIN customers cu ON cu.id = c.customer_id
     WHERE o.accept_token = $1`,
    [req.params.token]
  )).rows[0];

  if (!offer) return res.status(404).json({ error: "This quote link isn't valid. Please check the link or contact us directly." });

  const total = (offer.items_snapshot || []).reduce((sum, it) => sum + (Number(it.qty) || 0) * (Number(it.final_unit_price) || 0), 0);

  res.json({
    ref: offer.ref,
    revision: offer.revision,
    customerName: offer.customer_name,
    itemCount: (offer.items_snapshot || []).length,
    total,
    generatedAt: offer.generated_at,
    alreadyAccepted: !!offer.accepted_at,
    acceptedAt: offer.accepted_at,
    acceptedByName: offer.accepted_by_name,
    companyName: companyProfile.name,
  });
});

// POST /api/public/offers/:token/accept — body: { name }. Marks the offer
// accepted and moves the case to Won. Idempotent: accepting an
// already-accepted offer just returns the original acceptance rather than
// erroring or overwriting who/when — the first acceptance is the one that
// counts.
router.post("/:token/accept", async (req, res) => {
  const { name } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: "Please enter your name to confirm." });

  const offer = (await query(`SELECT * FROM offers WHERE accept_token = $1`, [req.params.token])).rows[0];
  if (!offer) return res.status(404).json({ error: "This quote link isn't valid." });

  if (offer.accepted_at) {
    return res.json({ alreadyAccepted: true, acceptedAt: offer.accepted_at, acceptedByName: offer.accepted_by_name });
  }

  const ip = (req.headers["x-forwarded-for"] || req.socket.remoteAddress || "").toString().split(",")[0].trim();

  await query(
    `UPDATE offers SET accepted_at = now(), accepted_by_name = $1, accepted_ip = $2 WHERE id = $3`,
    [name.trim(), ip || null, offer.id]
  );

  // Only move the case forward — if it's somehow already Won or Lost
  // (e.g. someone accepted after the case was separately marked Lost),
  // don't silently reopen or override that.
  const caseRow = (await query(`SELECT stage FROM cases WHERE id = $1`, [offer.case_id])).rows[0];
  if (caseRow && caseRow.stage !== "won" && caseRow.stage !== "lost") {
    await query(`UPDATE cases SET stage = 'won', outcome = 'won', closed_at = now() WHERE id = $1`, [offer.case_id]);
    await query(
      `INSERT INTO case_events (case_id, from_stage, to_stage, note) VALUES ($1, $2, 'won', 'Accepted online by customer')`,
      [offer.case_id, caseRow.stage]
    );
  }

  res.json({ alreadyAccepted: false, acceptedAt: new Date(), acceptedByName: name.trim() });
});

export default router;
