import { Router } from "express";
import { pool } from "../db.js";
import { seedDemoData } from "../demo/seedDemoData.js";

const router = Router();

// Same pattern as routes/inboxPoll.js: not behind requireAuth, since this
// needs to be callable before any user account exists yet. Protected by a
// shared secret instead. Hit this exactly once after first deploying a
// demo instance — it's safe to call again by accident (the seed function
// checks for existing demo data and no-ops if found).
//
// IMPORTANT: this route only belongs in a dedicated demo deployment's
// codebase — never wire this into a real customer's production instance.
router.all("/seed-demo-data", async (req, res) => {
  const expected = process.env.DEMO_SEED_SECRET;
  if (!expected) {
    return res.status(503).json({ error: "DEMO_SEED_SECRET is not configured on the server" });
  }
  const provided = req.query.secret || req.header("x-seed-secret");
  if (provided !== expected) {
    return res.status(401).json({ error: "Invalid or missing secret" });
  }

  try {
    const result = await seedDemoData(pool);
    res.json({ ok: true, ...result });
  } catch (err) {
    console.error("[seed-demo-data]", err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

export default router;
