-- Tracks every email sent from, or matched to, a case — the foundation
-- for "send offer", "send follow-up", and (next phase) auto-matching
-- inbound replies back to the case they belong to.
--
-- message_id / in_reply_to are standard email headers: message_id is this
-- email's own unique identifier, in_reply_to references the message it's
-- replying to. Storing both lets a future poll pass match an inbound
-- reply's in_reply_to/references against a message_id we sent, and attach
-- it to the right case automatically — the same threading mechanism every
-- email client uses.
CREATE TABLE IF NOT EXISTS case_emails (
  id           SERIAL PRIMARY KEY,
  case_id      INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  direction    TEXT NOT NULL CHECK (direction IN ('outbound', 'inbound')),
  to_email     TEXT,
  from_email   TEXT,
  subject      TEXT,
  body         TEXT,
  message_id   TEXT,
  in_reply_to  TEXT,
  offer_id     INTEGER REFERENCES offers(id) ON DELETE SET NULL,
  created_by   INTEGER REFERENCES users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_case_emails_case ON case_emails(case_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_case_emails_message_id ON case_emails(message_id);
