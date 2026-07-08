-- Review queue for inbound customer inquiries pulled from the existing
-- mailbox via IMAP polling (see backend/src/mail/pollInbox.js). Emails are
-- NOT auto-converted into cases — free-text email content is too
-- unreliable to trust unattended (wrong customer match, garbled
-- requirement text, spam, etc.), so every inquiry lands here first for a
-- human to review, edit, and convert (or dismiss).
--
-- message_uid is the email's Message-ID header — globally unique per
-- email, used to dedupe so re-polling never creates duplicate rows even
-- if a message is fetched more than once.
CREATE TABLE IF NOT EXISTS inbound_inquiries (
  id                    SERIAL PRIMARY KEY,
  message_uid           TEXT,
  from_email            TEXT,
  from_name             TEXT,
  subject               TEXT,
  body_text             TEXT,
  received_at           TIMESTAMPTZ,
  matched_customer_id   INTEGER REFERENCES customers(id),
  status                TEXT NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'converted', 'dismissed')),
  created_case_id       INTEGER REFERENCES cases(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_inbound_inquiries_message_uid
  ON inbound_inquiries(message_uid) WHERE message_uid IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_inbound_inquiries_status
  ON inbound_inquiries(status, received_at DESC);
