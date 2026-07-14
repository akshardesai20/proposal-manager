-- Every offer gets a unique, unguessable token the moment it's generated
-- (see offers.js) — used to build a public "Accept this Quote" link with
-- no login required. accepted_at/accepted_by_name track whether and when
-- the customer actually accepted; NULL means not yet accepted. Nothing
-- here is guessable or enumerable — accept_token is a long random hex
-- string, not a sequential id.
ALTER TABLE offers ADD COLUMN IF NOT EXISTS accept_token TEXT;
ALTER TABLE offers ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;
ALTER TABLE offers ADD COLUMN IF NOT EXISTS accepted_by_name TEXT;
ALTER TABLE offers ADD COLUMN IF NOT EXISTS accepted_ip TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_offers_accept_token ON offers(accept_token);
