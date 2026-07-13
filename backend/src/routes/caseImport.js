import { Router } from "express";
import multer from "multer";
import { requireAuth, requireRole } from "../middleware/auth.js";
import { query } from "../db.js";
import { buildTemplateBuffer } from "../import/buildTemplate.js";
import { parseWorkbook } from "../import/parseWorkbook.js";
import { validateRows } from "../import/validateRows.js";
import { commitRows } from "../import/commitRows.js";

const router = Router();
router.use(requireAuth);
// Bulk-creating/modifying live business data — admin only, same
// sensitivity level as user management and case delete.
router.use(requireRole("admin"));

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } }); // 10MB cap

// GET /api/import/template — the downloadable .xlsx with the exact
// expected columns and one example row.
router.get("/template", async (req, res) => {
  try {
    const buf = await buildTemplateBuffer();
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", `attachment; filename="case-import-template.xlsx"`);
    res.send(Buffer.from(buf));
  } catch (err) {
    console.error("[case-import:template]", err);
    res.status(500).json({ error: "Failed to generate the template" });
  }
});

// POST /api/import/preview — multipart file upload. Parses and validates
// every row, matching customers/users read-only. Nothing is written to
// the database here — this is purely a dry run.
router.post("/preview", upload.single("file"), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });
  try {
    const rawRows = await parseWorkbook(req.file.buffer);
    if (!rawRows.length) return res.status(400).json({ error: "No data rows found in the uploaded file" });
    const preview = await validateRows(rawRows);
    res.json({ ...preview, filename: req.file.originalname });
  } catch (err) {
    res.status(400).json({ error: err.message || "Failed to parse the uploaded file" });
  }
});

// POST /api/import/commit — body: { rows, filename }. rows are the exact
// preview rows the frontend received back (already validated); rows with
// status 'error' are filtered out here as a safety net even though the
// frontend shouldn't be sending them in the first place.
router.post("/commit", async (req, res) => {
  const { rows, filename } = req.body;
  if (!Array.isArray(rows) || !rows.length) return res.status(400).json({ error: "No rows provided" });

  const importableRows = rows.filter((r) => r.status !== "error");
  if (!importableRows.length) return res.status(400).json({ error: "No importable rows — every row has an error" });

  try {
    const batch = (await query(
      `INSERT INTO import_batches (filename, imported_by) VALUES ($1,$2) RETURNING id`,
      [filename || null, req.user.id]
    )).rows[0];

    const created = await commitRows(importableRows, { userId: req.user.id, batchId: batch.id });
    res.status(201).json({ batchId: batch.id, createdCount: created.length, created });
  } catch (err) {
    console.error("[case-import:commit]", err);
    if (err.code === "23505") {
      return res.status(409).json({
        error: "One of the rows has a Reference that now conflicts with an existing case (possibly created since you previewed this file) — nothing was imported. Remove the conflicting reference and try again.",
      });
    }
    res.status(500).json({ error: err.message || "Import failed — nothing was saved." });
  }
});

export default router;
