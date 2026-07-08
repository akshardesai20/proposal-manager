-- Adds what's needed to match the real sample offer document
-- (1079_Forozabad_NTPPL, reviewed directly):
--   - siemens_families gets a short trade name (e.g. "LU240") separate from
--     the full branded family name, and a generic instrument_type (e.g.
--     "Level Transmitter") for the offer table's "Name of Instrument" column.
--   - siemens_positions/options can flag which position defines the
--     product's "Range" (e.g. LU240's measurement range) and give it a
--     compact display label ("6 m") distinct from the full technical
--     meaning text.
--   - costing_items gains the matching per-line fields so the offer PDF's
--     quotation table (Name of Instrument | Model No. | Description |
--     Range | Qty | Unit Price | Total) can be populated directly.

ALTER TABLE siemens_families ADD COLUMN IF NOT EXISTS trade_name TEXT;
ALTER TABLE siemens_families ADD COLUMN IF NOT EXISTS instrument_type TEXT;

ALTER TABLE siemens_positions ADD COLUMN IF NOT EXISTS is_range BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE siemens_position_options ADD COLUMN IF NOT EXISTS short_label TEXT;

ALTER TABLE costing_items ADD COLUMN IF NOT EXISTS instrument_name TEXT;
ALTER TABLE costing_items ADD COLUMN IF NOT EXISTS product_name TEXT;
ALTER TABLE costing_items ADD COLUMN IF NOT EXISTS range_value TEXT;

-- Populate trade_name / instrument_type for the four seeded families.
UPDATE siemens_families SET trade_name = 'LU240', instrument_type = 'Level Transmitter' WHERE base_code = '7ML511';
UPDATE siemens_families SET trade_name = 'MAG 3100', instrument_type = 'Flow Sensor' WHERE base_code = '7ME6310';
UPDATE siemens_families SET trade_name = 'MAG 3100 HT', instrument_type = 'Flow Sensor' WHERE base_code = '7ME6320';
UPDATE siemens_families SET trade_name = 'LT500', instrument_type = 'Level Controller' WHERE base_code = '7ML60';

-- Mark LU240's "Measurement range/wetted parts" position as the Range
-- indicator, with compact labels matching the convention seen in the real
-- offer ("6meter", "12meter").
UPDATE siemens_positions SET is_range = true
WHERE family_id = (SELECT id FROM siemens_families WHERE base_code = '7ML511') AND position_no = 3;

UPDATE siemens_position_options SET short_label = '3meter'
WHERE position_id = (
  SELECT p.id FROM siemens_positions p JOIN siemens_families f ON f.id = p.family_id
  WHERE f.base_code = '7ML511' AND p.position_no = 3
) AND character IN ('B', 'C');

UPDATE siemens_position_options SET short_label = '6meter'
WHERE position_id = (
  SELECT p.id FROM siemens_positions p JOIN siemens_families f ON f.id = p.family_id
  WHERE f.base_code = '7ML511' AND p.position_no = 3
) AND character IN ('D', 'E');

UPDATE siemens_position_options SET short_label = '12meter'
WHERE position_id = (
  SELECT p.id FROM siemens_positions p JOIN siemens_families f ON f.id = p.family_id
  WHERE f.base_code = '7ML511' AND p.position_no = 3
) AND character IN ('G', 'H');
