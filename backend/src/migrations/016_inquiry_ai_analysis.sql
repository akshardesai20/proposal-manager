-- AI-derived fields for each inbound inquiry, populated by
-- backend/src/ai/analyzeInquiry.js right after an email is captured
-- during the poll cycle (see routes/inboxPoll.js). All nullable — if the
-- AI call fails, is unconfigured (no ANTHROPIC_API_KEY set), or hasn't
-- run yet, the inquiry still lands in the review queue exactly as before,
-- just without these fields filled in. This is enrichment, never a
-- requirement for the core email-capture flow to work.
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_summary TEXT;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_industry_type TEXT;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_suggested_segment TEXT;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_suggested_customer_name TEXT;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_email_type TEXT;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_analyzed_at TIMESTAMPTZ;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_error TEXT;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbound_inquiries_ai_segment_check') THEN
    ALTER TABLE inbound_inquiries ADD CONSTRAINT inbound_inquiries_ai_segment_check
      CHECK (ai_suggested_segment IN ('ww', 'industries', 'instrument_service') OR ai_suggested_segment IS NULL);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'inbound_inquiries_ai_email_type_check') THEN
    ALTER TABLE inbound_inquiries ADD CONSTRAINT inbound_inquiries_ai_email_type_check
      CHECK (ai_email_type IN ('new_inquiry', 'follow_up', 'negotiation', 'order', 'other') OR ai_email_type IS NULL);
  END IF;
END $$;
