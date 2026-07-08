-- Seeds SITRANS FSS100 (ultrasonic retrofit flowmeter kit) and
-- SIPART PS2 (electropneumatic positioner) plus its NCS remote position
-- sensor, from the FI 01 . April 2026 catalog.
--
-- KNOWN LIMITATIONS:
--   1. FSS100 accessories/spare-parts tables (transducer spare parts by
--      temperature/material/approval combo, transducer holders and
--      mounting plates by DN range, cable glands) are extensive --
--      representative subset seeded as addons, not exhaustive.
--   2. SIPART PS2 (6DR5) is genuinely ONE order-code family that covers
--      both the standard and flameproof enclosure variants -- they share
--      the same base code and article-number template, just picking
--      different combinations of Enclosure/Type-of-protection/Connection
--      thread/Gauge-block characters. Enclosure values are a clean union
--      (0/2/3 = standard, 5/6 = flameproof, no overlap). Type of
--      protection mostly unions cleanly too (F/G/K/N are byte-for-byte
--      identical text in both source tables) EXCEPT character 'E', which
--      the catalog reuses for two different meanings depending on which
--      Enclosure was picked (Intrinsic safety for enclosure 0/2/3 vs.
--      Flameproof+dust-ignition for enclosure 5/6). That option's
--      `meaning` text below spells out both cases explicitly -- always
--      cross-check against the Enclosure selection before quoting.
--   3. Gauge block / venting gauge block / booster options are modeled as
--      multi-character compound values (e.g. '9R1A'), matching how the
--      catalog's own article-number template reserves 4 trailing
--      character slots for them. The decode engine already tries
--      longest-match-first per position, so this works the same way
--      MAG 3100's compound electrode codes do.
--   4. "Other accessories" for SIPART PS2 (control units, plug panels,
--      mounting kits for specific third-party actuator brands, spare
--      pneumatic parts) are numerous standalone spare-part article
--      numbers, not order-code suffixes -- seeded as a representative
--      addons subset.

-- ============================================================
-- FAMILY: SITRANS FSS100 (7ME3810)
-- ============================================================

INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7ME3810', 'SITRANS FSS100 (SONOKIT)', 'Ultrasonic Retrofit Flowmeter Kit',
  'SITRANS FSS100 is a transit-time ultrasonic flowmeter retrofit kit (SONOKIT) for installation on existing pipelines, DN 100-3000 (4-120 inch), 1- to 4-path. Requires a separately-ordered transmitter (SITRANS FST030 for 1-4 path/Ex/industrial, or FST020 for 1-path water applications).',
  'FSS100', 'Ultrasonic Flowmeter Retrofit Kit')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7ME3810'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Installation method', false, false),
    (2,'Transducer holder', false, false),
    (3,'Sensor cable', false, false),
    (4,'Transducer type and approval', false, false),
    (5,'Number of tracks', false, false),
    (6,'Ex approvals', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'1','Empty pipe DN < 200 (8 inch), incl. transducer holder and mounting plates'),
  (1,'2','Empty pipe DN >= 200 (8 inch), incl. transducer holder and mounting plates'),
  (1,'4','Empty pipe concrete DN >= 600 (24 inch), incl. transducer holder and mounting plates'),
  (2,'B','Transducer carbon steel, mounting plates in carbon steel'),
  (2,'C','Transducer stainless steel, mounting plates in stainless steel'),
  (3,'B','Standard cable, 3 m, for FST030 or FST020'),
  (3,'C','Standard cable, 15 m, for FST030 or FST020'),
  (3,'D','Standard cable, 30 m, only for FST020'),
  (3,'E','Standard cable, 60 m, only for FST020'),
  (3,'F','Standard cable, 90 m, only for FST020'),
  (3,'J','High-temp cable, 3 m, for FST030 or FST020'),
  (3,'K','High-temp cable, 15 m, for FST030 or FST020'),
  (3,'L','High-temp cable, 30 m, for FST020'),
  (4,'1','IP68 (NEMA 4X/6) PA polyamide housing, PN 40, O-ring, 100 C (212 F)'),
  (4,'4','IP68 SS stainless steel housing, PN 40, O-ring, 190 C (374 F), Ex d type, ATEX (only with FST030 Ex version)'),
  (4,'5','IP68 SS stainless steel housing, PN 40, O-ring, 190 C (374 F), Ex i type, ATEX (only with FST030 Ex version)'),
  (5,'1','1 track (path) with FST030, FST030+FS DSL, or FST020'),
  (5,'2','2 tracks (path) with FST030, FST030+FS DSL, or FST020'),
  (5,'3','3 tracks (path), requires FST030 and FS DSL'),
  (5,'4','4 tracks (path), requires FST030 and FS DSL'),
  (6,'A','Non Ex'),
  (6,'C','ATEX zone 1'),
  (6,'F','IECEx zone 1'),
  (6,'N','NEPSI'),
  (6,'P','INMETRO'),
  (6,'Q','KCs')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C12','Material certificate acc. to EN 10204 3.1'),
  ('C15','Factory certificate acc. to EN 10204 2.1'),
  ('S10','Alignment rods-set for DN 100...750 (4-30 inch), dia 25mm, L=500mm, 3 pcs'),
  ('S11','Alignment rods-set for DN 800...2100 (32-84 inch), dia 25mm, L=500mm, 6 pcs'),
  ('S12','Alignment rods-set for DN 2200...3000 (88-120 inch), dia 25mm, L=500mm, 8 pcs'),
  ('S13','Alignment rods-set for DN 100...750 (4-30 inch), dia 25mm, L=500mm, 3 pcs (alt.)'),
  ('T11','Spanner key for transducer mounting FSS100 O-ring type'),
  ('T12','Toolbox set with various mounting/spare parts for FSS100'),
  ('Y17','Stainless steel TAG plate (1x24x80mm), wire fixed; font 8mm (1-10 chars) or 4mm (11-20 chars), specify in plain text')
) AS v(code, meaning)
WHERE base_code = '7ME3810'
ON CONFLICT (family_id, code) DO NOTHING;


INSERT INTO siemens_addons (code, name, description) VALUES
  ('A5E02904544','FSS100 couplant grease','High temperature, PFPE/PTFE based'),
  ('FDK:085B5333','FSS100 O-ring transducer extraction tool, up to 160mm length',''),
  ('FDK:085B5335','FSS100 O-ring transducer extraction tool, up to 230mm length',''),
  ('FDK:085B5330','FSS100 angle measurement tool',''),
  ('FDK:085B5392','FSS100 hot-tap drilling tool (extraction tool required, max 40 bar)',''),
  ('FDK:085B5393','FSS100 alignment tool (typically for hot-tapping), DN 300-1200',''),
  ('A5E02609214','FSS100 alignment rods-set, DN 100-650 (4-26 inch), 3 pcs',''),
  ('A5E02609215','FSS100 alignment rods-set, DN 700-1900 (28-76 inch), 6 pcs',''),
  ('A5E02609216','FSS100 alignment rods-set, DN 2000-3000 (80-120 inch), 10 pcs',''),
  ('A5E02609218','FSS100 spanner key for transducer mounting',''),
  ('A5E02609219','FSS100 tool set, various mounting/spare parts',''),
  ('A5E00839476','FSS100 complete O-ring transducer, PA6.6 housing, PN40, 160mm, 1/2in-NPT glands',''),
  ('A5E00839435','FSS100 complete O-ring transducer, 316SS housing, PN40, 160mm, 1/2in-NPT glands, -20..+200C',''),
  ('FDK:085B5452','FSS100 complete O-ring transducer, 316SS housing, PN40, 160mm, M20 glands, Ex d',''),
  ('A5E00836462','FSS100 complete O-ring transducer, 316SS housing, PN40, 160mm, M20 glands, Ex i',''),
  ('A5E00839460','FSS100 transducer terminal housing, PA6.6, -20..+100C, 1/2in-NPT glands',''),
  ('A5E00839427','FSS100 transducer terminal housing, AISI316, -20..+200C, 1/2in-NPT glands',''),
  ('FDK:085B1089','FSS100 transducer gasket, O-ring x3, FKM, PN40',''),
  ('FDK:085L1103','FSS100 transducer holder, 1-path/3-path center mount, 160mm SS 45deg, DN100-150',''),
  ('FDK:085L1109','FSS100 transducer holder, 2/3/4-path non-central mount, 160mm SS 60deg, DN200-3000',''),
  ('FDK:085L1113','FSS100 mounting plate, 1-path/3-path center mount, SS 45deg, DN100-150',''),
  ('FDK:085L1119','FSS100 mounting plate, 2/3/4-path non-central mount, SS 60deg, DN200-3000',''),
  ('A5E02246304','FSS100 cable gland, black PA plastic, cable dia 5-13mm',''),
  ('A5E02246309','FSS100 cable gland, 1/2in NPT grey PA plastic, cable dia 5-9mm',''),
  ('A5E02246194','FSS100 cable gland, M20 stainless steel, Ex i, cable dia 4-6mm',''),
  ('A5E02246311','FSS100 cable gland, M20 stainless steel, Ex d, cable dia 5-8mm','')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- FAMILY: SIPART PS2 electropneumatic positioner (6DR5)
