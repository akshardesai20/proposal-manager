import { Router } from "express";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import { query } from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth);
router.use(requireRole("admin")); // this entire section is admin-only

const ROLES = ["admin", "sales", "proposal", "service", "store", "account"];

// GET /api/users
router.get("/", async (req, res) => {
  const { rows } = await query(
    `SELECT id, name, email, role, designation, phone, whatsapp, notifications_enabled, status, created_at
     FROM users ORDER BY name`
  );
  res.json(rows);
});

// POST /api/users — creates a new login. Returns a one-time temporary
// password if none was supplied, same pattern as the admin auto-seed.
router.post("/", async (req, res) => {
  const { name, email, role, whatsapp, notifications_enabled, status, password } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: "Name is required" });
  if (!email || !email.trim()) return res.status(400).json({ error: "Email is required" });
  if (!ROLES.includes(role)) return res.status(400).json({ error: `role must be one of ${ROLES.join(", ")}` });

  const generated = !password;
  const finalPassword = password || crypto.randomBytes(9).toString("base64url");
  const hash = await bcrypt.hash(finalPassword, 10);

  try {
    const { rows } = await query(
      `INSERT INTO users (name, email, password_hash, role, whatsapp, notifications_enabled, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING id, name, email, role, designation, phone, whatsapp, notifications_enabled, status, created_at`,
      [
        name.trim(), email.trim(), hash, role,
        whatsapp?.trim() || null, notifications_enabled ?? true, status || "active",
      ]
    );
    res.status(201).json({ ...rows[0], generatedPassword: generated ? finalPassword : null });
  } catch (err) {
    if (err.code === "23505") return res.status(409).json({ error: "A user with that email already exists" });
    console.error(err);
    res.status(500).json({ error: "Failed to create user" });
  }
});

// PATCH /api/users/:id
const UPDATABLE = ["name", "email", "role", "designation", "phone", "whatsapp", "notifications_enabled", "status"];
router.patch("/:id", async (req, res) => {
  if (req.body.role !== undefined && !ROLES.includes(req.body.role)) {
    return res.status(400).json({ error: `role must be one of ${ROLES.join(", ")}` });
  }

  const sets = [];
  const vals = [];
  let i = 1;
  for (const f of UPDATABLE) {
    if (req.body[f] !== undefined) {
      sets.push(`${f} = $${i}`);
      vals.push(typeof req.body[f] === "string" ? req.body[f].trim() : req.body[f]);
      i++;
    }
  }

  // Optional password reset in the same call.
  if (req.body.password) {
    const hash = await bcrypt.hash(req.body.password, 10);
    sets.push(`password_hash = $${i}`);
    vals.push(hash);
    i++;
  }

  if (!sets.length) return res.status(400).json({ error: "No updatable fields provided" });
  vals.push(req.params.id);

  try {
    const { rows } = await query(
      `UPDATE users SET ${sets.join(", ")} WHERE id = $${i}
       RETURNING id, name, email, role, designation, phone, whatsapp, notifications_enabled, status, created_at`,
      vals
    );
    if (!rows[0]) return res.status(404).json({ error: "User not found" });
    res.json(rows[0]);
  } catch (err) {
    if (err.code === "23505") return res.status(409).json({ error: "A user with that email already exists" });
    console.error(err);
    res.status(500).json({ error: "Failed to update user" });
  }
});

// DELETE /api/users/:id — hard-deletes only if the user has no case/offer
// history (foreign key references would block it). If they do have
// history, returns a clear message pointing at deactivation instead, so
// audit trails (who prepared which offer, who's handling which case)
// never silently break.
router.delete("/:id", async (req, res) => {
  if (String(req.user.id) === String(req.params.id)) {
    return res.status(400).json({ error: "You can't remove your own account while logged in as it." });
  }
  try {
    const { rows } = await query(`DELETE FROM users WHERE id = $1 RETURNING id`, [req.params.id]);
    if (!rows[0]) return res.status(404).json({ error: "User not found" });
    res.status(204).end();
  } catch (err) {
    if (err.code === "23503") {
      return res.status(409).json({
        error: "This user has case or offer history and can't be removed. Set their Status to Inactive instead.",
      });
    }
    console.error(err);
    res.status(500).json({ error: "Failed to remove user" });
  }
});

export default router;
