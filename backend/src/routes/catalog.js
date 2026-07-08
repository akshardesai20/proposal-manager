import { Router } from "express";
import { query } from "../db.js";
import { requireAuth } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth);

// GET /api/catalog/families?q=search
router.get("/families", async (req, res) => {
  const q = `%${(req.query.q || "").toUpperCase()}%`;
  const { rows } = await query(
    `SELECT base_code, family, short_name, description, trade_name, instrument_type FROM siemens_families
     WHERE UPPER(base_code) LIKE $1 OR UPPER(family) LIKE $1 OR UPPER(short_name) LIKE $1
     ORDER BY base_code`,
    [q]
  );
  res.json(rows);
});

// GET /api/catalog/families/:baseCode - full position/option/suffix detail
router.get("/families/:baseCode", async (req, res) => {
  const fam = (await query(`SELECT * FROM siemens_families WHERE base_code = $1`, [req.params.baseCode])).rows[0];
  if (!fam) return res.status(404).json({ error: "Family not found" });

  const positions = (await query(
    `SELECT * FROM siemens_positions WHERE family_id = $1 ORDER BY position_no`,
    [fam.id]
  )).rows;
  for (const p of positions) {
    p.options = (await query(
      `SELECT character, meaning, short_label FROM siemens_position_options WHERE position_id = $1 ORDER BY LENGTH(character) DESC, character`,
      [p.id]
    )).rows;
  }
  const suffixes = (await query(
    `SELECT code, meaning FROM siemens_suffixes WHERE family_id = $1 ORDER BY code`,
    [fam.id]
  )).rows;

  res.json({ ...fam, positions, suffixes });
});

// GET /api/catalog/addons?q=search
router.get("/addons", async (req, res) => {
  const q = `%${(req.query.q || "").toUpperCase()}%`;
  const { rows } = await query(
    `SELECT code, name, description FROM siemens_addons
     WHERE UPPER(code) LIKE $1 OR UPPER(name) LIKE $1 ORDER BY code`,
    [q]
  );
  res.json(rows);
});

// POST /api/catalog/decode { code }
// Decodes a model code against the catalog: finds the longest-matching
// family base_code, then walks each position in order, trying the longest
// known option first at the current cursor (handles both 1-char and
// multi-char positions like MAG 3100's diameter code). Anything that
// doesn't match is flagged rather than guessed.
router.post("/decode", async (req, res) => {
  const raw = (req.body.code || "").trim();
  if (!raw) return res.status(400).json({ error: "code is required" });

  const zMatch = raw.match(/-Z\s*/i);
  let mainPart = raw;
  let suffixPart = "";
  if (zMatch) {
    mainPart = raw.slice(0, zMatch.index);
    suffixPart = raw.slice(zMatch.index + zMatch[0].length);
  }
  const compact = mainPart.replace(/[\s-]/g, "").toUpperCase();

  const families = (await query(`SELECT * FROM siemens_families`)).rows;
  let family = null;
  for (const f of families) {
    if (compact.startsWith(f.base_code.toUpperCase())) {
      if (!family || f.base_code.length > family.base_code.length) family = f;
    }
  }
  if (!family) {
    return res.json({ matched: false, input: raw, message: "No matching family found for this base code." });
  }

  const positions = (await query(
    `SELECT * FROM siemens_positions WHERE family_id = $1 ORDER BY position_no`,
    [family.id]
  )).rows;

  let remainder = compact.slice(family.base_code.length);
  const decodedPositions = [];

  for (const p of positions) {
    const options = (await query(
      `SELECT character, meaning, short_label FROM siemens_position_options WHERE position_id = $1 ORDER BY LENGTH(character) DESC`,
      [p.id]
    )).rows;

    const match = options.find((opt) => remainder.startsWith(opt.character));
    if (match) {
      decodedPositions.push({
        position_no: p.position_no, name: p.name, is_fix: p.is_fix, is_range: p.is_range,
        character: match.character, meaning: match.meaning, short_label: match.short_label, matched: true,
      });
      remainder = remainder.slice(match.character.length);
    } else {
      decodedPositions.push({
        position_no: p.position_no, name: p.name, is_fix: p.is_fix, is_range: p.is_range,
        character: remainder[0] || null, meaning: null, short_label: null, matched: false,
      });
      remainder = remainder.slice(1);
    }
  }

  const suffixTokens = suffixPart.split(/[\s+]+/).map((s) => s.trim()).filter(Boolean);
  const decodedSuffixes = [];
  if (suffixTokens.length) {
    const allSuffixes = (await query(`SELECT code, meaning FROM siemens_suffixes WHERE family_id = $1`, [family.id])).rows;
    for (const tok of suffixTokens) {
      const found = allSuffixes.find((s) => s.code.toUpperCase() === tok.toUpperCase());
      decodedSuffixes.push({ code: tok, meaning: found ? found.meaning : null, matched: !!found });
    }
  }

  const bullets = decodedPositions.filter((p) => !p.is_fix && p.matched).map((p) => `${p.name}: ${p.meaning}`);
  const suffixBullets = decodedSuffixes.filter((s) => s.matched).map((s) => s.meaning);
  const rangeMatch = decodedPositions.find((p) => p.is_range && p.matched);
  const rangeValue = rangeMatch ? (rangeMatch.short_label || rangeMatch.meaning) : null;

  res.json({
    matched: true,
    family: {
      base_code: family.base_code, family: family.family,
      short_name: family.short_name, description: family.description,
      trade_name: family.trade_name, instrument_type: family.instrument_type,
    },
    positions: decodedPositions,
    suffixes: decodedSuffixes,
    leftover: remainder || null,
    description: [family.description, ...bullets, ...suffixBullets].filter(Boolean).join(" "),
    bullets: [...bullets, ...suffixBullets],
    range_value: rangeValue,
  });
});

export default router;
