-- Formalizes "manufacturer" as a real concept, ahead of supporting more
-- than Siemens. Added in three safe steps so this works cleanly against
-- a table that already has real catalog data in it:
--   1. Create manufacturers, seed Siemens.
--   2. Add manufacturer_id as NULLABLE, backfill every existing family to
--      Siemens.
--   3. Only now make it NOT NULL — safe, since every row has a value by
--      this point.
CREATE TABLE IF NOT EXISTS manufacturers (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO manufacturers (name) VALUES ('Siemens') ON CONFLICT (name) DO NOTHING;

ALTER TABLE siemens_families ADD COLUMN IF NOT EXISTS manufacturer_id INTEGER REFERENCES manufacturers(id);

UPDATE siemens_families
SET manufacturer_id = (SELECT id FROM manufacturers WHERE name = 'Siemens')
WHERE manufacturer_id IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'siemens_families' AND column_name = 'manufacturer_id' AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE siemens_families ALTER COLUMN manufacturer_id SET NOT NULL;
  END IF;
END $$;
