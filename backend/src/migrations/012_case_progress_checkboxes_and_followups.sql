-- Three additions to the case detail page:
--
-- 1. cases.expected_order_date — a target/forecast date for when the order
--    is expected to be finalized (won or lost), set by the user. This is
--    DIFFERENT from the actual won/lost date, which is still the existing
--    `closed_at` timestamp, now stamped automatically via the new "Order
--    Won" / "Order Lost" checkboxes on the case detail page. If it turns
--    out only the actual date was wanted, this column is easy to drop —
--    flagging the assumption here since the request listed it separately
--    from the checkbox list.
--
-- 2. case_followups — an append-only log of follow-up entries (date +
--    free-text update), one row per follow-up, so every follow-up is kept
--    in history rather than overwriting a single "last follow-up" field.
--
-- 3. negotiation_completed_at + the 'negotiation_complete' stage value —
--    the one milestone in the new checkbox list that had no existing
--    column or stage value to reuse. Costing Completed, Offer Prepared,
--    Offer Submitted (existing 'offer_sent' stage, relabeled in the UI),
--    Order Won, and Order Lost all reuse columns/stages that already
--    existed (costing_completed_at, offer_prepared_at, offer_sent_at,
--    outcome + closed_at) — only this one needed something new.

ALTER TABLE cases ADD COLUMN IF NOT EXISTS expected_order_date DATE;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS negotiation_completed_at TIMESTAMPTZ;

-- Widen the stage CHECK constraint to allow the new 'negotiation_complete'
-- value. The constraint was created inline/unnamed in 001_init, so Postgres
-- auto-named it '<table>_<column>_check'.
ALTER TABLE cases DROP CONSTRAINT IF EXISTS cases_stage_check;
ALTER TABLE cases ADD CONSTRAINT cases_stage_check
  CHECK (stage IN ('enquiry','costing','costing_complete','offer_prepared','offer_sent','negotiation','negotiation_complete','won','lost'));

CREATE TABLE IF NOT EXISTS case_followups (
  id            SERIAL PRIMARY KEY,
  case_id       INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  followup_date DATE NOT NULL,
  update_text   TEXT NOT NULL,
  created_by    INTEGER REFERENCES users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_case_followups_case ON case_followups(case_id, followup_date DESC);
