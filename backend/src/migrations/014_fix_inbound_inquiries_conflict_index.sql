-- Fixes a bug in migration 013: the ON CONFLICT (message_uid) clause used
-- in pollInbox.js's insert cannot match a *partial* unique index (one with
-- a WHERE clause) unless the same predicate is repeated in the ON
-- CONFLICT clause itself — Postgres requires an exact match for conflict
-- inference. This caused every insert to fail with "there is no unique or
-- exclusion constraint matching the ON CONFLICT specification".
--
-- The partial WHERE clause was unnecessary in the first place: Postgres
-- unique constraints already treat NULL as distinct from every other NULL,
-- so multiple NULL message_uid rows were never actually at risk of
-- violating a plain (non-partial) unique index. Switching to a plain
-- unique index both fixes the bug and is simpler.
DROP INDEX IF EXISTS idx_inbound_inquiries_message_uid;
CREATE UNIQUE INDEX IF NOT EXISTS idx_inbound_inquiries_message_uid
  ON inbound_inquiries(message_uid);
