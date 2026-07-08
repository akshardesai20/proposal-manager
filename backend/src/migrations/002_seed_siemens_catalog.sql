-- Seeds the Siemens decode catalog with three families from the FI 01
-- catalog sheets provided: SITRANS Probe LU240, SITRANS FM MAG 3100 /
-- MAG 3100 HT, and SITRANS LT500.
--
-- KNOWN LIMITATION (see handoff notes): MAG 3100's "Diameter" position uses
-- a two-character code (e.g. '1V' = DN15) and its Electrode option '9'
-- (ceramic coated) needs a further 3-character suffix ('N0A' etc). Both are
-- stored here as multi-character `character` values, which the schema
-- supports fine — but the decode engine's character-matching logic needs a
-- variable-length-match upgrade (try longest option first) before it can
-- read a real MAG 3100 code correctly. Single-character families (LU240,
-- LT500) are unaffected.

-- ============================================================
-- FAMILY: SITRANS Probe LU240 (7ML511)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description)
VALUES ('7ML511', 'SITRANS Probe LU240', 'Ultrasonic Level Transmitter',
  'SITRANS Probe LU240 ultrasonic level transmitter, non-contact, continuous level/volume/volume flow measurement up to 12 m (40 ft), for liquids, slurries, and bulk materials.')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML511'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix)
  SELECT fam.id, v.position_no, v.name, v.is_fix FROM fam,
  (VALUES
    (1,'Communications', false),
    (2,'Ingress protection', true),
    (3,'Measurement range/wetted parts', false),
    (4,'Process connection', false),
    (5,'Non-wetted parts', true),
    (6,'Type of protection', false),
    (7,'Electrical connections/cable entries', false),
    (8,'Local HMI', false)
  ) AS v(position_no, name, is_fix)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning)
SELECT pos.id, v.character, v.meaning FROM pos JOIN (VALUES
  (1,'0','HART (4...20 mA) level, volume, volume flow'),
  (1,'7','4...20 mA level only'),
  (2,'1','IP66, IP68, Type 4X, 6'),
  (3,'B','200...3000 mm (7.87...118.11 in), PVDF Copolymer'),
  (3,'C','200...3000 mm (7.87...118.11 in), ETFE'),
  (3,'D','200...6000 mm (7.87...236.22 in), PVDF Copolymer'),
  (3,'E','200...6000 mm (7.87...236.22 in), ETFE'),
  (3,'G','200...12000 mm (7.87...472.44 in), PVDF Copolymer'),
  (3,'H','200...12000 mm (7.87...472.44 in), ETFE'),
  (4,'D','2" NPT (Taper), ASME B1.20.1'),
  (4,'E','R 2" (BSPT), EN 10226'),
  (4,'F','G 2" (BSPP), EN ISO 228-1'),
  (5,'7','Plastic (PBT/PC material)'),
  (6,'A','Ordinary Locations/General Purpose (Non-Ex), cCSAus, CE, KC, RCM, EAC'),
  (6,'B','Ordinary Locations/General Purpose (Non-Ex), cCSAus, FM, CE, KC, RCM, EAC'),
  (6,'C','Ex i (ia) (Ex-Zone 0/Div. 1)/IS, FM NI (Class I, Div. 2)'),
  (7,'F','2 x M20 x 1.5 (general purpose Polyamide cable gland + blocking plug)'),
  (7,'K','1 x 1/2" NPT (no gland cable provided)'),
  (8,'0','Without display (blind lid of PBT/PC material)'),
  (8,'1','With display (blind lid of PBT/PC material)'),
  (8,'3','With display (clear lid of PC material)')
) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Stainless steel tag [13 x 45 mm]: measuring-point number/identification, plain text, max 32 characters'),
  ('C19','Declaration of compliance DIN 55350-18, Type M / ISO 9001 delivery meets order requirements'),
  ('C14','Certificate EN 10204-2.2'),
  ('F50','Bluetooth wireless communication'),
  ('E31','ATEX II 1 G Ex ia IIC T4 Ga / IECEx Ex ia IIC T4 Ga / EAC Ex 0Ex ia IIC T4 Ga X / SABS Ex ia IIC T4 Ga, Ta -40...+80C'),
  ('E32','FM (Non-incendive) Class I, Div. 2, Groups A,B,C,D, T5/T6'),
  ('E33','IECEx Ex ia IIC T4 Ga / KCs Ex ia IIC T4 / NEPSI Ex ia IIC T4 Ga, Ta -40...+80C'),
  ('E34','CSA Class I Div.2 / CSA Zone 0 AEx ia IIC T4 Ga / IECEx Ex ia IIC T4 Ga / INMETRO / KCs, Ta -40...+80C'),
  ('E61','VLAREM II (available with approval option A, B, or E31 only)')
) AS v(code, meaning)
WHERE base_code = '7ML511'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS FM MAG 3100 (7ME6310)
-- Diameter uses 2-char codes; Electrode '9' needs a 3-char suffix — see
-- note at top of file.
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description)
VALUES ('7ME6310', 'SITRANS FM MAG 3100', 'Electromagnetic Flow Sensor',
  'SITRANS FM MAG 3100 electromagnetic flow sensor, DN 15 to DN 2200 (1/2" to 88"), wide range of electrode and liner materials, fully welded construction.')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ME6310'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix)
  SELECT fam.id, v.position_no, v.name, v.is_fix FROM fam,
  (VALUES
    (1,'Diameter', false),
    (2,'Flange norm and pressure rating', false),
    (3,'Flange material', false),
    (4,'Liner material', false),
    (5,'Electrode material', false),
    (6,'Transmitter', false),
    (7,'Communication', false),
    (8,'Cable glands/terminal box', false)
  ) AS v(position_no, name, is_fix)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning)
