-- Two additions to support smarter customer handling on the Inbox page:
--
-- 1. ai_suggested_customer_phone — a phone/mobile number extracted from
--    the email signature, if present. Genuinely new information (the
--    sender's email address alone never gives you this) — useful when
--    creating a brand-new customer record straight from an inquiry.
--
-- 2. ai_matched_customer_id — distinct from matched_customer_id (which is
--    an exact match on the sender's email address). This is a fuzzy match
--    on the AI-extracted company NAME against existing customers, for the
--    common case where someone emails from a personal Gmail address but
--    their company is already in the system under a different contact's
--    email. Nullable, no cascade needed beyond the customer being
--    deletable (SET NULL keeps the inquiry's history intact).
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_suggested_customer_phone TEXT;
ALTER TABLE inbound_inquiries ADD COLUMN IF NOT EXISTS ai_matched_customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL;
