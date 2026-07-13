-- Tracks each bulk-import run (who did it, when, how many rows) and tags
-- every case created that way, so imported cases are always distinguishable
-- and auditable from ones created normally through the app.
CREATE TABLE IF NOT EXISTS import_batches (
  id           SERIAL PRIMARY KEY,
  filename     TEXT,
  imported_by  INTEGER REFERENCES users(id),
  row_count    INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cases ADD COLUMN IF NOT EXISTS import_batch_id INTEGER REFERENCES import_batches(id);
