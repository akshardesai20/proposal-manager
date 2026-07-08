-- Adds a case-level note the engineer can type before generating an offer
-- (replaces the old hardcoded "Installation Accessories not included" line
-- in the PDF — that was static boilerplate, not something every offer
-- actually needs). Snapshotted onto each offer at generation time so past
-- revisions keep whatever note was in effect when they were generated.
ALTER TABLE cases ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE offers ADD COLUMN IF NOT EXISTS notes_snapshot TEXT;

-- Tightens the "Name of Instrument" wording to match what should actually
-- print on the offer (confirmed against a real generated document).
UPDATE siemens_families SET instrument_type = 'Ultrasonic Level Transmitter' WHERE base_code = '7ML511';
UPDATE siemens_families SET instrument_type = 'Electromagnetic Flow Sensor' WHERE base_code IN ('7ME6310', '7ME6320');
