import { Router } from "express";
import { query } from "../db.js";
import { requireAuth } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth);

// GET /api/customers?q=search — empty q returns the full master list (up to 500)
router.get("/", async (req, res) => {
  const q = `%${(req.query.q || "").toUpperCase()}%`;
  const { rows } = await query(
    `SELECT * FROM customers
     WHERE UPPER(name) LIKE $1 OR UPPER(code) LIKE $1 OR UPPER(COALESCE(gst_number,'')) LIKE $1
     ORDER BY name LIMIT 500`,
    [q]
  );
  res.json(rows);
});

// Turns a Postgres unique_violation into a clear, field-specific message
// instead of a raw constraint name — e.g. "customers_code_key" becomes
// "A customer with this code already exists."
function friendlyDbError(err) {
  if (err.code === "23505") {
    if (err.constraint?.includes("code")) return "A customer with this code already exists — use a different code, or search for the existing one instead.";
    if (err.constraint?.includes("gst")) return "A customer with this GST number already exists — search for the existing one instead.";
    return "A customer with these details already exists.";
  }
  return null;
}

// POST /api/customers - adds to the master list, independent of any case
router.post("/", async (req, res) => {
  const { name, code, contact_person, email, phone, address, gst_number } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: "Customer name is required" });

  try {
    const { rows } = await query(
      `INSERT INTO customers (name, code, contact_person, email, phone, address, gst_number)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [
        name.trim(), code?.trim() || null, contact_person?.trim() || null,
        email?.trim() || null, phone?.trim() || null, address?.trim() || null, gst_number?.trim() || null,
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    const friendly = friendlyDbError(err);
    if (friendly) return res.status(409).json({ error: friendly });
    console.error("[customers:create]", err);
    res.status(500).json({ error: "Failed to save customer" });
  }
});

// PATCH /api/customers/:id - edit an existing master record
router.patch("/:id", async (req, res) => {
  const fields = ["name", "code", "contact_person", "email", "phone", "address", "gst_number"];
  const sets = [];
  const vals = [];
  let i = 1;
  for (const f of fields) {
    if (req.body[f] !== undefined) {
      sets.push(`${f} = $${i}`);
      vals.push(typeof req.body[f] === "string" ? (req.body[f].trim() || null) : req.body[f]);
      i++;
    }
  }
  if (!sets.length) return res.status(400).json({ error: "No updatable fields provided" });
  if (req.body.name !== undefined && !req.body.name.trim()) {
    return res.status(400).json({ error: "Customer name cannot be empty" });
  }
  vals.push(req.params.id);

  try {
    const { rows } = await query(`UPDATE customers SET ${sets.join(", ")} WHERE id = $${i} RETURNING *`, vals);
    if (!rows[0]) return res.status(404).json({ error: "Customer not found" });
    res.json(rows[0]);
  } catch (err) {
    const friendly = friendlyDbError(err);
    if (friendly) return res.status(409).json({ error: friendly });
    console.error("[customers:update]", err);
    res.status(500).json({ error: "Failed to save customer" });
  }
});

router.get("/:id", async (req, res) => {
  const { rows } = await query(`SELECT * FROM customers WHERE id = $1`, [req.params.id]);
  if (!rows[0]) return res.status(404).json({ error: "Customer not found" });
  res.json(rows[0]);
});

export default router;
