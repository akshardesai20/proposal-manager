-- Shruhi Instrumentation Proposal Portal — initial schema
-- Run via `npm run migrate` (backend/scripts/migrate.js)

CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('admin', 'sales_engineer', 'costing_engineer')),
  designation   TEXT,
  phone         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customers (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  code       TEXT UNIQUE,
  attn       TEXT,
  email      TEXT,
  phone      TEXT,
  address    TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 'stage' always holds the current stage. Full history lives in case_events —
-- nothing here gets overwritten in a way that loses information.
CREATE TABLE IF NOT EXISTS cases (
  id                        SERIAL PRIMARY KEY,
  customer_id               INTEGER NOT NULL REFERENCES customers(id),
  requirement_text          TEXT,
  assigned_sales_engineer   INTEGER REFERENCES users(id),
  assigned_costing_engineer INTEGER REFERENCES users(id),
  stage                     TEXT NOT NULL DEFAULT 'enquiry'
                              CHECK (stage IN ('enquiry','costing','costing_complete','offer_prepared','offer_sent','negotiation','won','lost')),
  outcome                   TEXT CHECK (outcome IN ('won','lost') OR outcome IS NULL),
  -- convenience columns, derived from the latest matching case_events row --
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  costing_started_at        TIMESTAMPTZ,
  costing_completed_at      TIMESTAMPTZ,
  offer_prepared_at         TIMESTAMPTZ,
  offer_sent_at             TIMESTAMPTZ,
  closed_at                 TIMESTAMPTZ
);

-- Full audit trail of every stage transition. Source of truth for history;
-- the timestamp columns on `cases` are just a fast-read cache of the latest ones.
CREATE TABLE IF NOT EXISTS case_events (
  id         SERIAL PRIMARY KEY,
  case_id    INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  from_stage TEXT,
  to_stage   TEXT NOT NULL,
  changed_by INTEGER REFERENCES users(id),
  note       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Decode structure only — no prices. Prices are looked up on the Siemens
-- portal by the engineer and entered directly on the costing line.
CREATE TABLE IF NOT EXISTS siemens_families (
  id          SERIAL PRIMARY KEY,
  base_code   TEXT NOT NULL UNIQUE,        -- e.g. '6DR5110'
  family      TEXT NOT NULL,               -- e.g. 'SIPART PS2'
  short_name  TEXT,                        -- e.g. 'Single Acting Positioner'
  description TEXT
);

CREATE TABLE IF NOT EXISTS siemens_positions (
  id          SERIAL PRIMARY KEY,
  family_id   INTEGER NOT NULL REFERENCES siemens_families(id) ON DELETE CASCADE,
  position_no INTEGER NOT NULL,            -- order in the model code
  name        TEXT NOT NULL,               -- e.g. 'Explosion protection'
  is_fix      BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (family_id, position_no)
);

CREATE TABLE IF NOT EXISTS siemens_position_options (
  id          SERIAL PRIMARY KEY,
  position_id INTEGER NOT NULL REFERENCES siemens_positions(id) ON DELETE CASCADE,
  character   TEXT NOT NULL,               -- the code character, e.g. 'N'
  meaning     TEXT NOT NULL,
  UNIQUE (position_id, character)
);

CREATE TABLE IF NOT EXISTS siemens_suffixes (
  id        SERIAL PRIMARY KEY,
  family_id INTEGER NOT NULL REFERENCES siemens_families(id) ON DELETE CASCADE,
  code      TEXT NOT NULL,                 -- e.g. 'E49'
  meaning   TEXT NOT NULL,
  UNIQUE (family_id, code)
);

CREATE TABLE IF NOT EXISTS siemens_addons (
  id          SERIAL PRIMARY KEY,
  code        TEXT NOT NULL UNIQUE,        -- e.g. '6DR4004-8F'
  name        TEXT NOT NULL,
  description TEXT
);

-- One row per line item on a case. source = 'catalog' (built via decoder)
-- or 'manual' (free-text) — both write the same shape.
CREATE TABLE IF NOT EXISTS costing_items (
  id               SERIAL PRIMARY KEY,
  case_id          INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  source           TEXT NOT NULL CHECK (source IN ('catalog','manual')),
  model_code       TEXT,                    -- populated when source = 'catalog'
  family           TEXT,
  description      TEXT NOT NULL,
  config_bullets   JSONB DEFAULT '[]',
  addons           JSONB DEFAULT '[]',      -- [{code, name, price}]
  qty              INTEGER NOT NULL DEFAULT 1,
  list_price       NUMERIC(12,2) DEFAULT 0,
  discount_pct     NUMERIC(5,2) DEFAULT 60,
  margin_pct       NUMERIC(5,2) DEFAULT 30,
  final_unit_price NUMERIC(12,2) DEFAULT 0,
  sort_order       INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offers (
  id              SERIAL PRIMARY KEY,
  case_id         INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  ref             TEXT NOT NULL,             -- SI/nnnn/CODE/Rn
  revision        INTEGER NOT NULL DEFAULT 0,
  prepared_by     INTEGER REFERENCES users(id),
  items_snapshot  JSONB NOT NULL,
  terms_snapshot  JSONB NOT NULL,
  pdf_url         TEXT,
  generated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (case_id, revision)
);

CREATE TABLE IF NOT EXISTS reminders (
  id             SERIAL PRIMARY KEY,
  case_id        INTEGER NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  rule           TEXT NOT NULL,              -- e.g. 'no_stage_change_7_days'
  due_at         TIMESTAMPTZ NOT NULL,
  notify_user_id INTEGER REFERENCES users(id),
  channel        TEXT NOT NULL DEFAULT 'portal' CHECK (channel IN ('portal','email')),
  status         TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','dismissed')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- running offer-reference sequence, mirrors the Phase 1 prototype's counter
CREATE TABLE IF NOT EXISTS offer_sequence (
  id       INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  next_seq INTEGER NOT NULL DEFAULT 7574
);
INSERT INTO offer_sequence (id, next_seq) VALUES (1, 7574) ON CONFLICT (id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_cases_stage ON cases(stage);
CREATE INDEX IF NOT EXISTS idx_case_events_case ON case_events(case_id);
CREATE INDEX IF NOT EXISTS idx_costing_items_case ON costing_items(case_id);
CREATE INDEX IF NOT EXISTS idx_reminders_due ON reminders(due_at) WHERE status = 'pending';
