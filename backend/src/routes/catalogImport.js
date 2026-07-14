import { Router } from "express";
import multer from "multer";
import { query } from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { extractPdfText } from "../catalog/extractPdfText.js";
import { extractCatalogFromText } from "../catalog/extractCatalogFromText.js";
import { commitCatalogExtraction } from "../catalog/commitCatalogExtraction.js";

const router = Router();
router.use(requireAuth);
// Bulk-writing catalog data is the same sensitivity level as user
// management and bulk case import — admin only.
router.use(requireRole("admin"));

// A second, independent gate on top of admin role: whether this feature
// exists on THIS deployment at all. Deliberately not tied to who's logged
// in — an admin account on a customer's own instance shouldn't be able to
// reach this just by having the right role, since it costs real OpenAI
// API usage and the extraction quality needs a reviewer who knows the
// catalog domain. Set CATALOG_IMPORT_ENABLED=true only on the instance(s)
// you personally use to build catalogs before handing them off.
router.use((req, res, next) => {
  if (process.env.CATALOG_IMPORT_ENABLED !== "true") {
    return res.status(404).json({ error: "This feature isn't available on this deployment." });
  }
  next();
});

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } }); // 20MB — datasheets can run long

// GET /api/catalog/manufacturers
router.get("/manufacturers", async (req, res) => {
  const { rows } = await query(`SELECT * FROM manufacturers ORDER BY name`);
  res.json(rows);
});

// POST /api/catalog/manufacturers — body: { name }
router.post("/manufacturers", async (req, res) => {
  const { name } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: "Manufacturer name is required" });
  try {
    const { rows } = await query(`INSERT INTO manufacturers (name) VALUES ($1) RETURNING *`, [name.trim()]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === "23505") return res.status(409).json({ error: "A manufacturer with that name already exists" });
    throw err;
  }
});

// POST /api/catalog/extract — multipart PDF upload. Extracts text, runs
// AI structured extraction, returns a PREVIEW. Nothing is written to the
// catalog tables here — see /commit for that, which only runs once a
// human has reviewed this response.
router.post("/extract", upload.single("file"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });

  let text;
  try {
    const extracted = await extractPdfText(req.file.buffer);
    text = extracted.text;
  } catch (err) {
    return res.status(400).json({ error: `Couldn't read this PDF: ${err.message}` });
  }

  const result = await extractCatalogFromText(text);
  if (result.error) return res.status(502).json({ error: result.error });

  res.json(result);
});

// POST /api/catalog/commit — body: { manufacturerId, families, addons }.
// Expects the (possibly human-edited) shape returned by /extract.
router.post("/commit", async (req, res) => {
  const { manufacturerId, families, addons } = req.body;
  if (!manufacturerId) return res.status(400).json({ error: "manufacturerId is required" });
  if (!Array.isArray(families) || !families.length) return res.status(400).json({ error: "No families to save" });

  try {
    const result = await commitCatalogExtraction({ manufacturerId, families, addons });
    res.status(201).json(result);
  } catch (err) {
    console.error("[catalog:commit]", err);
    res.status(500).json({ error: err.message || "Failed to save catalog data" });
  }
});

export default router;