SELECT pos.id, v.character, v.meaning FROM pos JOIN (VALUES
  -- Diameter (2-char: size digit + letter)
  (1,'1V','DN 15, 1/2 inch (PTFE and PFA liner)'),
  (1,'2D','DN 25, 1 inch'),
  (1,'2H','DN 32, 1 1/4 inch'),
  (1,'2R','DN 40, 1 1/2 inch'),
  (1,'2Y','DN 50, 2 inch'),
  (1,'3F','DN 65, 2 1/2 inch'),
  (1,'3M','DN 80, 3 inch'),
  (1,'3T','DN 100, 4 inch'),
  (1,'4B','DN 125, 5 inch'),
  (1,'4H','DN 150, 6 inch'),
  (1,'4P','DN 200, 8 inch'),
  (1,'4V','DN 250, 10 inch'),
  (1,'5D','DN 300, 12 inch'),
  (1,'5K','DN 350, 14 inch'),
  (1,'5R','DN 400, 16 inch'),
  (1,'5Y','DN 450, 18 inch'),
  (1,'6F','DN 500, 20 inch'),
  (1,'6P','DN 600, 24 inch'),
  (1,'6Y','DN 700, 28 inch'),
  (1,'7D','DN 750, 30 inch'),
  (1,'7H','DN 800, 32 inch'),
  (1,'7M','DN 900, 36 inch'),
  (1,'7R','DN 1000, 40 inch'),
  (1,'7U','DN 1050, 42 inch'),
  (1,'7V','DN 1100, 44 inch'),
  (1,'8B','DN 1200, 48 inch'),
  (1,'8F','DN 1400, 54 inch'),
  (1,'8K','DN 1500, 60 inch'),
  (1,'8P','DN 1600, 66 inch'),
  (1,'8T','DN 1800, 72 inch'),
  (1,'8Y','DN 2000, 80 inch'),
  (1,'8V','DN 2200, 88 inch'),
  -- Flange norm and pressure rating
  (2,'A','EN 1092-1 PN 6 flanges'),
  (2,'B','EN 1092-1 PN 10 flanges'),
  (2,'C','EN 1092-1 PN 16 flanges, standard face-to-face (1.25xDN, PED compliant)'),
  (2,'D','EN 1092-1 PN 16 flanges, short face-to-face (1.0xDN, not PED compliant)'),
  (2,'E','EN 1092-1 PN 25 flanges'),
  (2,'F','EN 1092-1 PN 40 flanges'),
  (2,'G','EN 1092-1 PN 63 flanges'),
  (2,'H','EN 1092-1 PN 100 flanges'),
  (2,'J','ANSI B16.5 Class 150 flanges'),
  (2,'K','ANSI B16.5 Class 300 flanges'),
  (2,'U','ANSI B16.5 Class 600 flanges'),
  (2,'L','AWWA C-207 Class D flanges'),
  (2,'M','AS 2129 table E flanges'),
  (2,'N','AS 4087 PN 16 flanges'),
  (2,'P','AS 4087 PN 21 flanges'),
  (2,'Q','AS 4087 PN 35 flanges'),
  (2,'R','JIS B 2220:2004 10K flanges'),
  (2,'S','JIS B 2220:2004 20K flanges'),
  -- Flange material
  (3,'1','Carbon steel flanges ASTM A 105, corrosion-resistant coating C4'),
  (3,'2','Stainless steel flanges, AISI 304/1.4301, corrosion-resistant coating C4'),
  (3,'3','Stainless steel flanges and sensor body, AISI 316L/1.4404, polished'),
  (3,'4','Carbon steel ASTM A 105, EN ISO 12944 grade C5 coating (300 um)'),
  (3,'5','Stainless steel flanges, AISI 304/1.4301, EN ISO 12944 grade C5 coating (300 um)'),
  -- Liner material
  (4,'1','Soft rubber'),
  (4,'2','EPDM'),
  (4,'3','PTFE'),
  (4,'4','Ebonite'),
  (4,'5','Linatex'),
  (4,'7','PFA'),
  -- Electrode material (standard)
  (5,'1','AISI 316Ti/1.4571 (not for PFA)'),
  (5,'2','Hastelloy C276/2.4819 (PFA liner: Hastelloy C22/2.4602)'),
  (5,'3','Platinum (DN <= 300 (12")) (not for Ebonite)'),
  (5,'4','Titanium (not for PFA)'),
  (5,'5','Tantalum (not for Ebonite)'),
  (5,'6','Hastelloy C incl. grounding electrodes (only PFA and PTFE)'),
  (5,'7','Platinum incl. grounding electrodes (only PFA and PTFE)'),
  (5,'8','Tantalum incl. grounding electrodes (only PFA and PTFE)'),
  -- Electrode material 9 = ceramic, requires 3-char suffix (see note at top)
  (5,'9N0A','Ceramic coated stainless steel'),
  (5,'9N0B','Ceramic coated Hastelloy C'),
  (5,'9N0C','AISI 316Ti incl. grounding electrodes (only PTFE)'),
  (5,'9N0D','Titanium incl. grounding electrodes (only PTFE)'),
  -- Transmitter
  (6,'A','Standard sensor for remote transmitter (order transmitter separately)'),
  (6,'B','Ex sensor for remote transmitter (order transmitter separately)'),
  (6,'C','MAG 6000 I, Aluminum 18...90 V DC, 115...230 V AC, FM/CSA Class I Div.2'),
  (6,'D','MAG 6000 I, Aluminum 18...30 V DC, Ex'),
  (6,'E','MAG 6000 I, Aluminum 115...230 V, Ex'),
  (6,'F','MAG 6000 I, Aluminum 18...90 V DC, 115...230 V AC (non-Ex)'),
  (6,'H','MAG 6000 Polyamide, 11...30 V DC / 11...24 V AC'),
  (6,'J','MAG 6000, Polyamide, 115...230 V AC'),
  (6,'K','MAG 5000, Polyamide, 11...30 V DC / 11...24 V AC'),
  (6,'L','MAG 5000, Polyamide, 115...230 V AC'),
  -- Communication
  (7,'A','No communication, add-on possible'),
  (7,'B','HART / Blocked for any TRN except MAG 6000I (consider ordering FM320)'),
  (7,'F','PROFIBUS PA Profile 3'),
  (7,'G','PROFIBUS DP Profile 3 (not for Ex)'),
  (7,'E','Modbus RTU/RS 485 (not for Ex)'),
  (7,'J','FOUNDATION Fieldbus H1'),
  -- Cable glands/terminal box
  (8,'1','Metric: Polyamide terminal box or MAG 6000 I compact'),
  (8,'2','1/2" NPT: Polyamide terminal box or MAG 6000 I compact'),
  (8,'3','Metric: Stainless steel terminal box'),
  (8,'4','1/2" NPT: Stainless steel terminal box')
) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C01','Pressure test certificate according to EN 10204-3.1'),
  ('C12','Material certificate according to EN 10204-3.1'),
  ('C14','Factory certificate according to EN 10204-2.2'),
  ('C15','Factory certificate according to EN 10204-2.1'),
  ('D01','5-point calibration for DN 15...200'),
  ('D02','5-point calibration for DN 250...600'),
  ('D03','5-point calibration for DN 700...1200'),
  ('N02','Factory mounted terminal blocks'),
  ('H25','CRN (Canadian Registration Number)'),
  ('Y16','Tag name, stainless steel plate for transmitter (plain text)'),
  ('Y17','Tag name, stainless steel plate (plain text)'),
  ('Y18','Tag name, adhesive label (plain text)'),
  ('Y20','Customer-specific transmitter setting'),
  ('Y40','Factory mounted sensor cables'),
  ('Y41','Factory mounted and potted sensor cables, IP68 protection class')
) AS v(code, meaning)
WHERE base_code = '7ME6310'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS FM MAG 3100 HT (High Temperature) (7ME6320)
-- Smaller size/material range than standard 3100; same position structure.
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description)
VALUES ('7ME6320', 'SITRANS FM MAG 3100 HT', 'Electromagnetic Flow Sensor (High Temperature)',
  'SITRANS FM MAG 3100 HT electromagnetic flow sensor, DN 15 to DN 300, high temperature sensor for applications up to 180C (356F).')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ME6320'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix)
  SELECT fam.id, v.position_no, v.name, v.is_fix FROM fam,
  (VALUES
    (1,'Diameter', false),
    (2,'Flange norm and pressure rating', false),
    (3,'Flange material', false),
    (4,'Liner material', false),
    (5,'Electrode material', false),
    (6,'Transmitter', false),
    (7,'Communication', false),
    (8,'Cable glands/terminal box', false)
  ) AS v(position_no, name, is_fix)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning)
