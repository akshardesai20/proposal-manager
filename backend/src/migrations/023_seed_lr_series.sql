-- Seeds the SITRANS LR radar level transmitter families from the FI 01 · April 2026
-- catalog sheets: LR100 (7ML530), LR110 (7ML531), LR120 (7ML532), LR140 (7ML533),
-- LR150 (7ML534), LR510 (7ML751), LR530 (7ML753), LR550 (7ML755), LR580 (7ML758).
--
-- LR100/LR110/LR120/LR140/LR150 are the compact PVDF-enclosure series (10-30 m range).
-- LR510/LR530/LR550/LR580 are the SITRANS LR500 series (80 GHz, up to 120 m, high
-- temperature/pressure, graphical HMI, aluminum enclosure) — see also LR553/LR500 series
-- shared spec sheet (measuring principle, HART 7, IEC 62828 1 mm accuracy, certificates)
-- which is not modeled as its own family since it has no distinct base_code/order code.
--
-- KNOWN LIMITATIONS:
--   1. For LR510/LR530/LR550/LR580, "Process connection type and material" is modeled as
--      a single 2-character position (matching the two-column layout of the source catalog
--      table), consistent with how FMS300's 2-char Diameter position was handled in
--      migration 008. The decode engine's longest-match-first resolution handles this
--      without changes.
--   2. LR120/LR140/LR150 process-pressure/temperature derating curves and LR510/530's
--      flange-size-dependent max measuring range table are not modeled as selectable
--      positions; these stay as manual verification notes for the quoting engineer.
--   3. Suffix (order code) lists are a representative subset — mounting-bracket and
--      cable-length-dependent tables run long and aren't fully enumerated.

