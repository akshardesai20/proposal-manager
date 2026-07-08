-- Seeds three more families from the FI 01 · 2025 catalog sheets provided:
-- SITRANS FMS300 (7ME636), SITRANS FMS500 (7ME653), and the SITRANS FMT020
-- transmitter (7ME6942, ordered separately for remote-mount systems — FM320
-- = FMS300 + FMT020, FM520 = FMS500 + FMT020).
--
-- Both sensors already offer an "integral transmitter" option on their own
-- order code (Transmitter variant 0/2, and Transmitter mounting & enclosure
-- type A/G/J), so FMT020 as a separate family only matters for remote-mount
-- jobs where it's costed as its own line.
--
-- Diameter position is flagged is_range = true on both sensors (short_label
-- = the DN size), so "Build from options" auto-fills the offer table's
-- Range column the way LU240 already does. MAG 3100 doesn't have this yet —
-- worth doing as a follow-up, not touched here.
--
-- KNOWN LIMITATIONS / things to verify before quoting off these:
--   1. FMT020's article number template in the catalog PDF
--      (7ME6942-0AA00-0●●●) has several literal digits between the base
--      code and the three selectable categories (mounting, terminal box,
--      power supply) that aren't explained by any table in the source
--      document. Only the three confirmed selectable positions are seeded
--      below, in the order the "Selection and ordering data" table lists
--      them. Cross-check against the PIA Life Cycle Portal configurator or
--      a real FMT020 order code before trusting decoded output verbatim.
--   2. Suffix (order code) lists below are a representative subset per
--      family, matching the depth migration 002 seeded for LU240/MAG3100 —
--      covering certificates, calibration classes, drinking water/custody
--      transfer approvals, communication, and common device options. The
--      full DN-and-flange-dependent tables (grounding rings, calibration
--      broken out by DN band, verification tolerance tables) run to
--      hundreds of rows and aren't modeled; those stay as manual costing
--      lines for now.
--   3. FMS500's Electrode material position has only one catalog value
--      (Hastelloy C276), so it's marked is_fix = true, same convention
--      used for LU240's single-value positions.

