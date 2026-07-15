import { Router } from "express";
import multer from "multer";
import { query } from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { extractPdfText } from "../catalog/extractPdfText.js";
import { extractCatalogFromText } from "../catalog/extractCatalogFromText.js";
import { commitCatalogExtraction } from "../catalog/commitCatalogExtraction.js";
import { exportManufacturerAsSql, exportFamiliesAsSql } from "../catalog/exportCatalogSql.js";

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

// GET /api/catalog/browse — every family currently in the database,
// grouped by manufacturer, with counts so the page can show what's
// actually there without loading every position/option up front.
router.get("/browse", async (req, res) => {
  const { rows } = await query(
    `SELECT f.id, f.base_code, f.family, f.short_name, f.instrument_type,
            m.id AS manufacturer_id, m.name AS manufacturer_name,
            (SELECT COUNT(*) FROM siemens_positions WHERE family_id = f.id) AS position_count,
            (SELECT COUNT(*) FROM siemens_suffixes WHERE family_id = f.id) AS suffix_count
     FROM siemens_families f
     JOIN manufacturers m ON m.id = f.manufacturer_id
     ORDER BY m.name, f.family`
  );

  const byManufacturer = {};
  for (const row of rows) {
    if (!byManufacturer[row.manufacturer_id]) {
      byManufacturer[row.manufacturer_id] = { manufacturerId: row.manufacturer_id, manufacturerName: row.manufacturer_name, families: [] };
    }
    byManufacturer[row.manufacturer_id].families.push({
      id: row.id, baseCode: row.base_code, family: row.family, shortName: row.short_name,
      instrumentType: row.instrument_type, positionCount: Number(row.position_count), suffixCount: Number(row.suffix_count),
    });
  }
  res.json(Object.values(byManufacturer));
});

// GET /api/catalog/export/:manufacturerId — downloads everything under
// one manufacturer as a portable, idempotent .sql file, ready to commit
// to any other repo's migrations folder. Solves the gap where catalog
// data added through this UI otherwise only exists in this one database.
router.get("/export/:manufacturerId", async (req, res) => {
  try {
    const sql = await exportManufacturerAsSql(req.params.manufacturerId);
    const mfg = (await query(`SELECT name FROM manufacturers WHERE id = $1`, [req.params.manufacturerId])).rows[0];
    const filename = `catalog_${(mfg?.name || "export").toLowerCase().replace(/[^a-z0-9]+/g, "_")}.sql`;
    res.setHeader("Content-Type", "application/sql");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    res.send(sql);
  } catch (err) {
    res.status(404).json({ error: err.message || "Export failed" });
  }
});

// POST /api/catalog/export-families — body: { familyIds: [...] }. Same
// output format as the manufacturer-wide export, but scoped to exactly
// the families given — used right after an import to export only what
// was just captured, not that manufacturer's whole accumulated history.
router.post("/export-families", async (req, res) => {
  const { familyIds } = req.body;
  if (!Array.isArray(familyIds) || !familyIds.length) return res.status(400).json({ error: "No families specified" });
  try {
    const sql = await exportFamiliesAsSql(familyIds);
    res.setHeader("Content-Type", "application/sql");
    res.setHeader("Content-Disposition", `attachment; filename="catalog_new_import.sql"`);
    res.send(sql);
  } catch (err) {
    res.status(404).json({ error: err.message || "Export failed" });
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
