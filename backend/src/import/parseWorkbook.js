import ExcelJS from "exceljs";
import { COLUMNS } from "./columns.js";

// Reads the first worksheet of an uploaded .xlsx buffer. Expects row 1 to
// be headers matching COLUMNS (case-insensitive, whitespace-trimmed) —
// column order doesn't matter, only the header text does, so a user
// re-arranging columns in Excel doesn't break the import.
export async function parseWorkbook(buffer) {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  const sheet = workbook.worksheets[0];
  if (!sheet) throw new Error("The uploaded file has no worksheets");

  const headerRow = sheet.getRow(1);
  const colIndexByKey = {};
  headerRow.eachCell((cell, colNumber) => {
    const text = String(cell.value || "").trim().toLowerCase();
    const match = COLUMNS.find((c) => c.header.toLowerCase() === text);
    if (match) colIndexByKey[match.key] = colNumber;
  });

  const missingRequired = COLUMNS.filter((c) => c.required && !(c.key in colIndexByKey));
  if (missingRequired.length) {
    throw new Error(
      `The uploaded file is missing required column(s): ${missingRequired.map((c) => c.header).join(", ")}. ` +
      `Download the template to see the exact expected headers.`
    );
  }

  const rows = [];
  sheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return; // header row
    const isBlank = row.values.length <= 1 || row.values.every((v) => v === null || v === undefined || v === "");
    if (isBlank) return;

    const raw = { rowNumber };
    for (const col of COLUMNS) {
      const idx = colIndexByKey[col.key];
      raw[col.key] = idx ? cellValue(row.getCell(idx)) : null;
    }
    rows.push(raw);
  });

  return rows;
}

// ExcelJS returns Date objects directly for date-formatted cells, plain
// values for text/number cells, and a {richText: [...]} or {text: ...}
// shape for some rich/formula cells — normalize all of that down to a
// plain string/number/Date/null.
function cellValue(cell) {
  const v = cell.value;
  if (v === null || v === undefined) return null;
  if (v instanceof Date) return v;
  if (typeof v === "object") {
    if (Array.isArray(v.richText)) return v.richText.map((t) => t.text).join("");
    if ("text" in v) return v.text;
    if ("result" in v) return v.result; // formula cell
    return null;
  }
  return typeof v === "string" ? v.trim() : v;
}
