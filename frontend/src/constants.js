export const STAGES = [
  { key: "enquiry", label: "Enquiry", color: "#5d7188" },
  { key: "costing", label: "Costing", color: "#f2a900" },
  { key: "costing_complete", label: "Costing complete", color: "#f2a900" },
  { key: "offer_prepared", label: "Offer prepared", color: "#1bb8b0" },
  { key: "offer_sent", label: "Offer submitted", color: "#1bb8b0" },
  { key: "negotiation", label: "Negotiation", color: "#f2a900" },
  { key: "negotiation_complete", label: "Negotiation completed", color: "#f2a900" },
  { key: "won", label: "Won", color: "#3fb950" },
  { key: "lost", label: "Lost", color: "#ff6b6b" },
];
export const stageMeta = (key) => STAGES.find((s) => s.key === key) || STAGES[0];

// Ordered milestone checklist shown on the case detail page. Each entry's
// `stage` is the value PATCHed to /cases/:id/stage when checked; `dateKey`
// is the case field holding the timestamp that gets stamped automatically
// when that stage is reached (read-only — not manually editable, same as
// offer_prepared_at already was before this checklist existed).
export const CASE_PROGRESS_STAGES = [
  { stage: "costing_complete", label: "Costing Completed", dateKey: "costing_completed_at" },
  { stage: "offer_prepared", label: "Offer Prepared", dateKey: "offer_prepared_at" },
  { stage: "offer_sent", label: "Offer Submitted", dateKey: "offer_sent_at" },
  { stage: "negotiation_complete", label: "Negotiations Completed", dateKey: "negotiation_completed_at" },
];
// STAGE_ORDER mirrors the backend's list — used to derive which checkbox
// should show as checked from the single `stage` value on the case.
export const STAGE_ORDER = ["enquiry", "costing", "costing_complete", "offer_prepared", "offer_sent", "negotiation", "negotiation_complete", "won", "lost"];

export const INQUIRY_TYPES = [
  { value: "purchase", label: "Purchase" },
  { value: "budgetary", label: "Budgetary" },
  { value: "tender", label: "Tender" },
];

// Business segment, selected per-case at case-creation time. Drives the
// three tabs on the Proposals page and the segment-wise dashboard metrics.
export const SEGMENTS = [
  { value: "ww", label: "WW" },
  { value: "industries", label: "Industries" },
  { value: "instrument_service", label: "Instrument Service" },
];
export const segmentMeta = (key) => SEGMENTS.find((s) => s.value === key) || null;