SELECT pos.id, v.character, v.meaning FROM pos JOIN (VALUES
  (1,'1V','DN 15, 1/2 inch'),
  (1,'2D','DN 25, 1 inch'),
  (1,'2R','DN 40, 1 1/2 inch'),
  (1,'2Y','DN 50, 2 inch'),
  (1,'3F','DN 65, 2 1/2 inch'),
  (1,'3M','DN 80, 3 inch'),
  (1,'3T','DN 100, 4 inch'),
  (1,'4B','DN 125, 5 inch'),
  (1,'4H','DN 150, 6 inch'),
  (1,'4P','DN 200, 8 inch'),
  (1,'4V','DN 250, 10 inch'),
  (1,'5D','DN 300, 12 inch'),
  (2,'B','EN 1092-1 PN 10 flanges'),
  (2,'C','EN 1092-1 PN 16 flanges'),
  (2,'E','EN 1092-1 PN 25 flanges'),
  (2,'F','EN 1092-1 PN 40 flanges'),
  (2,'J','ANSI B16.5 Class 150 flanges'),
  (2,'K','ANSI B16.5 Class 300 flanges'),
  (2,'M','AS 2129 table E flanges'),
  (3,'1','Carbon steel flanges ASTM A 105, corrosion-resistant coating C4'),
  (3,'2','Stainless steel flanges, AISI 304/1.4301, corrosion-resistant coating C4'),
  (3,'3','Stainless steel flanges and sensor body, AISI 316L/1.4404, polished'),
  (4,'2','PTFE max 150C (302F)'),
  (4,'3','PTFE incl. type E protection rings AISI 316/1.4436, max 150C (302F)'),
  (4,'7','PFA max 150C (302F)'),
  (5,'1','AISI 316Ti/1.4571 (not for PFA)'),
  (5,'2','Hastelloy C276/2.4819 (PFA liner: Hastelloy C22/2.4602)'),
  (5,'3','Platinum'),
  (5,'4','Titanium (not for PFA)'),
  (5,'5','Tantalum'),
  (5,'6','Hastelloy C22/2.4602 incl. grounding electrodes (PFA only)'),
  (5,'7','Platinum incl. grounding electrodes (PFA only)'),
  (5,'8','Tantalum incl. grounding electrodes (PFA only)'),
  (6,'A','Standard sensor for remote transmitter (order transmitter separately)'),
  (6,'B','Ex sensor for remote transmitter (order transmitter separately)'),
  (6,'C','MAG 6000 I, Aluminum 18...90 V DC, 115...230 V AC, FM/CSA Class I Div.2'),
  (6,'D','MAG 6000 I, Aluminum 18...30 V DC, Ex'),
  (6,'E','MAG 6000 I, Aluminum 115...230 V AC, Ex'),
  (6,'F','MAG 6000 I, Aluminum 18...90 V DC, 115...230 V AC (non-Ex)'),
  (6,'H','MAG 6000, Polyamide, 11...30 V DC/11...24 V AC'),
  (6,'J','MAG 6000, Polyamide, 115...230 V AC'),
  (6,'K','MAG 5000, Polyamide, 11...30 V DC/11...24 V AC'),
  (6,'L','MAG 5000, Polyamide, 115...230 V AC'),
  (7,'A','No communication, add-on possible'),
  (7,'B','HART / Blocked for any TRN except MAG 6000I (consider ordering FM320)'),
  (7,'F','PROFIBUS PA Profile 3'),
  (7,'G','PROFIBUS DP Profile 3'),
  (7,'E','Modbus RTU/RS 485'),
  (7,'J','FOUNDATION Fieldbus H1'),
  (8,'1','Metric: Polyamide terminal box (max 150C) or MAG 6000 I compact'),
  (8,'2','1/2" NPT: Polyamide terminal box (max 150C) or MAG 6000 I compact'),
  (8,'3','Metric: Stainless steel terminal box'),
  (8,'4','1/2" NPT: Stainless steel terminal box')
) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS LT500 (7ML60) - covers both mA HART and Ultrasonic
-- versions; they differ only at position 3 (Sensor input type).
-- Positions 8-9 ('A','A') are fixed/reserved per the catalog's article
-- number pattern - no corresponding selectable category was listed.
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description)
VALUES ('7ML60', 'SITRANS LT500', 'Level Controller (HydroRanger/MultiRanger)',
  'SITRANS LT500 is a versatile single and multi-vessel level monitor/controller. mA HART version works with SITRANS LR110, LR120, Probe LU240, or any 4-20mA/HART level device. Ultrasonic version connects EchoMax or legacy transducers directly.')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ML60'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix)
  SELECT fam.id, v.position_no, v.name, v.is_fix FROM fam,
  (VALUES
    (1,'Product brand', false),
    (2,'Feature set', false),
    (3,'Sensor input type', false),
    (4,'Number of measurement points', false),
    (5,'Relay output', false),
    (6,'Mounting, enclosure design', false),
    (7,'Type of protection', false),
    (8,'Removable data storage', true),
    (9,'Reserved', true),
    (10,'Reserved', true),
    (11,'Input voltage', false)
  ) AS v(position_no, name, is_fix)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning)
