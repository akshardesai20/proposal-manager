-- Expands the customer master record to the full set requested: name,
-- address, email, contact person, GST number (phone and code already
-- existed). Also adds a place to remember which running offer-reference
-- number a case has been allocated, so revisions (R0, R1, R2...) reuse the
-- same number instead of consuming a new one each time.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'attn') THEN
    ALTER TABLE customers RENAME COLUMN attn TO contact_person;
  END IF;
END $$;

ALTER TABLE customers ADD COLUMN IF NOT EXISTS gst_number TEXT;
ALTER TABLE cases ADD COLUMN IF NOT EXISTS offer_seq INTEGER;

CREATE INDEX IF NOT EXISTS idx_customers_name ON customers (UPPER(name));
