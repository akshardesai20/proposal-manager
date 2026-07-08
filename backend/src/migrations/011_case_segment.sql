-- Business segment for each case: WW, Industries, or Instrument Service.
-- Selected by the user during case configuration (the case creation form)
-- and editable afterwards the same way inquiry_type already is.
--
-- Drives the three segment tabs on the Proposals ("List of Proposal")
-- page and feeds the dashboard's planned metrics broken out by segment
-- (see Dashboard.jsx "Planned metrics" list).
--
-- Nullable rather than NOT NULL: existing live cases predate this field
-- and have no segment recorded. The frontend requires a selection for
-- new cases going forward; old cases will simply show under no tab
-- until someone backfills them (or we add an "Unassigned" tab later).
ALTER TABLE cases ADD COLUMN IF NOT EXISTS segment TEXT;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cases_segment_check') THEN
    ALTER TABLE cases ADD CONSTRAINT cases_segment_check
      CHECK (segment IN ('ww', 'industries', 'instrument_service') OR segment IS NULL);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_cases_segment ON cases(segment);
