-- Adds a basic, first-cut instrument model/family recommendation to the
-- AI analysis already run on inbound emails — grounded in the actual
-- seeded Siemens catalog (siemens_families), not just the model's general
-- knowledge, so it only ever points to something genuinely carried.
-- Deliberately not a full part number — see analyzeInquiry.js for why.
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_model_recommendation TEXT;
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS ai_model_recommendation TEXT;
