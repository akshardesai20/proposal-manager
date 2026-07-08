-- Editable case reference (falls back to CASE-NNNN display when unset).
ALTER TABLE cases ADD COLUMN IF NOT EXISTS reference TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_cases_reference ON cases (reference) WHERE reference IS NOT NULL;

-- User management: broader role set (Sales, Proposal, Service, Store,
-- Account, plus Admin), WhatsApp contact, a notifications flag for the
-- planned email-notification feature, and an active/inactive status.
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('admin', 'sales', 'proposal', 'service', 'store', 'account', 'sales_engineer', 'costing_engineer'));

ALTER TABLE users ADD COLUMN IF NOT EXISTS whatsapp TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_status_check') THEN
    ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status IN ('active', 'inactive'));
  END IF;
END $$;