-- Merged standard-enclosure and flameproof-enclosure variants -- see
-- KNOWN LIMITATIONS #2/#3 at top of file for the 'E' character caveat
-- and the compound gauge-block values.
-- ============================================================

INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('6DR5', 'SIPART PS2 electropneumatic positioner', 'Electropneumatic Positioner',
  'SIPART PS2 digital electropneumatic positioner for pneumatic linear and part-turn actuators. HART/PROFIBUS PA/FOUNDATION Fieldbus. Covers both standard (polycarbonate/stainless/aluminum) and flameproof (Ex d, aluminum/316L) enclosure variants under the same order-code family.',
  'SIPART PS2', 'Electropneumatic Positioner')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '6DR5'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Version (electronics)', false, false),
    (2,'Actuator', false, false),
    (3,'Enclosure', false, false),
    (4,'Type of protection (Ex)', false, false),
    (5,'Connection thread electric/pneumatic', false, false),
    (6,'Limit monitor', false, false),
    (7,'Option modules', false, false),
    (8,'Brief instructions', false, false),
    (9,'Version (fail-safe behavior)', false, false),
    (10,'Gauge block', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','4...20 mA'),
  (1,'1','4...20 mA, HART'),
  (1,'5','PROFIBUS PA'),
  (1,'6','FOUNDATION Fieldbus'),
  (1,'9','Without electronics (for 19-inch remote variant)'),
  (2,'1','Single-acting'),
  (2,'2','Double-acting'),
  (3,'0','Polycarbonate, glass-fiber reinforced (standard enclosure)'),
  (3,'2','Stainless steel, without inspection window, 1.4581 (standard enclosure)'),
  (3,'3','Aluminum, AlSi12 (standard enclosure)'),
  (3,'5','Aluminum, flameproof, AlSi12'),
  (3,'6','Stainless steel, 316L, flameproof, 1.4409'),
  (4,'N','Without explosion protection'),
  (4,'D','Increased safety (Ex e), dust ignition protection by enclosure (Ex t) -- standard enclosure only'),
  (4,'E','DEPENDS ON ENCLOSURE (position 3): for Enclosure 0/2/3 (standard) = Intrinsic safety (Ex i), SITRANS I200 output isolation amplifier sold separately (7NG4131-1AA00). For Enclosure 5/6 (flameproof) = Flameproof enclosure (Ex d), dust ignition protection by enclosure (Ex t). Verify against the Enclosure selection before quoting.'),
  (4,'F','Intrinsic safety (Ex i), increased safety (Ex e); SITRANS I200 output isolation amplifier sold separately (7NG4131-1AA00)'),
  (4,'G','Increased safety (Ex e)'),
  (4,'K','Intrinsic safety (Ex i), increased safety (Ex e), dust ignition protection by enclosure (Ex t); SITRANS I200 output isolation amplifier sold separately (7NG4131-1AA00)'),
  (4,'P','Flameproof enclosure (Ex d), intrinsic safety (Ex i), dust ignition protection by enclosure (Ex t); SITRANS I200 output isolation amplifier sold separately (7NG4131-1AA00) -- flameproof enclosure only'),
  (5,'G','M20x1.5 / G1/4'),
  (5,'N','1/2-14 NPT / 1/4-18 NPT'),
  (5,'M','M20x1.5 / 1/4-18 NPT'),
  (5,'P','1/2-14 NPT / G1/4'),
  (5,'R','M12 device plug (A coding) for electronics / G1/4; cable socket ordered separately with 6DR4004-5A -- standard enclosure only'),
  (5,'S','M12 device plug (A coding) for electronics / 1/4-18 NPT; cable socket ordered separately with 6DR4004-5A -- standard enclosure only'),
  (5,'Q','M25x1.5 / G1/4 -- flameproof enclosure only'),
  (6,'0','None (incl. 2nd cable gland)'),
  (6,'1','Digital I/O Module (DIO), 1 digital input, 3 digital outputs (2 limits min/max, 1 fault indicator); device plug M12 orderable with -Z D55'),
  (6,'2','Inductive Limit Switches (ILS), 2 inductive limit switches + 1 digital output (DO); device plug M12 orderable with -Z D56'),
  (6,'3','Mechanic Limit Switches (MLS), 2 mechanical limit switches + 1 digital output (DO); not for natural gas; device plug M12 orderable with -Z D57'),
  (6,'9L1A','Internal NCS module for non-contacting position detection; potentiometer detection not applied but orderable with -Z K11; only for 6DR55.. and 6DR56..'),
  (7,'0','None (incl. 2nd cable gland)'),
  (7,'1','Analog Output Module (AOM), analog position feedback 4...20 mA; device plug M12 orderable with -Z D53; SITRANS I100 isolating power supply sold separately'),
  (7,'2','Analog Input Module (AIM) for external position detection (NCS sensor, position transmitter 6DR4004-1ES/2ES/3ES/4ES, or others); internal position detection orderable with -Z K11/K12; device plug M12 orderable with -Z D54; SITRANS I100 sold separately'),
  (7,'3','AOM + AIM combined; internal position detection orderable with -Z K11/K12; device plug M12 not available'),
  (8,'A','English/German/Chinese'),
  (8,'B','French/Italian/Spanish'),
  (9,'A','Standard / Fail Safe: depressurizing the actuator on failure of electrical auxiliary power'),
  (9,'F','Fail in Place: maintain position on failure of electrical and/or pneumatic auxiliary power'),
  (9,'G','Fail to Open: pressurizing the actuator on failure of electrical auxiliary power'),
  (10,'0','Gauge block: none'),
  (10,'1','Gauge block: plastic gauges IP31 (MPa,bar), aluminum block, single-acting, G1/4'),
  (10,'2','Gauge block: plastic gauges IP31 (MPa,bar), aluminum block, double-acting, G1/4'),
  (10,'3','Gauge block: plastic gauges IP31 (MPa/psi), aluminum block, single-acting, 1/4-18 NPT'),
  (10,'4','Gauge block: plastic gauges IP31 (MPa/psi), aluminum block, double-acting, 1/4-18 NPT'),
  (10,'9R1A','Gauge block: metal gauges IP44 (MPa,bar,psi), aluminum block, single-acting, G1/4'),
  (10,'9R2A','Gauge block: metal gauges IP44 (MPa,bar,psi), aluminum block, double-acting, G1/4'),
  (10,'9R1B','Gauge block: metal gauges IP44 (MPa,bar,psi), aluminum block, single-acting, 1/4-18 NPT'),
  (10,'9R2B','Gauge block: metal gauges IP44 (MPa,bar,psi), aluminum block, double-acting, 1/4-18 NPT'),
  (10,'9R1C','Gauge block: stainless steel gauges IP54 (MPa,bar,psi), 316 stainless block, single-acting, G1/4'),
  (10,'9R2C','Gauge block: stainless steel gauges IP54 (MPa,bar,psi), 316 stainless block, double-acting, G1/4'),
  (10,'9R1D','Gauge block: stainless steel gauges IP54 (MPa,bar,psi), 316 stainless block, single-acting, 1/4-18 NPT'),
  (10,'9R2D','Gauge block: stainless steel gauges IP54 (MPa,bar,psi), 316 stainless block, double-acting, 1/4-18 NPT'),
  (10,'9R2E','Venting gauge block: aluminum, double-acting, G1/4 -- standard enclosure only'),
  (10,'9R2F','Venting gauge block: aluminum, double-acting, 1/4-18 NPT -- standard enclosure only'),
  (10,'9R1J','Booster (Cv=2): aluminum, metal gauges IP44, single-acting, G1/2 -- standard (non-flameproof) enclosure only'),
  (10,'9R2J','Booster (Cv=2): aluminum, metal gauges IP44, double-acting, G1/2 -- standard (non-flameproof) enclosure only'),
  (10,'9R1K','Booster (Cv=2): aluminum, metal gauges IP44, single-acting, 1/2-14 NPT -- standard (non-flameproof) enclosure only'),
  (10,'9R2K','Booster (Cv=2): aluminum, metal gauges IP44, double-acting, 1/2-14 NPT -- standard (non-flameproof) enclosure only'),
  (10,'9R1P','Booster (Cv=2): aluminum, metal gauges IP44, single-acting, G1/2 -- flameproof enclosure only'),
  (10,'9R2P','Booster (Cv=2): aluminum, metal gauges IP44, double-acting, G1/2 -- flameproof enclosure only'),
  (10,'9R1Q','Booster (Cv=2): aluminum, metal gauges IP44, single-acting, 1/2-14 NPT -- flameproof enclosure only'),
  (10,'9R2Q','Booster (Cv=2): aluminum, metal gauges IP44, double-acting, 1/2-14 NPT -- flameproof enclosure only')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A30','SIEMENS Positioner Lifecycle Support Platform (WeChat applet, China only)'),
  ('A40','Stainless steel sound absorber (standard with stainless steel enclosures)'),
  ('C20','Functional safety (SIL 2), single-acting positioner only; suitable per IEC 61508/61511'),
  ('D53','M12 device plug (D coding), connected with Analog Output Module (AOM); cable socket ordered separately with 6DR4004-5D'),
  ('D54','M12 device plug (D coding), connected with Analog Input Module (AIM)'),
  ('D55','M12 device plug (D coding), connected with Digital I/O Module (DIO)'),
  ('D56','M12 device plug (D coding), connected with Inductive Limit Switches (ILS)'),
  ('D57','M12 device plug (D coding), connected with Mechanic Limit Switches (MLS)'),
  ('F50','SITRANS AW050 Bluetooth adapter for wireless communication and data transfer'),
  ('K10','Optimized control behavior for small actuators (< 200 cm3)'),
  ('K11','Additional internal position detection by means of a potentiometer'),
  ('K12','Additional, device-internal position detection via a magnetic sensor (NCS)'),
  ('K18','Pneumatic terminal strip made of stainless steel 316'),
  ('K20','Interface acc. to VDI/VDE 3847, single/double-acting, CATS only for single-acting; not for flameproof enclosure'),
  ('K50','Operation with natural gas; corrosion-protected painted electronics, FVMQ elastomers'),
  ('K55','Pneumatic block seal from FVMQ (higher oil resistance)'),
  ('M40','Permissible ambient temperature -40...80C (-40...+176F); lid without inspection window for 6DR5..1./2./3.'),
  ('P01','Pressure sensor supported monitoring: device/custom min/max supply pressure PZ, hold position on demand, NAMUR NE107'),
  ('P02','Pressure sensor supported monitoring: as P01 plus Valve Signature, Partial Stroke Test, leakage/actuating pressure monitoring, pressure limitation for single-acting actuators'),
  ('C35','EN 10204 certificate type 2.1'),
  ('S10','DNV (Det Norske Veritas) marine certificate'),
  ('S11','LR (Lloyds Register) marine certificate'),
  ('S12','BV (Bureau Veritas) marine certificate'),
  ('S14','ABS (American Bureau of Shipping) marine certificate'),
  ('S15','KR (Korean Register of Shipping) marine certificate'),
  ('S16','CCS (China Classification Society) marine certificate'),
  ('S17','RINA (Registro Italiano Navale) marine certificate'),
  ('A20','TAG plate made of stainless steel, 3-line; text from Y17/Y15/Y16'),
  ('Y15','Measuring point description; max 16 chars HART, max 32 chars PROFIBUS PA/FF/4-20mA, plain text'),
  ('Y16','Measuring point text; max 32 characters, plain text'),
  ('Y17','Measuring point number (TAG no.); max 32 characters, plain text'),
  ('Y25','Preset bus address; plain text, 6DR55../6DR56.. only'),
  ('Y30','Customer-specific parameter setting; plain text'),
  ('Y99','Special design / Product Variant Request (PVR); order number from PVR clarification, plain text')
) AS v(code, meaning)
WHERE base_code = '6DR5'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: NCS sensor for SIPART PS2 remote variant (6DR4004)
-- Contact-free position detection sensor, ordered separately from the
-- positioner electronics for 19-inch remote-mount SIPART PS2 systems.
-- ============================================================

INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('6DR4004', 'NCS sensor for SIPART PS2 remote variant', 'Position Sensor (Remote, Contact-free)',
  'NCS sensor for contact-free position detection, used with SIPART PS2 electronics without built-in electronics (Version=9) in 19-inch remote-mount installations. Not for Ex d version.',
  'NCS Sensor', 'Position Sensor')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '6DR4004'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Explosion protection', false, false),
    (2,'Cable length', false, false),
    (3,'Actuator type', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES
  (1,'8','Non-explosion-proof'),
  (1,'6','Intrinsic safety / non-sparking'),
  (2,'N','6 m (19.68 ft)'),
  (2,'P','20 m (65.67 ft)'),
  (2,'R','40 m (131.23 ft)'),
  (3,'2','Linear actuator, stroke <= 14 mm (0.55 inch); actuator-specific mounting not included, add-on kit 6DR4004-8V usable on NAMUR actuators'),
  (3,'3','Linear actuator, stroke 14...130 mm (0.55...5.12 inch); add-on kit 6DR4004-8V (2-35mm) or long lever 6DR4004-8L (35-120mm) for NAMUR actuators'),
  (3,'4','Part-turn actuator, magnet holder anodized aluminum; NAMUR mount not included, order separately with 6DR4004-1D/-2D/-3D/-4D')
) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;

