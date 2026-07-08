// Builds the offer document to match the real letterhead format
// (reviewed directly from a real sent offer: 1079_Forozabad_NTPPL).
import path from "path";
import { fileURLToPath } from "url";
import { companyProfile } from "../config/companyProfile.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const LOGO_PATH = path.join(__dirname, "assets", "logo.jpeg");

// A standard reusable terms table (not tender-specific).
// Renumbered 1-18 sequentially - the source document had a duplicated "9"
// (a typo), fixed here rather than reproduced.
export const STANDARD_TERMS = [
  ["Total Basic", "Ex-Works, Sachin"],
  ["Packing, Forwarding & Loading at SELLER'S Shop.", "Included"],
  ["GST", "18% Extra as applicable at the time of dispatch"],
  ["Freight", "Included"],
  ["Payment terms:", "30% advance & balance against PI."],
  ["Delivery", "18-20 weeks"],
  ["Dispatch Location:", "At site"],
  ["Supervision of Erection if Required applicable", "No, If Required Can be Arranged on Additional Cost."],
  ["Supervision of Commissioning", "No, If Required Can be Arranged on Additional Cost."],
  ["Guarantee / Warrantee", "As provided by Manufacturer"],
  ["Price Basis", "Firm"],
  ["Any other Extra Charges?", "NO"],
  ["Validity of Offer", "30 days"],
  ["Bank Guarantee for Payment of advance and retention money shall be furnished", "NO"],
  ["Penalty Clause will be accepted.", "NO"],
  ["Part Order will be accepted.", "NO"],
  ["Commissioning Spares if applicable.", "NO"],
  ["Two (2) year's Operational Spares if applicable", "NO"],
];

const TERMS_NOTE =
  "Note: 1. If [NO], specify the period. Please explain on a separate sheet. If [YES], state extra charges. " +
  "2. Furnish the list of spares and unit prices on a separate sheet. " +
  "3. Quote separate prices for optional items, specified on Specification / Data Sheets.";

const money = (n) => Number(n || 0).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// Splits an address into 2-3 readable lines. Respects manual line breaks if
// present; otherwise (the common case — addresses are usually typed as one
// comma-separated string) greedily packs comma-separated segments into
// lines up to ~45 characters, which reliably produces 2-3 lines for a
// typical Indian address rather than one long unbroken line.
function formatAddressLines(address, maxLineLength = 45) {
  if (!address) return [];
  if (address.includes("\n")) {
    return address.split("\n").map((l) => l.trim()).filter(Boolean);
  }
  const parts = address.split(",").map((p) => p.trim()).filter(Boolean);
  const lines = [];
  let current = "";
  for (const part of parts) {
    const candidate = current ? `${current}, ${part}` : part;
    if (candidate.length > maxLineLength && current) {
      lines.push(current);
      current = part;
    } else {
      current = candidate;
    }
  }
  if (current) lines.push(current);
  return lines;
}

function letterhead(doc) {
  try {
    doc.image(LOGO_PATH, 50, 45, { width: 50 });
  } catch { /* logo optional if asset missing */ }
  doc.font("Helvetica-Bold").fontSize(10).fillColor("#333")
    .text(companyProfile.name, 350, 45, { align: "right", width: 195 });
  doc.font("Helvetica-Bold").fontSize(9)
    .text(companyProfile.addressLines[0] || "", 350, 58, { align: "right", width: 195 })
    .fillColor("#555");
  companyProfile.addressLines.slice(1).forEach((line) => {
    doc.text(line, { align: "right", width: 195 });
  });
  doc.font("Helvetica-Bold").fillColor("#333")
    .text(`TELE   ${companyProfile.phone}`, { align: "right", width: 195 })
    .fillColor("#1a5aa8")
    .text(`Email - ${companyProfile.email}`, { align: "right", width: 195 })
    .fillColor("#000");
  // Logo is portrait (taller than wide) — at width 50 it renders ~69pt tall,
  // starting at y 45. The old fixed y=115 landed inside the logo's bottom
  // edge, causing ref/date text to visually strike through it. 145 clears it.
  doc.y = 145;
}

