// Single source of truth for the import template's columns — used both to
// generate the downloadable template and to parse an uploaded file, so
// the two can never drift out of sync with each other.
export const COLUMNS = [
  { key: "customer_name", header: "Customer Name", required: true },
  { key: "customer_code", header: "Customer Code" },
  { key: "contact_person", header: "Contact Person" },
  { key: "customer_email", header: "Customer Email" },
  { key: "customer_phone", header: "Customer Phone" },
  { key: "customer_address", header: "Customer Address" },
  { key: "gst_number", header: "GST Number" },
  { key: "segment", header: "Segment", required: true, example: "Industries" },
  { key: "requirement", header: "Requirement", required: true },
  { key: "reference", header: "Reference" },
  { key: "inquiry_type", header: "Inquiry Type", example: "Purchase" },
  { key: "assigned_to_email", header: "Assigned To (Email)" },
  { key: "stage", header: "Current Stage", required: true, example: "Offer Submitted" },
  { key: "enquiry_date", header: "Enquiry Received Date", required: true, date: true, example: "15-Jan-2026" },
  { key: "costing_completed_date", header: "Costing Completed Date", date: true },
  { key: "offer_prepared_date", header: "Offer Prepared Date", date: true },
  { key: "offer_submitted_date", header: "Offer Submitted Date", date: true },
  { key: "negotiation_completed_date", header: "Negotiations Completed Date", date: true },
  { key: "closed_date", header: "Won / Lost Date", date: true },
  { key: "expected_order_date", header: "Expected Order Date", date: true },
  { key: "offer_value", header: "Current Offer Value", number: true },
  { key: "notes", header: "Notes" },
];

export const SEGMENT_LABELS = {
  ww: "WW",
  industries: "Industries",
  instrument_service: "Instrument Service",
};
export const SEGMENT_VALUES = Object.fromEntries(
  Object.entries(SEGMENT_LABELS).map(([value, label]) => [label.toLowerCase(), value])
);

export const STAGE_LABELS = {
  enquiry: "Enquiry",
  costing_complete: "Costing Completed",
  offer_prepared: "Offer Prepared",
  offer_sent: "Offer Submitted",
  negotiation_complete: "Negotiations Completed",
  won: "Won",
  lost: "Lost",
};
export const STAGE_VALUES = Object.fromEntries(
  Object.entries(STAGE_LABELS).map(([value, label]) => [label.toLowerCase(), value])
);
// Which stage each milestone-date column implies, so the preview can warn
// if a stage is reached but its date is missing.
export const STAGE_DATE_COLUMN = {
  costing_complete: "costing_completed_date",
  offer_prepared: "offer_prepared_date",
  offer_sent: "offer_submitted_date",
  negotiation_complete: "negotiation_completed_date",
};

export const INQUIRY_TYPE_LABELS = { purchase: "Purchase", budgetary: "Budgetary", tender: "Tender" };
export const INQUIRY_TYPE_VALUES = Object.fromEntries(
  Object.entries(INQUIRY_TYPE_LABELS).map(([value, label]) => [label.toLowerCase(), value])
);
