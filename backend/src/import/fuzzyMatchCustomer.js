import { query } from "../db.js";

// Same approach as the Inbox's AI customer matching: strips punctuation
// and common legal-entity suffixes (Pvt/Private/Ltd/Limited/LLP/Inc/Corp)
// before comparing, so "Nish Techno Projects Pvt Ltd." correctly matches
// an existing "Nish Techno Projects Private Limited" — plain substring
// matching alone misses this since neither string literally contains the
// other.
export async function fuzzyMatchCustomerId(name) {
  if (!name || !name.trim()) return null;
  const NORMALIZE = `regexp_replace(UPPER($1), '[^A-Z0-9]|PVT|PRIVATE|LIMITED|LTD|LLP|INC|CORP', '', 'g')`;
  const { rows } = await query(
    `SELECT id, name FROM customers
     WHERE regexp_replace(UPPER(name), '[^A-Z0-9]|PVT|PRIVATE|LIMITED|LTD|LLP|INC|CORP', '', 'g') LIKE '%' || ${NORMALIZE} || '%'
        OR ${NORMALIZE} LIKE '%' || regexp_replace(UPPER(name), '[^A-Z0-9]|PVT|PRIVATE|LIMITED|LTD|LLP|INC|CORP', '', 'g') || '%'
     ORDER BY LENGTH(name) ASC LIMIT 1`,
    [name.trim()]
  );
  return rows[0] || null;
}
