import ExcelJS from "exceljs";
import { COLUMNS } from "./columns.js";

export async function buildTemplateBuffer() {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Cases to Import");

  sheet.columns = COLUMNS.map((c) => ({ header: c.header, key: c.key, width: Math.max(c.header.length + 4, 18) }));
  sheet.getRow(1).font = { bold: true };

  // One example row, greyed out visually via a note rather than styling
  // (keeps this robust across Excel/Google Sheets/LibreOffice, which
  // don't all render cell comments/styles identically) — the row itself
  // is real, parseable data, just clearly a placeholder in its content.
  sheet.addRow({
    customer_name: "Example Engineering Pvt Ltd (delete this row before importing)",
    customer_code: "EXENG",
    contact_person: "Contact Name",
    customer_email: "contact@example.com",
    customer_phone: "9800000000",
    customer_address: "City, State",
    gst_number: "27ABCDE1234F1Z5",
    segment: "Industries",
    requirement: "Short description of what the customer needs",
    reference: "CASE-0100",
    inquiry_type: "Purchase",
    assigned_to_email: "salesperson@yourcompany.com",
    stage: "Offer Submitted",
    enquiry_date: "15-Jan-2026",
    costing_completed_date: "18-Jan-2026",
    offer_prepared_date: "20-Jan-2026",
    offer_submitted_date: "20-Jan-2026",
    negotiation_completed_date: "",
    closed_date: "",
    expected_order_date: "10-Feb-2026",
    offer_value: 185000,
    notes: "Any additional context",
  });

  return workbook.xlsx.writeBuffer();
}
