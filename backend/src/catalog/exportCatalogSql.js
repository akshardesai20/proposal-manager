import { query } from "../db.js";

// Safely quotes a value for direct inclusion in generated SQL text. This
// is building a literal .sql FILE for someone to review and commit, not
// running a parameterized query — so it needs its own escaping, distinct
// from the $1/$2 placeholders used everywhere else in this app.
function sqlLiteral(value) {
  if (value === null || value === undefined) return "NULL";
  if (typeof value === "number") return String(value);
  if (typeof value === "boolean") return value ? "true" : "false";
  return `'${String(value).replace(/'/g, "''")}'`;
}

// Core builder — takes an explicit list of family rows (already fetched)
// and writes the full migration text for exactly those families, nothing
// more. Both entry points below (whole-manufacturer, and just-these-ids)
// funnel through this, so there's one place that generates the actual SQL.
async function buildSqlForFamilies(families, headerLines) {
  const lines = [...headerLines, ""];

  for (const fam of families) {
    const mfg = (await query(`SELECT name FROM manufacturers WHERE id = $1`, [fam.manufacturer_id])).rows[0];
    lines.push(`-- ${fam.family} (${fam.base_code})`);
    lines.push(
      `INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type, manufacturer_id) ` +
      `VALUES (${sqlLiteral(fam.base_code)}, ${sqlLiteral(fam.family)}, ${sqlLiteral(fam.short_name)}, ${sqlLiteral(fam.description)}, ` +
      `${sqlLiteral(fam.trade_name)}, ${sqlLiteral(fam.instrument_type)}, ` +
      `(SELECT id FROM manufacturers WHERE name = ${sqlLiteral(mfg.name)})) ` +
      `ON CONFLICT (base_code) DO NOTHING;`
    );

    const positions = (await query(`SELECT * FROM siemens_positions WHERE family_id = $1 ORDER BY position_no`, [fam.id])).rows;
    for (const pos of positions) {
      lines.push(
        `INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range) ` +
        `VALUES ((SELECT id FROM siemens_families WHERE base_code = ${sqlLiteral(fam.base_code)}), ` +
        `${pos.position_no}, ${sqlLiteral(pos.name)}, ${sqlLiteral(pos.is_fix)}, ${sqlLiteral(pos.is_range)}) ` +
        `ON CONFLICT (family_id, position_no) DO NOTHING;`
      );

      const options = (await query(`SELECT * FROM siemens_position_options WHERE position_id = $1 ORDER BY character`, [pos.id])).rows;
      for (const opt of options) {
        lines.push(
          `INSERT INTO siemens_position_options (position_id, character, meaning, short_label) ` +
          `VALUES ((SELECT id FROM siemens_positions WHERE family_id = (SELECT id FROM siemens_families WHERE base_code = ${sqlLiteral(fam.base_code)}) AND position_no = ${pos.position_no}), ` +
          `${sqlLiteral(opt.character)}, ${sqlLiteral(opt.meaning)}, ${sqlLiteral(opt.short_label)}) ` +
          `ON CONFLICT (position_id, character) DO NOTHING;`
        );
      }
    }

    const suffixes = (await query(`SELECT * FROM siemens_suffixes WHERE family_id = $1 ORDER BY code`, [fam.id])).rows;
    for (const suf of suffixes) {
      lines.push(
        `INSERT INTO siemens_suffixes (family_id, code, meaning) ` +
        `VALUES ((SELECT id FROM siemens_families WHERE base_code = ${sqlLiteral(fam.base_code)}), ${sqlLiteral(suf.code)}, ${sqlLiteral(suf.meaning)}) ` +
        `ON CONFLICT (family_id, code) DO NOTHING;`
      );
    }
    lines.push("");
  }

  return lines.join("\n");
}

// Everything under one manufacturer — for a full "give me their whole
// catalog" export, e.g. setting up a brand-new deployment from scratch.
export async function exportManufacturerAsSql(manufacturerId) {
  const mfg = (await query(`SELECT * FROM manufacturers WHERE id = $1`, [manufacturerId])).rows[0];
  if (!mfg) throw new Error("Manufacturer not found");

  const families = (await query(
    `SELECT * FROM siemens_families WHERE manufacturer_id = $1 ORDER BY family`, [manufacturerId]
  )).rows;

  return buildSqlForFamilies(families, [
    `-- Catalog export: ${mfg.name} (complete)`,
    `-- Generated ${new Date().toISOString()} from the Catalog page.`,
    `-- Safe to run on any database — every insert below uses ON CONFLICT DO NOTHING,`,
    `-- so re-running this (or applying it alongside other catalog data) never duplicates rows.`,
    ``,
    `INSERT INTO manufacturers (name) VALUES (${sqlLiteral(mfg.name)}) ON CONFLICT (name) DO NOTHING;`,
  ]);
}

// Just the specific families given — e.g. only what a single import
// session just added, rather than a manufacturer's entire history.
export async function exportFamiliesAsSql(familyIds) {
  if (!familyIds || !familyIds.length) throw new Error("No families specified");

  const families = (await query(
    `SELECT * FROM siemens_families WHERE id = ANY($1::int[]) ORDER BY family`, [familyIds]
  )).rows;
  if (!families.length) throw new Error("None of those families were found");

  const mfgIds = [...new Set(families.map((f) => f.manufacturer_id))];
  const mfgs = (await query(`SELECT name FROM manufacturers WHERE id = ANY($1::int[])`, [mfgIds])).rows;

  return buildSqlForFamilies(families, [
    `-- Catalog export: newly imported families (${families.map((f) => f.family).join(", ")})`,
    `-- Manufacturer(s): ${mfgs.map((m) => m.name).join(", ")}`,
    `-- Generated ${new Date().toISOString()} from the Catalog page.`,
    `-- Safe to run on any database — every insert below uses ON CONFLICT DO NOTHING,`,
    `-- so re-running this (or applying it alongside other catalog data) never duplicates rows.`,
    ``,
    ...mfgs.map((m) => `INSERT INTO manufacturers (name) VALUES (${sqlLiteral(m.name)}) ON CONFLICT (name) DO NOTHING;`),
  ]);
}