SELECT pos.id, v.character, v.meaning FROM pos JOIN (VALUES
  (1,'2','SITRANS LT500'),
  (1,'0','SITRANS LT500 HydroRanger'),
  (1,'1','SITRANS LT500 MultiRanger'),
  (2,'3','Level, Volume, and Flow (MCERTS class 2 certified)'),
  (2,'4','Level, Volume, and Flow, high accuracy (MCERTS class 1 certified)'),
  (3,'0','4...20 mA input(s) for radar sensors (mA HART version)'),
  (3,'1','Ultrasonic transducer input(s) (Ultrasonic version)'),
  (4,'A','Single point version'),
  (4,'B','Dual point version'),
  (5,'A','1 relay (1 Form A), 250 V AC'),
  (5,'B','3 relays (2 Form A, 1 Form C), 250 V AC'),
  (5,'C','6 relays (4 Form A, 2 Form C), 250 V AC'),
  (6,'0','Wall mount, standard enclosure'),
  (6,'1','Wall mount, 4 entries, M20 cable glands included'),
  (6,'2','Panel mount'),
  (6,'3','Remote panel mount'),
  (7,'0','Ordinary Locations/General Purpose (Non-Ex)'),
  (7,'1','Ex rated'),
  (8,'1','Included, 8 GB micro SD'),
  (9,'A','Reserved (fixed)'),
  (10,'A','Reserved (fixed)'),
  (11,'2','12...30 V DC'),
  (11,'3','100...230 V AC')
) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('Y15','Stainless steel tag [13x45mm]: device parameter, plain text, max 32 chars'),
  ('E21','CSA Class I Div.2 Groups A,B,C,D / Class II Div.2 Groups F&G / Class III/Zone 2 GP IIC T3'),
  ('C11','Quality inspection certificate - calibration IEC 62828-4'),
  ('C19','Declaration of compliance DIN 55350-18, Type M / ISO 9001'),
  ('C14','Factory certificate 2.2 (EN 10204)'),
  ('D91','RFID/NFC tag according IEC 61406-1'),
  ('F01','HART with 4...20 mA active output'),
  ('F04','Modbus RTU'),
  ('F13','Modbus TCP'),
  ('F05','PROFIBUS PA'),
  ('F06','PROFIBUS DP'),
  ('F07','PROFINET'),
  ('F09','EtherNet/IP'),
  ('F50','Bluetooth wireless communication'),
  ('J20','Suitable for high temperatures +60C (140F)'),
  ('Y99','Special design (contact local sales person)')
) AS v(code, meaning)
WHERE base_code = '7ML60'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- ADDONS / ACCESSORIES (global, not tied to a single family)
-- Representative subset from each catalog's accessories tables.
-- ============================================================
INSERT INTO siemens_addons (code, name, description) VALUES
  ('7ML1930-1AC','Stainless steel tag','12 x 45 mm, one text line (max 16 characters) - LU240'),
  ('7ML1830-1BK','FMS200 universal box bracket mounting kit','LU240 mounting accessory'),
  ('7ML1830-1BT','3" ASME/DIN mounting adapter, 2" NPT, ETFE','LU240 mounting accessory'),
  ('7ML1830-1BU','3" ASME/DIN mounting adapter, 2" BSP, ETFE','LU240 mounting accessory'),
  ('A5E52107153','Stainless steel sun shield','LU240 accessory'),
  ('7ML5741-.....-.','SITRANS RD100, loop powered display','Compatible with LU240, MAG 3100, LT500'),
  ('7ML5742-.....-....','SITRANS RD150, remote digital display for 4-20mA and HART devices',''),
  ('7ML5740-.....-..','SITRANS RD200, universal input display with Modbus conversion',''),
  ('7ML5744-.....-..','SITRANS RD300, dual line display with totalizer and linearization curve',''),
  ('FDK-085U0220','Potting kit for IP68/NEMA 6P sealing of sensor junction box','MAG 3100 accessory'),
  ('A5E50255823','Barriers in a NEMA 4X/IP65 enclosure','LT500 accessory'),
  ('A5E50113513','Barrier suitable for LR1xx & LU240 (STAHL 9001/01-280-110-101)','LT500 accessory'),
  ('7ML1930-1GA','Sunshield/pipe mount plate, 304 Stainless steel','LT500 accessory'),
  ('7ML1930-1GD','USB cable, 2 m, standard USB-B to USB-mini B','LT500 accessory'),
  ('A5E50113558','Replacement motherboard, single point, includes DC power module','LT500 spare part')
ON CONFLICT (code) DO NOTHING;