-- ============================================================
-- FAMILY: SITRANS FMS300 (7ME636)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ME636', 'SITRANS FMS300', 'Electromagnetic Flow Sensor',
  'SITRANS FMS300 electromagnetic flow sensor for chemical, process, steel, mining, pulp & paper, and oil/gas applications. DN 15 to DN 2200 (1/2" to 88"), wide range of liner and electrode materials, fully welded construction. Combines with SITRANS FMT020 transmitter as SITRANS FM320.',
  'FMS300', 'Electromagnetic Flow Sensor')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ME636'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Transmitter variant', false, false),
    (2,'Diameter', false, true),
    (3,'Process connection', false, false),
    (4,'Process connection material', false, false),
    (5,'Liner material', false, false),
    (6,'Electrode material', false, false),
    (7,'Transmitter mounting & enclosure type', false, false),
    (8,'Power supply', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Transmitter variant
  (1,'0','No transmitter (sensor only)', NULL),
  (1,'2','Transmitter SITRANS FMT020 (integral mount)', NULL),
  -- Diameter (2-char: size digit + letter)
  (2,'1V','DN 15, 1/2 inch', 'DN15'),
  (2,'2D','DN 25, 1 inch', 'DN25'),
  (2,'2H','DN 32, 1 1/4 inch', 'DN32'),
  (2,'2R','DN 40, 1 1/2 inch', 'DN40'),
  (2,'2Y','DN 50, 2 inch', 'DN50'),
  (2,'3F','DN 65, 2 1/2 inch', 'DN65'),
  (2,'3M','DN 80, 3 inch', 'DN80'),
  (2,'3T','DN 100, 4 inch', 'DN100'),
  (2,'4B','DN 125, 5 inch', 'DN125'),
  (2,'4H','DN 150, 6 inch', 'DN150'),
  (2,'4P','DN 200, 8 inch', 'DN200'),
  (2,'4V','DN 250, 10 inch', 'DN250'),
  (2,'5B','DN 300, 12 inch', 'DN300'),
  (2,'5D','DN 350, 14 inch', 'DN350'),
  (2,'5H','DN 400, 16 inch', 'DN400'),
  (2,'5K','DN 450, 18 inch', 'DN450'),
  (2,'5R','DN 500, 20 inch', 'DN500'),
  (2,'5Y','DN 600, 24 inch', 'DN600'),
  (2,'6B','DN 700, 28 inch', 'DN700'),
  (2,'6D','DN 750, 30 inch', 'DN750'),
  (2,'6H','DN 800, 32 inch', 'DN800'),
  (2,'6K','DN 900, 36 inch', 'DN900'),
  (2,'6R','DN 1000, 40 inch', 'DN1000'),
  (2,'6Y','DN 1050, 42 inch', 'DN1050'),
  (2,'7D','DN 1100, 44 inch', 'DN1100'),
  (2,'7H','DN 1200, 48 inch', 'DN1200'),
  (2,'7M','DN 1400, 54 inch', 'DN1400'),
  (2,'7R','DN 1500, 60 inch', 'DN1500'),
  (2,'7V','DN 1600, 66 inch', 'DN1600'),
  (2,'7Y','DN 1800, 72 inch', 'DN1800'),
  (2,'8B','DN 2000, 80 inch', 'DN2000'),
  (2,'8F','DN 2200, 88 inch', 'DN2200'),
  -- Process connection
  (3,'A','EN 1092-1 PN 6 flanges', NULL),
  (3,'B','EN 1092-1 PN 10 flanges', NULL),
  (3,'C','EN 1092-1 PN 16 flanges, standard face-to-face (1.25xDN, PED compliant)', NULL),
  (3,'D','EN 1092-1 PN 16 flanges, short face-to-face (1.0xDN, not PED compliant)', NULL),
  (3,'E','EN 1092-1 PN 25 flanges', NULL),
  (3,'F','EN 1092-1 PN 40 flanges', NULL),
  (3,'G','EN 1092-1 PN 63 flanges', NULL),
  (3,'H','EN 1092-1 PN 100 flanges', NULL),
  (3,'J','ANSI B16.5 Class 150 flanges', NULL),
  (3,'K','ANSI B16.5 Class 300 flanges', NULL),
  (3,'L','ANSI B16.5 Class 600 flanges', NULL),
  (3,'M','AWWA C-207 Class D flanges', NULL),
  (3,'Q','AS 2129 table E flanges', NULL),
  (3,'S','AS 4087 PN 16 flanges', NULL),
  (3,'T','AS 4087 PN 21 flanges', NULL),
  (3,'U','AS 4087 PN 35 flanges', NULL),
  (3,'W','JIS B 2220:2004 10K flanges', NULL),
  (3,'Y','JIS B 2220:2004 20K flanges', NULL),
  -- Process connection material
  (4,'0','Carbon steel ASTM A 105, corrosion-resistant coating C4', NULL),
  (4,'1','Carbon steel ASTM A 105, corrosion-resistant coating C5', NULL),
  (4,'3','Stainless steel AISI 304 flange, corrosion-resistant coating C4', NULL),
  (4,'4','Stainless steel AISI 304 flange, corrosion-resistant coating C5', NULL),
  (4,'8','Stainless steel AISI 316L flange (incl. sensor housing), polished', NULL),
  -- Liner material
  (5,'1','Soft rubber (Neoprene)', NULL),
  (5,'2','EPDM', NULL),
  (5,'3','PTFE', NULL),
  (5,'4','Ebonite', NULL),
  (5,'5','Linatex', NULL),
  (5,'7','PFA', NULL),
  -- Electrode material
  (6,'0','Stainless steel AISI 316Ti / 1.4571', NULL),
  (6,'1','Hastelloy C276 / 2.4819 (PFA liner: Hastelloy C22 / 2.4602)', NULL),
  (6,'2','Platinum', NULL),
  (6,'3','Titanium', NULL),
  (6,'4','Tantalum', NULL),
  (6,'5','Ceramic coated stainless steel AISI 316Ti / 1.4571', NULL),
  (6,'6','Ceramic coated Hastelloy C276 / 2.4819', NULL),
  -- Transmitter mounting & enclosure type
  (7,'A','No transmitter (sensor only)', NULL),
  (7,'G','Compact design (integral mount), polycarbonate enclosure', NULL),
  (7,'J','Remote design, polycarbonate enclosure (wall-mounting unit + sensor terminal board included)', NULL),
  -- Power supply
  (8,'0','No transmitter (sensor only)', NULL),
  (8,'2','12...42 V DC', NULL),
  (8,'3','100...240 V AC, 50/60 Hz', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable glands: without (blind plugs)'),
  ('A02','Cable glands: M20x1.5, polyamide'),
  ('A05','Cable glands: 1/2" NPT, polyamide'),
  ('C00','Declaration of compliance with the order 2.1 (EN 10204)'),
  ('C12','Inspection certificate 3.1 (EN 10204) - Material of pressure-containing/wetted parts'),
  ('C14','Test report 2.2 (EN 10204)'),
  ('C18','Inspection certificate 3.1 (EN 10204) - Pressure test'),
  ('D01','High accuracy calibration +/- 0.2% of act. vol. flow, DN <= 200, <= 8 inch'),
  ('D02','High accuracy calibration +/- 0.2% of act. vol. flow, DN 250...600, 10...24 inch'),
  ('D03','High accuracy calibration +/- 0.2% of act. vol. flow, DN 700...1200, 28...48 inch'),
  ('D04','High accuracy calibration +/- 0.2% of act. vol. flow, DN >= 1400, >= 54 inch'),
  ('E06','CSA General Purpose'),
  ('E80','Drinking water approval: WRAS (WRc, BS 6920, GB)'),
  ('E81','Drinking water approval: NSF/ANSI 61 (Cold water, US)'),
  ('E82','Drinking water approval: ACS (France)'),
  ('E83','Drinking water approval: Compliance to Trinkwasserverordnung §14 (Germany)'),
  ('E84','Drinking water approval: Belgaqua (Belgium)'),
  ('E85','Drinking water approval: AS/NZS 4020 (Australia/New Zealand)'),
  ('E86','Drinking water approval: GB/T 5750 (China)'),
  ('E89','General purpose / without drinking water approval'),
  ('E90','Country of origin: France'),
  ('F01','HART with 4...20 mA output, active or passive'),
  ('F04','Modbus RTU / RS485'),
  ('F05','PROFIBUS PA'),
  ('F06','PROFIBUS DP'),
  ('F07','PROFINET'),
  ('F09','EtherNet/IP'),
  ('F10','MODBUS TCP/IP'),
  ('F30','I/O extension: digital input or output, passive'),
  ('G00','Custody transfer: without approval'),
  ('G01','Custody transfer: MI-001 cold water meter'),
  ('G05','Custody transfer: OIML R49 - Class 2 accuracy'),
  ('G06','Custody transfer: OIML R49 - Class 1 accuracy'),
  ('J00','Sensor terminal board factory mounted'),
  ('J01','Sensor cables factory mounted'),
  ('J02','Factory preconfigured for transmitter mounting in compact design (integral mount)'),
  ('J03','Display with protection cover'),
  ('J04','Breathing vent M20 thread, IP67'),
  ('J05','Breathing vent 1/2" NPT thread, IP67'),
  ('J06','Industrial Micro-SD memory card, 20 GB storage capacity'),
  ('J30','High temperature version (PTFE; PFA: 150C)'),
  ('J31','High temperature version (PTFE: 180C incl. type E protection rings AISI 316/1.4436)'),
  ('J32','Quick shipment (<= DN 300; PTFE; PFA; 10 days excluding shipment)'),
  ('L50','IP68 (NEMA 6P), sensor + transmitter, without potting (to 2 m depth, 10 days)'),
  ('L51','IP68 (NEMA 6P), sensor in remote design, factory potted (to 10 m depth, continuously)')
) AS v(code, meaning)
WHERE base_code = '7ME636'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS FMS500 (7ME653)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ME653', 'SITRANS FMS500', 'Electromagnetic Flow Sensor (Water)',
  'SITRANS FMS500 electromagnetic flow sensor for water abstraction, water treatment, distribution networks (leak detection), irrigation, and wastewater. NBR or EPDM rubber lining, integrated grounding electrodes, DN 15 to DN 2000 (1/2" to 80"). Combines with SITRANS FMT020 transmitter as SITRANS FM520.',
  'FMS500', 'Electromagnetic Flow Sensor')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ME653'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Transmitter variant', false, false),
    (2,'Diameter', false, true),
    (3,'Process connection', false, false),
    (4,'Process connection material', false, false),
    (5,'Liner material', false, false),
    (6,'Electrode material', true, false),
    (7,'Transmitter mounting & enclosure type', false, false),
    (8,'Power supply', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  -- Transmitter variant
  (1,'0','No transmitter (sensor only)', NULL),
  (1,'2','Transmitter SITRANS FMT020 (integral mount)', NULL),
  -- Diameter (2-char: size digit + letter)
  (2,'1V','DN 15, 1/2 inch', 'DN15'),
  (2,'2D','DN 25, 1 inch', 'DN25'),
  (2,'2R','DN 40, 1 1/2 inch', 'DN40'),
  (2,'2Y','DN 50, 2 inch', 'DN50'),
  (2,'3F','DN 65, 2 1/2 inch', 'DN65'),
  (2,'3M','DN 80, 3 inch', 'DN80'),
  (2,'3T','DN 100, 4 inch', 'DN100'),
  (2,'4B','DN 125, 5 inch', 'DN125'),
  (2,'4H','DN 150, 6 inch', 'DN150'),
  (2,'4P','DN 200, 8 inch', 'DN200'),
  (2,'4V','DN 250, 10 inch', 'DN250'),
  (2,'5B','DN 300, 12 inch', 'DN300'),
  (2,'5D','DN 350, 14 inch', 'DN350'),
  (2,'5H','DN 400, 16 inch', 'DN400'),
  (2,'5K','DN 450, 18 inch', 'DN450'),
  (2,'5R','DN 500, 20 inch', 'DN500'),
  (2,'5Y','DN 600, 24 inch', 'DN600'),
  (2,'6B','DN 700, 28 inch', 'DN700'),
  (2,'6D','DN 750, 30 inch', 'DN750'),
  (2,'6H','DN 800, 32 inch', 'DN800'),
  (2,'6K','DN 900, 36 inch', 'DN900'),
  (2,'6R','DN 1000, 40 inch', 'DN1000'),
  (2,'6Y','DN 1050, 42 inch', 'DN1050'),
  (2,'7D','DN 1100, 44 inch', 'DN1100'),
  (2,'7H','DN 1200, 48 inch', 'DN1200'),
  (2,'7M','DN 1400, 54 inch', 'DN1400'),
  (2,'7R','DN 1500, 60 inch', 'DN1500'),
  (2,'7V','DN 1600, 64 inch', 'DN1600'),
  (2,'7Y','DN 1800, 72 inch', 'DN1800'),
  (2,'8B','DN 2000, 80 inch', 'DN2000'),
  -- Process connection
  (3,'A','EN 1092-1 PN 6 flanges', NULL),
  (3,'B','EN 1092-1 PN 10 flanges', NULL),
  (3,'C','EN 1092-1 PN 16 flanges (PED compliant)', NULL),
  (3,'D','EN 1092-1 PN 16 flanges, non-PED type (excluded from scope of PED 2014/68/EU)', NULL),
  (3,'F','EN 1092-1 PN 40 flanges', NULL),
  (3,'J','ANSI B16.5 Class 150 flanges', NULL),
  (3,'M','AWWA C-207 Class D flanges', NULL),
  (3,'S','AS 4087 PN 16 flanges', NULL),
  (3,'W','JIS B 2220:2004 10K flanges', NULL),
  -- Process connection material
  (4,'0','Carbon steel ASTM A 105, corrosion-resistant coating C4', NULL),
  (4,'1','Carbon steel ASTM A 105, corrosion-resistant coating C5 (300um)', NULL),
  -- Liner material
  (5,'2','EPDM', NULL),
  (5,'3','NBR', NULL),
  -- Electrode material (single catalog value)
  (6,'1','Hastelloy C276 / 2.4819', NULL),
  -- Transmitter mounting & enclosure type
  (7,'A','No transmitter (sensor only)', NULL),
  (7,'G','Compact design (integral mount), polycarbonate enclosure', NULL),
  (7,'J','Remote design, polycarbonate enclosure (wall-mounting unit + sensor terminal board included)', NULL),
  -- Power supply
  (8,'0','None (sensor only)', NULL),
  (8,'2','12...42 V DC', NULL),
  (8,'3','100...240 V AC, 50/60 Hz', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable glands: without (blind plugs)'),
  ('A02','Cable glands: M20x1.5, polyamide'),
  ('A03','Cable glands: M20x1.5, Ex, polyamide'),
  ('A05','Cable glands: 1/2" NPT, polyamide'),
  ('A06','Cable glands: 1/2" NPT, Ex, polyamide'),
  ('C00','Declaration of compliance with the order 2.1 (EN 10204)'),
  ('C12','Inspection certificate 3.1 (EN 10204) - Material of pressure-containing/wetted parts'),
  ('C14','Test report 2.2 (EN 10204)'),
  ('C18','Inspection certificate 3.1 (EN 10204) - Pressure test'),
  ('D01','High accuracy calibration +/- 0.2% of act. vol. flow, DN <= 200, <= 8 inch'),
  ('D02','High accuracy calibration +/- 0.2% of act. vol. flow, DN 250...600, 10...24 inch'),
  ('D03','High accuracy calibration +/- 0.2% of act. vol. flow, DN 700...1200, 28...48 inch'),
  ('D04','High accuracy calibration +/- 0.2% of act. vol. flow, DN >= 1400, >= 54 inch'),
  ('E06','CSA General Purpose'),
  ('E20','Explosion protection: ATEX (Europe) & IECEx (World)'),
  ('E22','Explosion protection: FM (USA & Canada)'),
  ('E23','Explosion protection: IECEx (World)'),
  ('E75','Country specific approval: CPA (China)'),
  ('E80','Drinking water approval: WRAS (WRc, BS 6920, GB)'),
  ('E81','Drinking water approval: NSF/ANSI 61 (Cold water, US)'),
  ('E82','Drinking water approval: ACS (France)'),
  ('E83','Drinking water approval: Compliance to Trinkwasserverordnung §14 (Germany)'),
  ('E84','Drinking water approval: Belgaqua (Belgium)'),
  ('E85','Drinking water approval: AS/NZS 4020 (Australia/New Zealand)'),
  ('E86','Drinking water approval: GB/T 5750 (China)'),
  ('E89','General purpose / without drinking water approval'),
  ('E90','Country of origin: France'),
  ('F01','HART with 4...20 mA output, active or passive'),
  ('F04','Modbus RTU / RS485'),
  ('F05','PROFIBUS PA'),
  ('F06','PROFIBUS DP'),
  ('F07','PROFINET'),
  ('F09','EtherNet/IP'),
  ('F10','MODBUS TCP/IP'),
  ('F30','I/O extension: digital input / output, passive'),
  ('G00','Custody transfer: without approval'),
  ('G01','Custody transfer: MI-001 cold water meter'),
  ('G05','Custody transfer: OIML R49 - Class 2 accuracy'),
  ('G06','Custody transfer: OIML R49 - Class 1 accuracy'),
  ('J00','Sensor terminal board factory mounted'),
  ('J01','Sensor cables factory mounted'),
  ('J02','Factory preconfigured for transmitter mounting in compact design (integral mount)'),
  ('J03','Display with protection cover'),
  ('J04','Breathing vent M20 thread, IP67'),
  ('J05','Breathing vent 1/2" NPT thread, IP67'),
  ('J06','Industrial Micro-SD memory card, 20 GB storage capacity'),
  ('J20','Nameplate in Chinese language'),
  ('L12','Type of Ex protection: Increased safety (Ex e) Zone 2'),
  ('L15','Type of Ex protection: Non-incendive (NI) Class I, Division 2'),
  ('L50','IP68 (NEMA 6P), sensor + transmitter, without potting (to 2 m depth, 10 days)'),
  ('L51','IP68 (NEMA 6P), sensor in remote design, factory potted (to 10 m depth, continuously)')
) AS v(code, meaning)
WHERE base_code = '7ME653'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS FMT020 transmitter (7ME6942)
-- Ordered separately for remote-mount systems. See "KNOWN LIMITATIONS"
-- note at top of file re: unconfirmed fixed digits in the article number.
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ME6942', 'SITRANS FMT020', 'Magnetic Flowmeter Transmitter',
  'SITRANS FMT020 magnetic flowmeter transmitter, successor to MAG 5000/6000. Simultaneously measures volumetric flow, flow velocity, and electrical conductivity. Combines with SITRANS FMS500 sensor (or FMS300) for a complete flowmeter system. Integral or remote mount; HART, PROFINET, PROFIBUS DP/PA, EtherNet/IP, MODBUS RTU/TCP.',
  'FMT020', 'Flow Transmitter')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ME6942'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Transmitter mounting and enclosure type', false, false),
    (2,'Terminal box, electrical connection', false, false),
    (3,'Power supply', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, v.short_label FROM pos JOIN (VALUES
  (1,'A','Polycarbonate enclosure, compact design', NULL),
  (1,'B','Remote design, polycarbonate housing (wall-mounting unit + sensor terminal board included)', NULL),
  (2,'A','Without terminal box', NULL),
  (2,'B','Polycarbonate terminal box with M20 threads (incl. 4 pcs M20 cable glands)', NULL),
  (2,'C','Polycarbonate terminal box with M20 threads + 1/2" NPT adaptors (incl. 4 pcs 1/2" NPT cable glands)', NULL),
  (3,'2','12...42 V DC', NULL),
  (3,'3','100...240 V AC, 50/60 Hz', NULL)
) AS v(position_no, character, meaning, short_label) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('E06','CSA General Purpose'),
  ('E20','Explosion protection: ATEX (Europe) & IECEx (World)'),
  ('E22','Explosion protection: FM (USA & Canada)'),
  ('E23','Explosion protection: IECEx (World)'),
  ('E75','Country specific approval: CPA (China)'),
  ('F01','HART with 4...20 mA output, active or passive'),
  ('F04','Modbus RTU / RS485'),
  ('F05','PROFIBUS PA'),
  ('F06','PROFIBUS DP'),
  ('F07','PROFINET'),
  ('F09','EtherNet/IP'),
  ('F10','MODBUS TCP/IP'),
  ('F30','I/O extension: digital input / output, passive'),
  ('J06','Industrial micro SD memory card, 20 GB storage capacity'),
  ('J20','Name plate in Chinese language'),
  ('L12','Type of Ex protection: Increased safety (Ex e) Zone 2'),
  ('L15','Type of Ex protection: Non-incendive (NI) Class I, Division 2')
) AS v(code, meaning)
WHERE base_code = '7ME6942'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- ADDONS / ACCESSORIES — representative subset (see note at top of file
-- re: DN/flange-dependent grounding-ring and cable-length tables being
-- out of scope for this table).
-- ============================================================
INSERT INTO siemens_addons (code, name, description) VALUES
  ('7ME6940-1CM10','FMT020 comm. add-on: HART with 4...20 mA output','Active or passive'),
  ('7ME6940-1CM20','FMT020 comm. add-on: PROFINET',''),
  ('7ME6940-1CM30','FMT020 comm. add-on: EtherNet/IP',''),
  ('7ME6940-1CM40','FMT020 comm. add-on: Modbus RTU/RS485',''),
  ('7ME6940-1CM50','FMT020 comm. add-on: PROFIBUS DP',''),
  ('7ME6940-1CM60','FMT020 comm. add-on: PROFIBUS PA',''),
  ('7ME6940-1CM70','FMT020 comm. add-on: MODBUS TCP/IP',''),
  ('7ME6940-1DM10','FMT020 I/O add-on module','Digital input/output, passive'),
  ('7ME6940-1BT10','SITRANS AW050 Bluetooth adapter','Including connection cable'),
  ('7ME6940-1SP10','SensorPROM programmer','MAG 5000/6000 SensorPROM compatible'),
  ('7ME6940-1WU10','FMT020 wall-mounting unit, M20x1.5 cable glands (4 pcs)','Includes sensor terminal board'),
  ('7ME6940-1WU15','FMT020 wall-mounting unit, 1/2" NPT cable glands (4 pcs)','Includes sensor terminal board'),
  ('7ME6940-1PL10','FMT020 display protection cover',''),
  ('A5E01209496','FMT020 sun shield, remote mount',''),
  ('A5E01209500','FMT020 sun shield, integral mount (compact design)','Only for FMS500 sensors DN 150...1200 (6"...48")'),
  ('7ME6940-1BV10','FMT020 breathing vent, M20, IP67',''),
  ('7ME6940-1BV15','FMT020 breathing vent, 1/2" NPT, IP67',''),
  ('A5E53821516','FMT020 industrial microSD memory card','20 GB storage capacity'),
  ('7ME6940-1CB10','FMT020 spare: transmitter connection board with power supply, AC','100...240 V AC, 50/60 Hz'),
  ('7ME6940-1CB20','FMT020 spare: transmitter connection board with power supply, DC','12...42 V DC'),
  ('7ME6940-1DU10','FMT020 spare: local display and operating unit','Incl. ribbon cable and display holder'),
  ('7ME6940-1SM10','FMT020 Sensorprom memory unit, programmed','Sensor order code + serial number required when ordering'),
  ('T00','FMS300/FMS500 sensor cable kit, standard type, 5 m',''),
  ('T01','FMS300/FMS500 sensor cable kit, standard type, 10 m',''),
  ('T03','FMS300/FMS500 sensor cable kit, standard type, 20 m',''),
  ('FDK:083N8345','Grounding and protection ring - Type C, DN 65, stainless steel','Representative size; for all liners except PTFE/PFA — check DN/flange table before quoting other sizes')
ON CONFLICT (code) DO NOTHING;
