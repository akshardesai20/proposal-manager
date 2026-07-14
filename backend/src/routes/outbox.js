import { Router } from "express";
import { query } from "../db.js";
import { requireAuth } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth);

// GET /api/outbox — every outbound email across every case, newest
// first. Unlike GET /api/cases/:caseId/emails (scoped to one case), this
// is the cross-case tracking view: "did this actually go out," including
// failed attempts (see migration 022) which used to leave no trace at all.
router.get("/", async (req, res) => {
  const { rows } = await query(
    `SELECT e.*, c.reference, c.id AS case_id, cu.name AS customer_name, u.name AS created_by_name
     FROM case_emails e
     JOIN cases c ON c.id = e.case_id
     JOIN customers cu ON cu.id = c.customer_id
     LEFT JOIN users u ON u.id = e.created_by
     WHERE e.direction = 'outbound'
     ORDER BY e.created_at DESC`
  );
  res.json(rows);
});

export default router;
