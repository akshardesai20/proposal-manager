const MONTHS = {
  jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5,
  jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11,
};

// Returns { date: Date } on a confident parse, or { error: string } —
// never guesses. Purely numeric formats like "01/02/2026" are rejected
// outright (could mean 1-Feb or 2-Jan depending on locale) rather than
// silently picking one interpretation, since a wrong guess here means
// wrong historical data permanently in a live business's records.
export function parseImportDate(value) {
  if (value === null || value === undefined || value === "") return { date: null };

  if (value instanceof Date) {
    if (isNaN(value.getTime())) return { error: "Invalid date value" };
    return { date: value };
  }

  const str = String(value).trim();
  if (!str) return { date: null };

  // "15-Jan-2026", "15 Jan 2026", "15-January-2026" — day, named month,
  // year, in either order for day/month but always with the month
  // spelled out, which is what makes this unambiguous.
  const named = str.match(/^(\d{1,2})[\s-]([A-Za-z]{3,9})[\s-](\d{4})$/);
  if (named) {
    const day = Number(named[1]);
    const monthKey = named[2].slice(0, 3).toLowerCase();
    const year = Number(named[3]);
    if (!(monthKey in MONTHS)) return { error: `Unrecognized month "${named[2]}" in "${str}"` };
    if (day < 1 || day > 31) return { error: `Invalid day in "${str}"` };
    const date = new Date(Date.UTC(year, MONTHS[monthKey], day));
    return { date };
  }

  // ISO format is always unambiguous (year first).
  const iso = str.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
  if (iso) {
    const [, year, month, day] = iso.map(Number);
    if (month < 1 || month > 12) return { error: `Invalid month in "${str}"` };
    return { date: new Date(Date.UTC(year, month - 1, day)) };
  }

  // Purely numeric with slashes or dashes (DD/MM/YYYY vs MM/DD/YYYY) is
  // genuinely ambiguous — refuse rather than guess.
  if (/^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$/.test(str)) {
    return { error: `"${str}" is ambiguous (could be day/month or month/day) — use a format like "15-Jan-2026" instead` };
  }

  return { error: `Could not understand the date "${str}" — use a format like "15-Jan-2026"` };
}