-- ============================================================
-- FAMILY: SITRANS LR100 (7ML530)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML530', 'SITRANS LR100', 'Compact Radar Level Transmitter',
  'SITRANS LR100 2-wire loop powered W band (80 GHz) FMCW radar level transmitter for continuous level measurement of liquids and slurries to a range of 10 m (32.8 ft). Hermetically sealed PVDF enclosure, 8 m (26 ft) integrated cable connection, 4...20 mA loop powered, non-intrusive measurement through plastic vessel tops.',
  'LR100', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML530'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Process connection', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Process connection
  (1,'A','1-½" NPT [(Taper), ASME B1.20.1] / electrical connection 1" NPT', NULL),
  (1,'B','R 1-½" [(BSPT), EN 10226] / electrical connection 1" BSPT', NULL),
  (1,'C','G 1-½" [(BSPP), EN ISO 228-1] / electrical connection 1" BSPT', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Tag (device parameter, max. 32 characters) plate, stainless steel 304/1.4301')
)AS v(code, meaning)
WHERE base_code = '7ML530'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR110 (7ML531)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML531', 'SITRANS LR110', 'Compact Radar Level Transmitter',
  'SITRANS LR110 compact W band (80 GHz) FMCW radar level transmitter for continuous level measurement of liquids, slurries, or solids to a range of 20 m (65.6 ft). Hermetically sealed PVDF enclosure, 4...20 mA loop powered with HART [optional 4-wire Modbus RTU], Bluetooth connectivity for setup with SITRANS mobile IQ, hazardous area variants available.',
  'LR110', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML531'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communications', false, false),
    (2,'Bluetooth function', false, false),
    (3,'Cable length', false, true),
    (4,'Process connection', false, false),
    (5,'Type of protection', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Communications
  (1,'0','HART (4 ... 20 mA)', NULL),
  (1,'3','Modbus RTU (available only with Type of protection options A and G, and Bluetooth option 1)', NULL),
  -- Bluetooth function
  (2,'0','Without', NULL),
  (2,'1','With', NULL),
  -- Cable length
  (3,'A','5 m', '5m'),
  (3,'B','10 m', '10m'),
  (3,'C','30 m', '30m'),
  (3,'D','50 m', '50m'),
  (3,'E','100 m', '100m'),
  -- Process connection
  (4,'A','1-½" NPT [(Taper), ASME B1.20.1] / electrical connection 1" NPT', NULL),
  (4,'B','R 1-½" [(BSPT), EN 10226] / electrical connection 1" BSPT', NULL),
  (4,'C','G 1-½" [(BSPP), EN ISO 228-1] / electrical connection 1" BSPT', NULL),
  -- Type of protection
  (5,'A','Ordinary Locations/General Purpose (Non-Ex), CE, CFMUS, CCSAUS, RCM (not available in combination with regional Ex approval order codes)', NULL),
  (5,'B','ATEX II 1G, 1/2G Ex ia IIC T4 Ga, Ga/Gb; ATEX II 1D, 1/2D Ex ia IIIC T134°C Da, Da/Db; Gas Ex-Zone 0/Class 1, Div. 1; Dust Ex-Zone 20, 21, Class II & III Div. 1 (must be ordered with a regional Ex approval order code)', NULL),
  (5,'G','ATEX II 2G Ex ib mb IIC T4 Gb; ATEX II 1D/1/2D/2D Ex ta/tb IIIC dust approvals; Zone 1, 1/2, Zone 20, 21, 22, (Class I, Div. 2), Class II & III, Div. 1', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Tag (device parameter, max. 32 characters) plate, stainless steel 304/1.4301'),
  ('C25','Inspection certificate 3.1 (EN 10204) - device with test data'),
  ('E49','Regional Ex approval: CFMUS, CCSAUS, ATEX, IECEx'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E27','Regional Ex approval: NEPSI, CCOE'),
  ('E47','Regional Ex approval: ATEX, IECEx'),
  ('E29','Regional Ex approval: CSA-Japan-Ex'),
  ('E24','Regional Ex approval: EACEx'),
  ('E61','WHG and VLAREM II approval'),
  ('E84','NSF 61 Drinking Water and FDA, EG1935/2004 approval')
)AS v(code, meaning)
WHERE base_code = '7ML531'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR120 (7ML532)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML532', 'SITRANS LR120', 'Radar Level Transmitter',
  'SITRANS LR120 compact W band (80 GHz) FMCW radar level transmitter for continuous level measurement of liquids and solids to a range of 30 m (98.4 ft), integrated cable connection. Approved for open air applications outside of a tank. Long range, narrow beam suitable for wet wells with obstructions or solids level measurement.',
  'LR120', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML532'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communications', false, false),
    (2,'Bluetooth function', false, false),
    (3,'Cable length', false, true),
    (4,'Type of protection', false, false),
    (5,'Electrical connection of the cable entry', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Communications
  (1,'0','HART (4 ... 20 mA)', NULL),
  (1,'3','Modbus RTU (available only with Type of protection options A and G, and Bluetooth option 1)', NULL),
  -- Bluetooth function
  (2,'0','Without', NULL),
  (2,'1','With', NULL),
  -- Cable length
  (3,'A','5 m', '5m'),
  (3,'B','10 m', '10m'),
  (3,'C','30 m', '30m'),
  (3,'D','50 m', '50m'),
  (3,'E','100 m', '100m'),
  -- Type of protection
  (4,'A','Ordinary Locations/General Purpose (Non-Ex), CFMUS, CCSAUS, CE, RCM (not available in combination with regional Ex approval order codes)', NULL),
  (4,'B','ATEX II 1G, 1/2G Ex ia IIC T4 Ga, Ga/Gb; ATEX II 1D, 1/2D Ex ia IIIC T134 °C Da, Da/Db; Gas Ex-Zone 0/Class 1, Div. 1; Dust Ex-Zone 20, 21, Class II & III Div. 1 (must be ordered with a regional Ex approval order code)', NULL),
  (4,'G','ATEX II 2G Ex ib mb IIC T4 Gb; ATEX II 1D/1/2D/2D Ex ta/tb IIIC dust approvals; Zone 1, 1/2, Zone 20, 21, 22, (Class I, Div. 2), Class II & III, Div. 1', NULL),
  -- Electrical connection of the cable entry
  (5,'H','1" BSPT', NULL),
  (5,'P','1" NPT', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Tag (device parameter, max. 32 characters) plate, stainless steel 304/1.4301'),
  ('C25','Inspection certificate 3.1 (EN 10204) - device with test data'),
  ('E49','Regional Ex approval: CFMUS, CCSAUS, ATEX, IECEx'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E27','Regional Ex approval: NEPSI, CCOE'),
  ('E47','Regional Ex approval: ATEX, IECEx'),
  ('E29','Regional Ex approval: CSA-Japan-Ex'),
  ('E24','Regional Ex approval: EACEx'),
  ('E61','WHG and VLAREM II approval'),
  ('E84','NSF 61 Drinking Water and FDA, EG1935/2004 approval')
)AS v(code, meaning)
WHERE base_code = '7ML532'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR140 (7ML533)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML533', 'SITRANS LR140', 'Radar Level Transmitter',
  'SITRANS LR140 2-wire loop powered W band (80 GHz) FMCW radar level transmitter for continuous level measurement of liquids and slurries to a range of 10 m (32.8 ft). Chemically resistant PVDF sensor, measurement possible non-intrusively through plastic vessel tops, Bluetooth connectivity with SITRANS mobile IQ, compact design for limited space installations.',
  'LR140', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML533'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Process connection', false, false),
    (2,'Electrical connections / Cable entry', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Process connection
  (1,'A','1-½" NPT', NULL),
  (1,'B','R 1-½" (BSPT)', NULL),
  (1,'C','G 1-½" (BSPP)', NULL),
  -- Electrical connections / Cable entry
  (2,'F','M20', NULL),
  (2,'K','½" NPT', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Tag (device parameter, max. 32 characters) plate, stainless steel 304/1.4301')
)AS v(code, meaning)
WHERE base_code = '7ML533'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR150 (7ML534)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML534', 'SITRANS LR150', 'Radar Level Transmitter',
  'SITRANS LR150 compact W band (80 GHz) FMCW radar level transmitter with chemically resistant PVDF sensor, for continuous level measurement of liquids, slurries, and solids to a range of 20 m (65.6 ft). HART 7.0, 4...20 mA loop powered, optional HMI with pushbutton programming and local diagnostic data, Bluetooth connectivity with SITRANS mobile IQ, hazardous area variants available.',
  'LR150', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML534'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Bluetooth function', false, false),
    (2,'Process connection', false, false),
    (3,'Type of protection', false, false),
    (4,'Electrical connections / cable entry', false, false),
    (5,'Local HMI', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Bluetooth function
  (1,'0','Without', NULL),
  (1,'1','With', NULL),
  -- Process connection
  (2,'A','1-½" NPT', NULL),
  (2,'B','R 1-½" (BSPT)', NULL),
  (2,'C','G 1-½" (BSPP)', NULL),
  -- Type of protection
  (3,'A','Ordinary Locations/General Purpose (Non-Ex) (not available with a regional Ex approval order code)', NULL),
  (3,'C','ATEX II 1G, 1/2G Ex ia IIC T4 Ga, Ga/Gb; Gas Ex-Zone 0/Class 1, Div. 1 & Div. 2 (must be ordered with a regional Ex approval order code)', NULL),
  -- Electrical connections / cable entry
  (4,'F','M20', NULL),
  (4,'K','½" NPT', NULL),
  -- Local HMI
  (5,'0','Without display (closed lid of PBT/PC material)', NULL),
  (5,'1','With display (closed lid of PBT/PC material)', NULL),
  (5,'3','With display (clear lid with plastic window of PC material)', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Tag (device parameter, max. 32 characters) plate, stainless steel 304/1.4301'),
  ('C25','Inspection certificate 3.1 (EN 10204) - device with test data'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E27','Regional Ex approval: NEPSI, CCOE'),
  ('E24','Regional Ex approval: EACEx'),
  ('E49','Regional Ex approval: ATEX, IECEx, CFMUS, CCSAUS'),
  ('E29','Regional Ex approval: CSA-Japan-Ex'),
  ('E61','WHG and VLAREM II approval'),
  ('E84','NSF 61 Drinking Water and FDA, EG1935/2004 approval')
)AS v(code, meaning)
WHERE base_code = '7ML534'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR510 (7ML751)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML751', 'SITRANS LR510', 'Radar Level Transmitter, Threaded Connection',
  'SITRANS LR510 80 GHz radar level transmitter, threaded lens antenna, for continuous non-contact level measurement of liquids and slurries to a range of 30 m (98 ft). Part of the SITRANS LR500 series (1 mm accuracy per IEC 62828, graphical HMI, HART 7, optional SLOD second line of defense).',
  'LR510', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML751'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communications', false, false),
    (2,'Sealing material of the antenna/process connection', false, false),
    (3,'Process connection type and material', false, false),
    (4,'Second line of defence (SLOD) gas-tight seal', false, false),
    (5,'Enclosure', true, false),
    (6,'Type of protection', false, false),
    (7,'Electrical connection', false, false),
    (8,'Local HMI', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Communications
  (1,'0','4 ... 20 mA, HART', NULL),
  -- Sealing material of the antenna/process connection
  (2,'0','PEEK / FKM, ‑40 ... +150 °C (‑40 ... +302 °F)', NULL),
  (2,'1','PEEK / FKM, ‑40 ... +200 °C (‑40 ... +392 °F)', NULL),
  (2,'2','PEEK / FFKM, ‑20 ... +150 °C (‑4 ... +302 °F)', NULL),
  (2,'3','PEEK / FFKM, ‑20 ... +250 °C (‑4 ... +482 °F)', NULL),
  -- Process connection type and material
  (3,'AA','Thread, DIN 3852-2-A-G¾", 316/316L', NULL),
  (3,'AB','Thread, DIN 3852-2-A-G¾", Alloy C22 (2.4602)', NULL),
  (3,'AC','Thread, ASME B1.20.1, ¾" NPT, 316/316L', NULL),
  (3,'AD','Thread, ASME B1.20.1, ¾" NPT, Alloy C22 (2.4602)', NULL),
  (3,'BA','Thread, DIN 3852-2-A-G1", 316/316L', NULL),
  (3,'BB','Thread, DIN 3852-2-A-G1", Alloy C22 (2.4602)', NULL),
  (3,'BC','Thread, ASME B1.20.1, 1" NPT, 316/316L', NULL),
  (3,'BD','Thread, ASME B1.20.1, 1" NPT, Alloy C22 (2.4602)', NULL),
  (3,'CA','Thread, DIN 3852-2-A-G1-½", 316/316L', NULL),
  (3,'CB','Thread, DIN 3852-2-A-G1-½", Alloy C22 (2.4602)', NULL),
  (3,'CC','Thread, ASME B1.20.1, 1-½" NPT, 316/316L', NULL),
  (3,'CD','Thread, ASME B1.20.1, 1-½" NPT, Alloy C22 (2.4602)', NULL),
  -- Second line of defence (SLOD) gas-tight seal
  (4,'0','SLOD not included', NULL),
  (4,'1','SLOD included (internal fused glass seal)', NULL),
  -- Enclosure
  (5,'4','Single compartment enclosure', NULL),
  -- Type of protection
  (6,'A','Non Ex - General purpose', NULL),
  (6,'B','Intrinsically safe Ex ia / IS (Class I, II, III, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  (6,'C','Flameproof Ex d (Class I, Division 1)', NULL),
  (6,'D','Non-incendive (Class I, Division 2) (available only with -Z regional hazardous approval option E48)', NULL),
  (6,'M','Dust Ignition proof, Ex t / DIP (Class II, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  -- Electrical connection
  (7,'F','M20', NULL),
  (7,'K','½" NPT', NULL),
  -- Local HMI
  (8,'0','None, with blind lid', NULL),
  (8,'1','Included, with blind lid', NULL),
  (8,'3','Included, with window lid', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C01','Pressure test certificate inspection certificate EN 10204-3.1 (AD2000-A4 / EN 12266-1) - process connection options AA, AB, BA, BB, CA, CB'),
  ('C02','Pressure test certificate inspection certificate EN 10204-3.1 (ASME B31.1 / B31.3) - process connection options AC, AD, BC, BD, CC, CD'),
  ('C11','Manufacturer''s test certificate M to DIN 55350, Part 18 and to ISO 9000 - performance'),
  ('C12','Inspection certificate EN 10204-3.1, material'),
  ('C13','Inspection certificate EN 10204-3.1, material with NACE MR0175 and MR0103'),
  ('C14','Test report EN 10204-2.2, material'),
  ('C15','Test report EN 10204-3.1, PMI test - XRF (X-Ray fluorescence)'),
  ('Y15','Stainless steel tag [69 x 50 mm], device parameters (max. 27 characters), plate, stainless steel 304/1.4301'),
  ('E24','Regional Ex approval: EAC Ex'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E26','Regional Ex approval: KCs (Korea)'),
  ('E27','Regional Ex approval: NEPSI (China)'),
  ('E28','Regional Ex approval: PESO (India)'),
  ('E29','Regional Ex approval: Japan'),
  ('E47','Regional Ex approval: ATEX (Europe), IECEx (International)'),
  ('E48','Regional Ex approval: CSA (Canada) and FM (USA)'),
  ('E49','Regional Ex approval: ATEX (Europe), IECEx (International), CSA (Canada), and FM (USA)')
)AS v(code, meaning)
WHERE base_code = '7ML751'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR530 (7ML753)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML753', 'SITRANS LR530', 'Radar Level Transmitter, Flanged Encapsulated PTFE',
  'SITRANS LR530 80 GHz radar level transmitter, flanged encapsulated PTFE antenna, for continuous non-contact level measurement of liquids and slurries to a range of 120 m (394 ft). Part of the SITRANS LR500 series, PTFE lens with integral PTFE gasket, optional SLOD second line of defense.',
  'LR530', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML753'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communications', false, false),
    (2,'Sealing material of the antenna/process connection', false, false),
    (3,'Process connection type and material', false, false),
    (4,'Second line of defence (SLOD) gas tight seal', false, false),
    (5,'Enclosure', true, false),
    (6,'Type of protection', false, false),
    (7,'Electrical connection', false, false),
    (8,'Local HMI', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Communications
  (1,'0','4 ... 20 mA, HART', NULL),
  -- Sealing material of the antenna/process connection
  (2,'0','PTFE / PTFE, ‑60 ... +150 °C (‑76 ... +302 °F)', NULL),
  (2,'1','PTFE / PTFE, ‑196 ... +200 °C (‑321 ... +392 °F)', NULL),
  -- Process connection type and material
  (3,'KA','Flange DN 25 PN 6, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'KB','Flange DN 50 PN 6, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'KC','Flange DN 80 PN 6, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'KD','Flange DN 100 PN 16, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'KE','Flange DN 150 PN 16, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'KF','Flange DN 200 PN 16, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'LA','Flange DN 25 PN 40, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'LB','Flange DN 50 PN 40, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'LC','Flange DN 80 PN 40, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'LD','Flange DN 100 PN 40, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'LE','Flange DN 150 PN 40, raised face, Form B1, EN 1092-1, DIN 2501 / 316/316L', NULL),
  (3,'MA','Flange 1" 150 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'MB','Flange 2" 150 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'MC','Flange 3" 150 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'MD','Flange 4" 150 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'ME','Flange 6" 150 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'MF','Flange 8" 150 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'NA','Flange 1" 300 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'NB','Flange 2" 300 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'NC','Flange 3" 300 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'ND','Flange 4" 300 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'NE','Flange 6" 300 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'NF','Flange 8" 300 lb RF, ASME B16.5 / 316/316L', NULL),
  (3,'VA','Flange DN 25 5K RF, JIS / 316/316L', NULL),
  (3,'VB','Flange DN 50 10K RF, JIS / 316/316L', NULL),
  (3,'VC','Flange DN 80 10K RF, JIS / 316/316L', NULL),
  (3,'VD','Flange DN 100 10K RF, JIS / 316/316L', NULL),
  (3,'VE','Flange DN 150 10K RF, JIS / 316/316L', NULL),
  -- Second line of defence (SLOD) gas tight seal
  (4,'0','SLOD not included', NULL),
  (4,'1','SLOD included (internal fused glass seal)', NULL),
  -- Enclosure
  (5,'4','Single compartment enclosure', NULL),
  -- Type of protection
  (6,'A','Non Ex - General purpose', NULL),
  (6,'B','Intrinsically safe Ex ia / IS (Class I, II, III, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  (6,'C','Flameproof Ex d (Class I, Division 1)', NULL),
  (6,'D','Non-incendive (Class I, Division 2) (available only with -Z regional Ex approval option E48)', NULL),
  (6,'M','Dust Ignition proof, Ex t / DIP (Class II, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  -- Electrical connection
  (7,'F','M20', NULL),
  (7,'K','½" NPT', NULL),
  -- Local HMI
  (8,'0','None, with blind lid', NULL),
  (8,'1','Included, with blind lid', NULL),
  (8,'3','Included, with window lid', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C01','Pressure test certificate inspection certificate EN 10204-3.1 (AD2000-A4 / EN12266-1) - process connection options KA...KF, LA...LE, VA...VE'),
  ('C02','Pressure test certificate inspection certificate EN 10204-3.1 (ASME B31.1 / B31.3) - process connection options MA...MF and NA...NF'),
  ('C11','Manufacturer''s test certificate M to DIN 55350, Part 18 and to ISO 9000 - performance'),
  ('C12','Inspection certificate EN 10204-3.1, material'),
  ('C13','Inspection certificate EN 10204-3.1, material with NACE MR0175 and MR0103'),
  ('C14','Test report EN 10204-2.2, material'),
  ('C15','Test report EN 10204-3.1, PMI test - XRF (X-Ray Fluorescence)'),
  ('Y15','Stainless steel tag [69 x 50 mm], device parameters (max. 27 characters), plate, stainless steel 304/1.4301'),
  ('E24','Regional Ex approval: EAC Ex'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E26','Regional Ex approval: KCs (Korea)'),
  ('E27','Regional Ex approval: NEPSI (China)'),
  ('E28','Regional Ex approval: PESO (India)'),
  ('E29','Regional Ex approval: Japan'),
  ('E47','Regional Ex approval: ATEX (Europe) and IECEx (International)'),
  ('E48','Regional Ex approval: CSA (Canada) and FM (USA)'),
  ('E49','Regional Ex approval: ATEX (Europe), IECEx (International), CSA (Canada), and FM (USA)')
)AS v(code, meaning)
WHERE base_code = '7ML753'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR550 (7ML755)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML755', 'SITRANS LR550', 'Radar Level Transmitter, Polymeric Horn Antenna',
  'SITRANS LR550 80 GHz radar level transmitter, polymeric horn antenna, for continuous non-contact level measurement of solids or liquids to a range of 120 m (394 ft). Part of the SITRANS LR500 series, PP-GF30 flange material, optional purge (self-cleaning) connection for dusty solids.',
  'LR550', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML755'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communications', false, false),
    (2,'Sealing material of the antenna/process connection', false, false),
    (3,'Process connection type and material', false, false),
    (4,'Purge (self-cleaning) connection', false, false),
    (5,'Enclosure', true, false),
    (6,'Type of protection', false, false),
    (7,'Electrical connection', false, false),
    (8,'Local HMI', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Communications
  (1,'0','4 ... 20 mA, HART', NULL),
  -- Sealing material of the antenna/process connection
  (2,'0','PP / PP / ‑40 ... +80 °C (‑40 ... +176 °F)', NULL),
  (2,'1','PP / FKM / ‑40 ... +80 °C (‑40 ... +176 °F)', NULL),
  (2,'2','PP / EPDM / ‑40 ... +80 °C (‑40 ... +176 °F)', NULL),
  -- Process connection type and material
  (3,'DA','Universal, plastic horn antenna / PP/PBT', NULL),
  (3,'DC','Without flange, with mounting bracket 300 mm / 316/316L', NULL),
  (3,'EC','Universal bolted flange 3" 150 lb, DN 80 PN16 / PP-GF30', NULL),
  (3,'FL','Flange DN 100 PN 6, flat face / PP-GF30', NULL),
  (3,'FD','Flange DN 100 PN16, flat face / PP-GF30', NULL),
  (3,'FE','Flange DN 150 PN16, flat face / PP-GF30', NULL),
  (3,'FF','Flange DN 200 PN16, flat face / PP-GF30', NULL),
  (3,'FG','Flange DN 250 PN16, flat face / PP-GF30', NULL),
  (3,'HC','Flange 3" 150lb FF, PP-GF30', NULL),
  (3,'HD','Flange 4" 150lb FF, PP-GF30', NULL),
  (3,'HE','Flange 6" 150lb FF, PP-GF30', NULL),
  (3,'HF','Flange 8" 150lb FF, PP-GF30', NULL),
  (3,'JD','Flange DN 100 10K FF, JIS / PP-GF30', NULL),
  (3,'JE','Flange DN 150 10K FF, JIS / PP-GF30', NULL),
  -- Purge (self-cleaning) connection
  (4,'0','No purge connection', NULL),
  (4,'1','With purge connection (only suitable for 15 psi or less process pressure; if Type of protection is B, C, D, or M then -Z option J01 non-return valve must also be selected; not available with process connection options DA, DC, EC, HC)', NULL),
  -- Enclosure
  (5,'4','Single compartment enclosure', NULL),
  -- Type of protection
  (6,'A','Non Ex - General purpose', NULL),
  (6,'B','Intrinsically safe Ex ia / IS (Class I, II, III, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  (6,'C','Flameproof Ex d (Class I, Division 1)', NULL),
  (6,'D','Non-incendive (Class I, Division 2) (available only with -Z regional hazardous approval option E48)', NULL),
  (6,'M','Dust Ignition proof, Ex t / DIP (Class II, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  -- Electrical connection
  (7,'F','M20', NULL),
  (7,'K','½" NPT', NULL),
  -- Local HMI
  (8,'0','None, with blind lid', NULL),
  (8,'1','Included, with blind lid', NULL),
  (8,'3','Included, with window lid', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C11','Manufacturer''s test certificate M to DIN 55350, Part 18 and to ISO 9000 - performance'),
  ('Y15','Stainless steel tag [69 x 50 mm], device parameters (max. 27 characters), plate, stainless steel 304/1.4301'),
  ('E24','Regional Ex approval: EAC Ex'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E26','Regional Ex approval: KCs (Korea)'),
  ('E27','Regional Ex approval: NEPSI (China)'),
  ('E28','Regional Ex approval: PESO (India)'),
  ('E29','Regional Ex approval: Japan'),
  ('E47','Regional Ex approval: ATEX (Europe) and IECEx (International)'),
  ('E48','Regional Ex approval: CSA (Canada) and FM (USA)'),
  ('E49','Regional Ex approval: ATEX (Europe), IECEx (International), CSA (Canada), and FM (USA)'),
  ('J01','Process connection special: non-return valve for purging air connection (available only with Purge connection option 1)')
)AS v(code, meaning)
WHERE base_code = '7ML755'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LR580 (7ML758)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ML758', 'SITRANS LR580', 'Radar Level Transmitter, Flanged Lens Antenna',
  'SITRANS LR580 80 GHz radar level transmitter, flanged lens antenna, for continuous non-contact level measurement of solids or liquids to a range of 120 m (394 ft). Part of the SITRANS LR500 series, PEEK lens with FKM/FFKM seal, 316/316L flange material, optional SLOD second line of defense, universal aiming flanges with up to 8° adjustment.',
  'LR580', 'Radar Level Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML758'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communications', false, false),
    (2,'Sealing material of the antenna/process connection', false, false),
    (3,'Process connection type and material', false, false),
    (4,'Second line of defense (SLOD) gas tight seal', false, false),
    (5,'Enclosure', true, false),
    (6,'Type of protection', false, false),
    (7,'Electrical connection', false, false),
    (8,'Local HMI', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Communications
  (1,'0','4 ... 20 mA, HART', NULL),
  -- Sealing material of the antenna/process connection
  (2,'0','PEEK / FKM / ‑40 ... +150 °C (-40 ... +302 °F)', NULL),
  (2,'1','PEEK / FKM / ‑40 ... +200 °C (-40 ... +392 °F)', NULL),
  (2,'2','PEEK / FFKM / ‑15 ... +250 °C (5 ... +482 °F)', NULL),
  -- Process connection type and material
  (3,'PC','Flange DN 80 PN 16, flat face, 316/316L', NULL),
  (3,'PD','Flange DN 100 PN 16, flat face, 316/316L', NULL),
  (3,'PE','Flange DN 150 PN 16, flat face, 316/316L', NULL),
  (3,'QC','Flange 3" 150lb, FF, 316/316L', NULL),
  (3,'QD','Flange 4" 150lb, FF, 316/316L', NULL),
  (3,'QE','Flange 6" 150lb, FF, 316/316L', NULL),
  (3,'RC','Flange DN 80 10K, FF, JIS / 316/316L', NULL),
  (3,'RD','Flange DN 100 10K, FF, JIS / 316/316L', NULL),
  (3,'RE','Flange DN 150 10K, FF, JIS / 316/316L', NULL),
  (3,'ED','Aiming flange, universal DN 100/4", 316/316L', NULL),
  (3,'EE','Aiming flange, universal DN 150/6", 316/316L', NULL),
  -- Second line of defense (SLOD) gas tight seal
  (4,'0','SLOD not included', NULL),
  (4,'1','SLOD included (internal fused glass seal)', NULL),
  -- Enclosure
  (5,'4','Single compartment enclosure', NULL),
  -- Type of protection
  (6,'A','Non Ex - General purpose', NULL),
  (6,'B','Intrinsically safe Ex ia / IS (Class I, II, III, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  (6,'C','Flameproof Ex d (Class I, Division 1)', NULL),
  (6,'D','Non-incendive (Class I, Division 2) (available only with -Z regional hazardous approval option E48)', NULL),
  (6,'M','Dust Ignition proof, Ex t / DIP (Class II, Division 1) (requires one -Z regional hazardous approval option)', NULL),
  -- Electrical connection
  (7,'F','M20', NULL),
  (7,'K','½" NPT', NULL),
  -- Local HMI
  (8,'0','None, with blind lid', NULL),
  (8,'1','Included, with blind lid', NULL),
  (8,'3','Included, with window lid', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C11','Manufacturer''s test certificate M to DIN 55350, Part 18 and to ISO 9000 - performance'),
  ('C12','Inspection certificate EN 10204-3.1, material'),
  ('C13','Inspection certificate EN 10204-3.1, material with NACE MR0175 and MR0103'),
  ('C14','Test report EN 10204-2.2, material'),
  ('C15','Test report EN 10204-3.1, PMI test - XRF (X-Ray Fluorescence)'),
  ('Y15','Stainless steel tag [69 x 50 mm], device parameters (max. 27 characters), plate, stainless steel 304/1.4301'),
  ('E24','Regional Ex approval: EAC Ex'),
  ('E25','Regional Ex approval: INMETRO, IA MASC'),
  ('E26','Regional Ex approval: KCs (Korea)'),
  ('E27','Regional Ex approval: NEPSI (China)'),
  ('E28','Regional Ex approval: PESO (India)'),
  ('E29','Regional Ex approval: Japan'),
  ('E47','Regional Ex approval: ATEX (Europe) and IECEx (International)'),
  ('E48','Regional Ex approval: CSA (Canada) and FM (USA)'),
  ('E49','Regional Ex approval: ATEX (Europe), IECEx (International), CSA (Canada), and FM (USA)'),
  ('J01','Process connection special: non-return valve for purging air connection')
)AS v(code, meaning)
WHERE base_code = '7ML758'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- ADDONS / ACCESSORIES (shared across the LR100 and LR500 series)
-- ============================================================
INSERT INTO siemens_addons (code, name, description) VALUES
  ('7ML1930-1BK','Hand Programmer, Intrinsically safe','LR500 series'),
  ('A5E52107153','Sun shield cover','LR500 series'),
  ('A5E51857118','AW050 BlueTooth module kit, M20','General purpose only, LR500 series'),
  ('A5E52095588','AW050 BlueTooth module kit, ½" NPT','General purpose only, LR500 series'),
  ('7MF7903-7AB','Lightning Arrestor, M20','LR500 series'),
  ('7MF7903-7AC','Lightning Arrestor, ½" NPT','LR500 series'),
  ('7MF79067BJ','Sealing plug, 316L/1.4404, Ex d, 1/2 NPT','LR500 series'),
  ('7MF79067AJ','Sealing plug, 316L/1.4404, Ex d, M20 x 1.5','LR500 series'),
  ('7MF4997-1DC','HART modem with USB interface',''),
  ('7NG4124-1AA00','Intrinsically Safe barrier',''),
  ('6NH3112-0BA00-0XX0','SIMATIC RTU3010C compact, remote data manager with alarming',''),
  ('6NH3112-3BA00-0XX0','SIMATIC RTU3030C compact, remote data manager with alarming',''),
  ('7ML5741-.....-.','SITRANS RD100, loop powered display',''),
  ('7ML5742-.....-....','SITRANS RD150, remote digital display for 4 to 20 mA and HART devices',''),
  ('7ML5740-.....-..','SITRANS RD200, universal input display with Modbus conversion',''),
  ('7ML5744-.....-..','SITRANS RD300, dual line display with totalizer, linearization curve and Modbus conversion',''),
  ('7ML60..-.....-....','SITRANS LT500, single/multi-vessel level monitor/controller',''),
  ('A5E53276254','¾" process seal for G thread types FKM, KLINGERSIL C-4400','LR510'),
  ('A5E53276255','1" process seal for G thread types FKM, KLINGERSIL C-4400','LR510'),
  ('A5E53276256','1-½" process seal for G thread types FKM, KLINGERSIL C-4400','LR510'),
  ('A5E53276263','Electronic module, LR510, LR530, <DN80 / 3 inch, mA/HART',''),
  ('A5E53276250','LR500 lid with window, Non-Exd/XP',''),
  ('A5E53308680','LR500 lid with window, Exd/XP',''),
  ('A5E53276252','LR500 lid without window, all versions',''),
  ('A5E53276247','HMI graphical display, with interconnection cable',''),
  ('A5E53276249','Electronic module, LR530, LR550, LR580, >DN 50 / 2 inch, mA/HART',''),
  ('A5E50868980','Polypropylene adapter flange, 2"/DN50, universal, 1.5" NPT',''),
  ('A5E50868982','Polypropylene adapter flange, 2"/DN50, universal, 1.5" BSPT',''),
  ('A5E50868988','Polypropylene adapter flange, 3"/DN80, universal, 1.5" NPT',''),
  ('A5E50868998','Polypropylene adapter flange, 3"/DN80, universal, 1.5" BSPT',''),
  ('A5E50869003','Polypropylene adapter flange, 4"/DN100, universal, 1.5" NPT',''),
  ('A5E50869005','Polypropylene adapter flange, 4"/DN100, universal, 1.5" BSPT',''),
  ('A5E53276258','Spring washers (x 40) kit for all process connection sizes','LR530'),
  ('A5E53308674','Spring washers x 4, M10 and 3/8", stainless steel','LR530'),
  ('A5E53308675','Spring washers x 4, ½", stainless steel','LR530'),
  ('A5E53308676','Spring washers x 4, M12, stainless steel','LR530'),
  ('A5E53308677','Spring washers x 8, M16 and 5/8", stainless steel','LR530'),
  ('A5E53308678','Spring washers x 12, M20 and ¾", stainless steel','LR530'),
  ('A5E53308679','Spring washers x 12, M24 and 7/8", stainless steel','LR530'),
  ('A5E52885008','Mounting bracket, 300 mm','LR550/LR580'),
  ('A5E52607563','EPDM Aiming Gasket DN 80','LR550/LR580'),
  ('A5E52607570','EPDM Aiming Gasket DN 100','LR550/LR580'),
  ('A5E52607582','EPDM Aiming Gasket 3"','LR550/LR580'),
  ('A5E52607584','EPDM Aiming Gasket 4"','LR550/LR580'),
  ('7ML1830-1AQ','Easy Aimer 2, aluminum, NPT with ¾" x 1" PVC coupling','LR100 series'),
  ('7ML1830-1AX','Easy Aimer 2, aluminum with M20 adapter and 1" and 1½" BSPT aluminum couplings','LR100 series'),
  ('7ML1830-1AU','Easy Aimer 304, NPT with 1" stainless steel coupling','LR100 series'),
  ('7ML1830-1GN','Easy Aimer 304, with M20 adapter and 1" and 1½" BSPT 304 stainless steel couplings','LR100 series'),
  ('A5E50507509','Bracket, 316L Stainless steel, 1 inch mount, 80 mm (3.1 inch) offset','LR100 series'),
  ('A5E50507511','Bracket, 316L Stainless steel, 1 inch mount, 200 mm (7.9 inch) offset','LR100 series'),
  ('A5E50507514','Bracket, 316L Stainless steel, 1.5 inch mount, 80 mm (3.1 inch) offset','LR100/LR140/LR150'),
  ('A5E50507516','Bracket, 316L Stainless steel, 1.5 inch mount, 200 mm (7.9 inch) offset','LR100/LR140/LR150'),
  ('7ML1830-1BK','FMS-200 universal box bracket, mounting kit','LR100 series'),
  ('7ML1830-1BL','FMS-210 channel bracket, wall mount','LR100 series'),
  ('7ML1830-1BM','FMS-220 extended channel bracket, wall mount','LR100 series'),
  ('7ML1830-1BN','FMS-310 channel bracket, floor mount','LR100 series'),
  ('7ML1830-1BP','FMS-320 extended channel bracket, floor mount','LR100 series'),
  ('7ML1830-1BQ','FMS-350 bridge channel bracket, floor mount','LR100 series'),
  ('7ML1830-1DS','1" NPT locknut, plastic','LR100 series'),
  ('7ML1830-1DR','1" BSP locknut, plastic','LR100 series'),
  ('7ML1830-1DP','1-½" BSP locknut, plastic','LR100/LR140/LR150'),
  ('7ML1830-1EA','Plastic adapter 1" BSP - 20 mm','LR100 series'),
  ('7ML1930-1FX','Plastic adapter 1" NPT','LR100 series'),
  ('7ML1830-1EF','Plastic adapter 1" NPT/M20','LR100 series'),
  ('A5E49069764','Submergence shield kit','LR120 - prevents build up on sensor during flooding conditions'),
  ('A5E50822955','SITRANS LR140/LR150 Blind lid with o-ring',''),
  ('A5E50822967','Flat gasket, FKM, for G1.5 inch sensor','LR140/LR150'),
  ('A5E50812988','SITRANS LR150 HMI with connection cable','LR150 only'),
  ('A5E50822960','SITRANS LR150 clear lid with o-ring','LR150 only')
ON CONFLICT (code) DO NOTHING;
