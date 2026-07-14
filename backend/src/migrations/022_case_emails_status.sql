-- Until now, only successfully-sent emails were ever recorded in
-- case_emails — a failed send attempt just returned an error to the
-- browser and left no trace anywhere. That's a real gap for an Outbox
-- view meant to show "did this actually go out" — a failed attempt is
-- exactly the kind of thing someone needs to see and retry, not have
-- silently disappear.
--
-- status defaults to 'sent' since every existing row already represents
-- a successful send (failures were never persisted before this).
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'sent';
ALTER TABLE case_emails ADD COLUMN IF NOT EXISTS error_message TEXT;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'case_emails_status_check') THEN
    ALTER TABLE case_emails ADD CONSTRAINT case_emails_status_check
      CHECK (status IN ('sent', 'failed'));
  END IF;
END $$;