function refDateLine(doc, ref, date) {
  doc.font("Helvetica-Bold").fontSize(10)
    .text(`Offer Ref: ${ref}`, 50, doc.y)
    .text(`Date: ${date}`);
  doc.moveDown(0.5);
}

export function writeOfferPdf(doc, { ref, revision, date, customer, requirementText, items, preparedBy, terms, notes }) {
  // ---------------- Page 1: Cover letter ----------------
  letterhead(doc);
  refDateLine(doc, ref, date);
  doc.moveDown(0.5);

  doc.font("Helvetica-Bold").fontSize(10).text("To,");
  doc.text(customer.customer_name || customer.name || "");
  doc.font("Helvetica");
  if (customer.contact_person) doc.font("Helvetica-Bold").text(`Kind Attn: ${customer.contact_person}`).font("Helvetica");
  if (customer.address) {
    formatAddressLines(customer.address).forEach((line) => doc.text(line));
  }
  if (customer.gst_number) doc.text(`GSTIN: ${customer.gst_number}`);
  doc.moveDown(0.8);

  doc.font("Helvetica-Bold").text(`Ref: Offer for "${companyProfile.manufacturer}" make Instruments.`);
  doc.moveDown(0.5);
  doc.font("Helvetica").text("Dear Sir,");
  doc.moveDown(0.3);
  doc.text(
    `Please find attached the offer for "${companyProfile.manufacturer}" make instruments as requested by you.${requirementText ? ` (${requirementText})` : ""}`
  );
  doc.moveDown(0.5);
  doc.font("Helvetica-BoldOblique")
    .text(`M/s. ${companyProfile.name.toUpperCase()}`, { continued: true })
    .font("Helvetica")
    .text(" is one of the leading companies in the region dealing in application study and solution based instrumentation.");
  doc.moveDown(0.3);
  doc.text(`Established in ${companyProfile.establishedYear}, we have enormous experience in the field of process Instrumentation.`);
  doc.moveDown(0.3);
  doc.font("Helvetica").text("We are representative of ", { continued: true })
    .font("Helvetica-BoldOblique").text(`M/s ${companyProfile.manufacturer}, India`, { continued: true })
    .font("Helvetica").text(" for their Process Instrumentation Division for the entire region and are authorized for their sales and service in the region.");
  doc.moveDown(0.6);

  doc.font("Helvetica-Bold").text(`M/s ${companyProfile.manufacturer} Process Instrumentation Division consists of the following Products Range.`);
  doc.font("Helvetica");
  companyProfile.productRangeLines.forEach((line, i) => doc.text(`${i + 1}.  ${line}`));
  doc.moveDown(0.6);

  doc.font("Helvetica-Bold").text("We request you to give us your valuable enquiry for your various maintenance and Project requirements.");
  doc.moveDown(0.6);
  doc.text("For any Techno-commercial query, please contact:");
  doc.font("Helvetica");
  doc.text(preparedBy.name || companyProfile.name);
  if (preparedBy.phone) doc.text(`M: ${preparedBy.phone}`);
  if (preparedBy.email) doc.text(`E id: ${preparedBy.email}`);
  doc.moveDown(0.6);

  doc.text("Thanking you and assuring you of our best attention & services at all the time.");
  doc.moveDown(0.6);
  doc.font("Helvetica-Bold").text(`For M/s. ${companyProfile.name},`);
  doc.moveDown(1.2);
  doc.text(preparedBy.name || "");
  if (preparedBy.designation) doc.font("Helvetica").text(`(${preparedBy.designation})`);

  // ---------------- Page 2: Quotation table ----------------
  doc.addPage();
  letterhead(doc);
  doc.font("Helvetica-Bold").fontSize(13).text("QUOTATION", 50, doc.y, { align: "center", underline: true, width: 500 });
  doc.moveDown(0.6);
  refDateLine(doc, ref, date);
  doc.moveDown(0.5);

  const col = { sr: 50, name: 78, model: 200, desc: 320, range: 385, qty: 435, unit: 465, total: 505 };
  let y = doc.y;
  doc.font("Helvetica-Bold").fontSize(8);
  doc.text("SR.", col.sr, y, { width: 25 });
  doc.text("Name of Instrument", col.name, y, { width: 118 });
  doc.text("Model No.", col.model, y, { width: 116 });
  doc.text("Descr.", col.desc, y, { width: 62 });
  doc.text("Range", col.range, y, { width: 46 });
  doc.text("Qty", col.qty, y, { width: 26 });
  doc.text("Unit", col.unit, y, { width: 36 });
  doc.text("Total", col.total, y, { width: 45 });
  doc.moveTo(50, y + 12).lineTo(550, y + 12).strokeColor("#999").stroke();
  doc.y = y + 16;

  let grandTotal = 0;
  doc.font("Helvetica").fontSize(7.5);
  items.forEach((it, idx) => {
    const rowY = doc.y;
    const lineTotal = Number(it.final_unit_price) * Number(it.qty);
    grandTotal += lineTotal;
    doc.text(String(idx + 1), col.sr, rowY, { width: 25 });
    doc.text(it.instrument_name || it.description || "-", col.name, rowY, { width: 118 });
    const afterName = doc.y;
    doc.text(it.model_code || "-", col.model, rowY, { width: 116 });
    const afterModel = doc.y;
    doc.text(it.product_name || it.description || "-", col.desc, rowY, { width: 62 });
    const afterDesc = doc.y;
    doc.text(it.range_value || "-", col.range, rowY, { width: 46 });
    doc.text(String(it.qty), col.qty, rowY, { width: 26 });
    doc.text(money(it.final_unit_price), col.unit, rowY, { width: 36 });
    doc.text(money(lineTotal), col.total, rowY, { width: 45 });
    doc.y = Math.max(afterName, afterModel, afterDesc, rowY + 10) + 6;
    if (doc.y > 730) { doc.addPage(); letterhead(doc); }
  });

  doc.moveTo(50, doc.y).lineTo(550, doc.y).strokeColor("#999").stroke();
  doc.moveDown(0.4);
  doc.font("Helvetica-Bold").fontSize(10).text(`Total: Rs. ${money(grandTotal)}`, 50, doc.y, { align: "right", width: 500 });
  if (notes && notes.trim()) {
    doc.moveDown(0.8);
    doc.font("Helvetica-Bold").fontSize(8.5).text(`Note: ${notes.trim()}`, 50, doc.y, { width: 500 });
  }

  // ---------------- Page 3: Commercial terms (standard compliance table) ----------------
  doc.addPage();
  letterhead(doc);
  refDateLine(doc, ref, date);
  doc.moveDown(0.5);
  doc.font("Helvetica-Bold").fontSize(13).text("Commercial Terms and Conditions", 50, doc.y, { align: "center", width: 500 });
  doc.moveDown(0.8);

  const rows = terms && terms.length ? terms : STANDARD_TERMS;
  const tCol = { no: 50, label: 75, value: 300 };
  doc.font("Helvetica").fontSize(8.5);
  rows.forEach((row, i) => {
    const [label, value] = Array.isArray(row) ? row : [row.label, row.value];
    const rowY = doc.y;
    doc.font("Helvetica").text(String(i + 1), tCol.no, rowY, { width: 20 });
    doc.text(label, tCol.label, rowY, { width: 215 });
    const afterLabel = doc.y;
    doc.font("Helvetica-Bold").text(value, tCol.value, rowY, { width: 245 });
    doc.font("Helvetica");
    doc.y = Math.max(afterLabel, doc.y, rowY + 12) + 4;
    doc.moveTo(50, doc.y - 2).lineTo(550, doc.y - 2).strokeColor("#ddd").stroke();
  });
  doc.moveDown(0.6);
  doc.fontSize(7.5).font("Helvetica-Oblique").text(TERMS_NOTE, 50, doc.y, { width: 500, align: "justify" });

  doc.moveDown(1.5);
  doc.font("Helvetica-Bold").fontSize(9).text(`For M/s. ${companyProfile.name},`, 50, doc.y, { width: 500 });
  doc.moveDown(1.2);
  doc.text(preparedBy.name || "", 50, doc.y, { width: 500 });
  if (preparedBy.designation) doc.font("Helvetica").fontSize(9).text(`(${preparedBy.designation})`, 50, doc.y, { width: 500 });

  return grandTotal;
}
