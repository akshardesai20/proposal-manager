-- Mirrors the AI fields already on inbound_inquiries (migration 016), but
-- for emails that get auto-matched directly to an existing case (see
-- pollInbox.js) instead of landing in the generic review queue. Same
-- philosophy as inbound_inquiries: analysis is on-demand only, triggered
-- from the case's Emails section, never automatic on poll.
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS ai_summary TEXT;
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS ai_email_type TEXT;
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS ai_analyzed_at TIMESTAMPTZ;
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS ai_error TEXT;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'case_emails_ai_email_type_check') THEN
    ALTER TABLE case_emails ADD CONSTRAINT case_emails_ai_email_type_check
      CHECK (ai_email_type IN ('new_inquiry', 'follow_up', 'negotiation', 'order', 'other') OR ai_email_type IS NULL);
  END IF;
END $$;

-- Needed so inbound-email inserts can use ON CONFLICT (message_id) DO
-- NOTHING for clean dedup on re-poll — a plain unique index, not partial,
-- learned the hard way earlier (see migration 014) that ON CONFLICT
-- can't infer against a partial index unless its WHERE clause is repeated
-- exactly in the conflict clause. Both inbound and outbound inserts
-- always set message_id, so a plain unique index is the right fit here.
CREATE UNIQUE INDEX IF NOT EXISTS idx_case_emails_message_id_unique ON case_emails(message_id);
