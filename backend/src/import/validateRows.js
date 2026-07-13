import { query } from "../db.js";
import { SEGMENT_VALUES, STAGE_VALUES, STAGE_DATE_COLUMN, INQUIRY_TYPE_VALUES } from "./columns.js";
import { parseImportDate } from "./parseImportDate.js";
import { fuzzyMatchCustomerId } from "./fuzzyMatchCustomer.js";

function str(v) {
  return v === null || v === undefined ? "" : String(v).trim();
}

// Validates one raw row and resolves its customer/user matches. Never
// writes to the database — matching queries are read-only (SELECT).
// Returns a preview object: { rowNumber, status, messages, customer, case }
async function validateRow(raw) {
  const messages = [];
  let status = "ok";
  const addError = (msg) => { messages.push({ level: "error", text: msg }); status = "error"; };
  const addWarning = (msg) => { messages.push({ level: "warning", text: msg }); if (status === "ok") status = "warning"; };

  const customerName = str(raw.customer_name);
  const segmentLabel = str(raw.segment);
  const requirement = str(raw.requirement);
  const stageLabel = str(raw.stage);

  if (!customerName) addError("Customer Name is required");
  if (!segmentLabel) addError("Segment is required");
  if (!requirement) addError("Requirement is required");
  if (!stageLabel) addError("Current Stage is required");

  const segment = SEGMENT_VALUES[segmentLabel.toLowerCase()];
  if (segmentLabel && !segment) addError(`Segment "${segmentLabel}" isn't one of WW / Industries / Instrument Service`);

  const stage = STAGE_VALUES[stageLabel.toLowerCase()];
  if (stageLabel && !stage) addError(`Current Stage "${stageLabel}" isn't a recognized stage — check spelling against the template`);

  const inquiryTypeLabel = str(raw.inquiry_type);
  const inquiryType = inquiryTypeLabel ? INQUIRY_TYPE_VALUES[inquiryTypeLabel.toLowerCase()] : null;
  if (inquiryTypeLabel && !inquiryType) addWarning(`Inquiry Type "${inquiryTypeLabel}" not recognized — left blank`);

  // Dates — enquiry date is required, the rest are optional but each gets
  // validated the same strict way if present at all.
  const dateFields = {};
  const dateColumns = ["enquiry_date", "costing_completed_date", "offer_prepared_date", "offer_submitted_date", "negotiation_completed_date", "closed_date", "expected_order_date"];
  for (const col of dateColumns) {
    const { date, error } = parseImportDate(raw[col]);
    if (error) {
      if (col === "enquiry_date") addError(`Enquiry Received Date: ${error}`);
      else addWarning(`${col.replace(/_/g, " ")}: ${error} — left blank`);
    } else {
      dateFields[col] = date;
    }
  }
  if (!dateFields.enquiry_date) addError("Enquiry Received Date is required");

  // If the stage implies a milestone was reached but its date is missing,
  // that's worth a heads-up — not blocking, since some historical records
  // genuinely won't have every date.
  if (stage && STAGE_VALUES) {
    const order = ["enquiry", "costing_complete", "offer_prepared", "offer_sent", "negotiation_complete"];
    const stageIdx = order.indexOf(stage);
    for (const [milestoneStage, dateCol] of Object.entries(STAGE_DATE_COLUMN)) {
      if (stageIdx >= order.indexOf(milestoneStage) && !dateFields[dateCol]) {
        addWarning(`Stage implies "${dateCol.replace(/_/g, " ")}" should be set, but it's blank`);
      }
    }
  }
  if ((stage === "won" || stage === "lost") && !dateFields.closed_date) {
    addWarning(`Stage is ${stageLabel} but "Won / Lost Date" is blank — reporting by month/FY won't include this case until it's set`);
  }

  let offerValue = null;
  if (raw.offer_value !== null && raw.offer_value !== undefined && raw.offer_value !== "") {
    const n = Number(raw.offer_value);
    if (isNaN(n)) addWarning(`Current Offer Value "${raw.offer_value}" isn't a number — left blank`);
    else offerValue = n;
  }

  const reference = str(raw.reference) || null;
  if (reference) {
    const existing = await query(`SELECT id FROM cases WHERE reference = $1`, [reference]);
    if (existing.rows[0]) addError(`Reference "${reference}" already exists on an existing case — pick a different reference or leave blank`);
  }

  let customer = { matched: false, id: null, name: customerName };
  if (customerName) {
    const match = await fuzzyMatchCustomerId(customerName);
    if (match) customer = { matched: true, id: match.id, name: match.name };
  }

  let assignedUserId = null;
  const assignedEmail = str(raw.assigned_to_email);
  if (assignedEmail) {
    const u = await query(`SELECT id FROM users WHERE LOWER(email) = LOWER($1)`, [assignedEmail]);
    if (u.rows[0]) assignedUserId = u.rows[0].id;
    else addWarning(`No user found with email "${assignedEmail}" — case will be left unassigned`);
  }

  return {
    rowNumber: raw.rowNumber,
    status,
    messages,
    customer: {
      matched: customer.matched,
      id: customer.id,
      name: customer.matched ? customer.name : customerName,
      willCreate: !customer.matched && !!customerName,
      code: str(raw.customer_code) || null,
      contact_person: str(raw.contact_person) || null,
      email: str(raw.customer_email) || null,
      phone: str(raw.customer_phone) || null,
      address: str(raw.customer_address) || null,
      gst_number: str(raw.gst_number) || null,
    },
    case: {
      segment: segment || null,
      requirement_text: requirement || null,
      reference,
      inquiry_type: inquiryType || null,
      assigned_user_id: assignedUserId,
      stage: stage || null,
      created_at: dateFields.enquiry_date || null,
      costing_completed_at: dateFields.costing_completed_date || null,
      offer_prepared_at: dateFields.offer_prepared_date || null,
      offer_sent_at: dateFields.offer_submitted_date || null,
      negotiation_completed_at: dateFields.negotiation_completed_date || null,
      closed_at: dateFields.closed_date || null,
      outcome: stage === "won" ? "won" : stage === "lost" ? "lost" : null,
      expected_order_date: dateFields.expected_order_date || null,
      offer_value: offerValue,
      notes: str(raw.notes) || null,
    },
  };
}

export async function validateRows(rawRows) {
  const results = [];
  for (const raw of rawRows) {
    results.push(await validateRow(raw));
  }
  const summary = {
    total: results.length,
    ok: results.filter((r) => r.status === "ok").length,
    warning: results.filter((r) => r.status === "warning").length,
    error: results.filter((r) => r.status === "error").length,
  };
  return { rows: results, summary };
}
