import { pool } from "../db.js";

// Writes a (human-reviewed) extraction result to the catalog tables.
// Same idempotency approach as every hand-written catalog migration in
// this project: ON CONFLICT DO NOTHING at every level, so re-running this
// on the same family is always safe and never creates duplicates. Runs as
// one transaction — if anything fails partway through, nothing is left
// half-written.
export async function commitCatalogExtraction({ manufacturerId, families, addons }) {
  const client = await pool.connect();
  const result = { familiesCreated: 0, familiesSkipped: 0, addonsCreated: 0 };
  try {
    await client.query("BEGIN");

    for (const fam of families || []) {
      if (!fam.base_code || !fam.family) continue; // silently skip incomplete rows rather than failing the whole batch

      const famRes = await client.query(
        `INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type, manufacturer_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7)
         ON CONFLICT (base_code) DO NOTHING
         RETURNING id`,
        [fam.base_code, fam.family, fam.short_name || null, fam.description || null, fam.trade_name || null, fam.instrument_type || null, manufacturerId]
      );

      let familyId = famRes.rows[0]?.id;
      if (!familyId) {
        result.familiesSkipped++;
        // Already exists — still worth resolving its id so positions/
        // suffixes below can attach correctly on a re-run rather than
        // silently doing nothing for the whole family.
        const existing = await client.query(`SELECT id FROM siemens_families WHERE base_code = $1`, [fam.base_code]);
        familyId = existing.rows[0]?.id;
        if (!familyId) continue;
      } else {
        result.familiesCreated++;
      }

      for (const pos of fam.positions || []) {
        if (!pos.position_no || !pos.name) continue;
        const posRes = await client.query(
          `INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
           VALUES ($1,$2,$3,$4,$5)
           ON CONFLICT (family_id, position_no) DO NOTHING
           RETURNING id`,
          [familyId, pos.position_no, pos.name, !!pos.is_fix, !!pos.is_range]
        );
        let positionId = posRes.rows[0]?.id;
        if (!positionId) {
          const existingPos = await client.query(
            `SELECT id FROM siemens_positions WHERE family_id = $1 AND position_no = $2`,
            [familyId, pos.position_no]
          );
          positionId = existingPos.rows[0]?.id;
        }
        if (!positionId) continue;

        for (const opt of pos.options || []) {
          if (!opt.character || !opt.meaning) continue;
          await client.query(
            `INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
             VALUES ($1,$2,$3,$4)
             ON CONFLICT (position_id, character) DO NOTHING`,
            [positionId, opt.character, opt.meaning, opt.short_label || null]
          );
        }
      }

      for (const suf of fam.suffixes || []) {
        if (!suf.code || !suf.meaning) continue;
        await client.query(
          `INSERT INTO siemens_suffixes (family_id, code, meaning)
           VALUES ($1,$2,$3)
           ON CONFLICT (family_id, code) DO NOTHING`,
          [familyId, suf.code, suf.meaning]
        );
      }
    }

    for (const addon of addons || []) {
      if (!addon.code || !addon.name) continue;
      const addonRes = await client.query(
        `INSERT INTO siemens_addons (code, name, description)
         VALUES ($1,$2,$3)
         ON CONFLICT (code) DO NOTHING
         RETURNING code`,
        [addon.code, addon.name, addon.description || null]
      );
      if (addonRes.rows.length) result.addonsCreated++;
    }

    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
