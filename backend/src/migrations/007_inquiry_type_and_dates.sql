-- Type of Inquiry (Purchase / Budgetary / Tender) and the two dates needed
-- to compute proposal-submission accuracy and on-time performance later:
-- scheduled_offer_date (target/planned date, set by the user) and the
-- actual date (reused from the existing offer_prepared_at timestamp — no
-- new column needed there, it's already captured automatically whenever
-- an offer is generated).
ALTER TABLE cases ADD COLUMN IF NOT EXISTS inquiry_type TEXT;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS scheduled_offer_date DATE;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cases_inquiry_type_check') THEN
    ALTER TABLE cases ADD CONSTRAINT cases_inquiry_type_check
      CHECK (inquiry_type IN ('purchase', 'budgetary', 'tender') OR inquiry_type IS NULL);
  END IF;
END $$;