-- ============================================================
-- ADDONS: SIPART PS2 accessories, position transmitters, control units,
-- modules and mounting kits -- representative subset (see KNOWN
-- LIMITATIONS #4 at top of file).
-- ============================================================

INSERT INTO siemens_addons (code, name, description) VALUES
  ('6DR4004-1ES','Position transmitter (potentiometer)','Aluminum enclosure with potentiometer, no electronics/pneumatic block, for separate mounting on actuator'),
  ('6DR4004-2ES','Position transmitter (NCS)','Aluminum enclosure, non-contacting position detection, no electronics/pneumatic block'),
  ('6DR4004-3ES','Position transmitter (NCS, ILS)','Aluminum enclosure, NCS + inductive limit switches, no electronics/pneumatic block'),
  ('6DR4004-4ES','Position transmitter (NCS, MLS)','Aluminum enclosure, NCS + mechanic limit switches, no electronics/pneumatic block'),
  ('A5E00151560','Control unit for 3x SIPART PS2 4-20mA','19-inch control unit, 3x electronics, 2-wire, for remote installation of 6DR59* electronics'),
  ('A5E00250501','Control unit for 5x SIPART PS2 PA','19-inch control unit incl. 5x PROFIBUS PA module; order 1x plug panel separately'),
  ('A5E00250502','Control unit for 10x SIPART PS2 PA','19-inch control unit incl. 10x PROFIBUS PA module; order 2x plug panels separately'),
  ('A5E00250503','Control unit for 15x SIPART PS2 PA','19-inch control unit incl. 15x PROFIBUS PA module; order 3x plug panels separately'),
  ('A5E00252845','Plug panel for control unit (50)','Burndy 50 plug connection panel, connects max 5 units of SIPART PS2 w/o electronics'),
  ('A5E00252830','Plug panel for control unit (50+8)','As above plus Burndy 8 plug to link communication between control units'),
  ('6DR4004-6F','Analog Input Module (AIM), with explosion protection',''),
  ('6DR4004-8F','Analog Input Module (AIM), without explosion protection',''),
  ('6DR4004-6A','Digital I/O Module (DIO), with explosion protection',''),
  ('6DR4004-8A','Digital I/O Module (DIO), without explosion protection',''),
  ('6DR4004-6G','Inductive Limit Switches (ILS), with explosion protection',''),
  ('6DR4004-8G','Inductive Limit Switches (ILS), without explosion protection',''),
  ('6DR4004-6K','Mechanic Limit Switches (MLS), with explosion protection',''),
  ('6DR4004-8K','Mechanic Limit Switches (MLS), without explosion protection',''),
  ('6DR4004-6J','Analog Output Module (AOM), with explosion protection',''),
  ('6DR4004-8J','Analog Output Module (AOM), without explosion protection',''),
  ('6DR4004-5L','Internal NCS module, without explosion protection, for installation in SIPART PS2',''),
  ('6DR4004-5LE','Internal NCS module, with explosion protection, for installation in SIPART PS2',''),
  ('6DR4004-2BT','SITRANS AW050 Bluetooth adapter kit, as of FW 5.05.00',''),
  ('6DR4004-1LP','Overvoltage protection up to 6kV, 2-wire, M20x1.5',''),
  ('6DR4004-2LP','Overvoltage protection up to 6kV, 3-wire, M20x1.5',''),
  ('6DR4004-3LP','Overvoltage protection up to 6kV, 4-wire, M20x1.5',''),
  ('6DR4004-4LP','Overvoltage protection up to 6kV, PA/FF, M20x1.5',''),
  ('6DR4004-5A','Cable socket M12 stainless steel, A-coding, for cable mounting 0.25-0.5mm2',''),
  ('6DR4004-5D','Cable socket M12 stainless steel, D-coding, for cable mounting 0.25-0.5mm2',''),
  ('6DR4004-1M','Gauge block, plastic gauges IP31 (MPa,bar), aluminum, single-acting, G1/4',''),
  ('6DR4004-2M','Gauge block, plastic gauges IP31 (MPa,bar), aluminum, double-acting, G1/4',''),
  ('6DR4004-1P','Gauge block, metal gauges IP44, aluminum, single-acting, G1/4',''),
  ('6DR4004-2P','Gauge block, metal gauges IP44, aluminum, double-acting, G1/4',''),
  ('6DR4004-1Q','Gauge block, stainless steel gauges IP54, 316, single-acting, G1/4',''),
  ('6DR4004-2Q','Gauge block, stainless steel gauges IP54, 316, double-acting, G1/4',''),
  ('6DR4004-2RE','Venting gauge block, aluminum, double-acting, G1/4',''),
  ('6DR4004-2RF','Venting gauge block, aluminum, double-acting, 1/4-18 NPT',''),
  ('6DR4004-1RJ','Booster (Cv=2), aluminum, single-acting, G1/2, non-flameproof enclosure variants',''),
  ('6DR4004-2RJ','Booster (Cv=2), aluminum, double-acting, G1/2, non-flameproof enclosure variants',''),
  ('6DR4004-1RP','Booster (Cv=2), aluminum, single-acting, G1/2, flameproof enclosure variants',''),
  ('6DR4004-2RP','Booster (Cv=2), aluminum, double-acting, G1/2, flameproof enclosure variants',''),
  ('6DR4004-5PB','Interface acc. to VDI/VDE 3847, single/double-acting, CATS single-acting only, not for flameproof',''),
  ('6DR4004-8D','Mounting kit for NAMUR part-turn actuators, VDI/VDE 3845, plastic coupling wheel',''),
  ('TGX:16300-1556','Mounting kit for NAMUR part-turn actuators, VDI/VDE 3845, stainless steel coupling',''),
  ('6DR4004-1D','Console for NAMUR part-turn actuator mounting, 80x30x20mm',''),
  ('6DR4004-2D','Console for NAMUR part-turn actuator mounting, 80x30x30mm',''),
  ('6DR4004-3D','Console for NAMUR part-turn actuator mounting, 130x30x30mm',''),
  ('6DR4004-4D','Console for NAMUR part-turn actuator mounting, 130x30x50mm',''),
  ('6DR4004-8V','Mounting kit for NAMUR linear actuator, short lever 2-35mm stroke',''),
  ('6DR4004-8L','Lever arm for strokes 35-130mm, without NAMUR mounting bracket',''),
  ('6DR4004-8VK','Reduced mounting kit (as 8V, no fixing angle/U-bracket), short lever up to 35mm',''),
  ('6DR4004-8VL','Reduced mounting kit (as 8V, no fixing angle/U-bracket), long lever >35mm',''),
  ('6DR4004-8R','Mounting console, stainless steel 316L, for flameproof enclosure/booster variants',''),
  ('6DR4004-3N','Tapered roller, stainless steel 316, replacement for 8V/8VK/8VL kits',''),
  ('6DR4004-3M','Terminal blocks, stainless steel 316, replacement for 8V/8VK/8VL kits',''),
  ('6DR4004-8S','Mounting kit for Samson actuator type 3277, yoke 101mm, not for Ex d',''),
  ('6DR4004-1R','Pneumatic terminal strip, stainless steel 316, single-acting, G1/4, spare part',''),
  ('6DR4004-2R','Pneumatic terminal strip, stainless steel 316, double-acting, G1/4, spare part',''),
  ('6DR4004-1B','Connection block for safety solenoid valve, extended NAMUR flange, per IEC 534-6',''),
  ('6DR4004-1C','Connection block for safety solenoid valve, SAMSON actuator integrated mounting',''),
  ('7MF4997-1DC','HART modem with USB interface',''),
  ('6DR4004-5DE','SIPART PS2 / PS100 demo case',''),
  ('TGX:16152-328','Mounting console for SPX (DEZURIK) Power Rac R1/R1A/R2/R2A',''),
  ('TGX:16152-350','Mounting console for Masoneilan Camflex II',''),
  ('TGX:16152-364','Mounting console for Fisher 1051/1052/1061, sizes 30/40/60-70',''),
  ('TGX:16152-1210','Mounting kit for MASONEILAN type 87/88',''),
  ('TGX:16152-1215','Mounting kit for MASONEILAN type 37/38, all sizes',''),
  ('TGX:16152-900','Mounting kit for Fisher type 657/667, sizes 30-80','')
ON CONFLICT (code) DO NOTHING;
