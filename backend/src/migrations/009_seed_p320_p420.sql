-- Seeds SITRANS P320/P420 pressure transmitter families (FI 01 . 2024 catalog,
-- pages 1/86-1/169) plus the SITRANS 7MF0814 diaphragm seal accessory family.
-- This is the PT-320 catalog flagged as a follow-up in the original handoff
-- notes (a real customer offer referenced a PT-320 base article 7MF0300...
-- placeholder -- the real catalog base codes are 7MF03x/7MF04x as seeded
-- below; Manual entry was the fallback until now).
--
-- FAMILY MODEL: P320 and P420 share an identical position/option structure
-- per application series; only the electronics differ (P420 adds trend
-- log / diagnostic log / parameters change log -- not modeled here, that's
-- firmware behavior, not a costing-relevant order-code position). Each
-- "series" (gauge, gauge-DP-body, absolute, absolute-DP-body, DP-and-flow
-- PN160, DP-and-flow PN420, level) is its own base_code/family per the
-- catalog's own article numbering -- 14 families total (7MF030-7MF036 for
-- P320, 7MF040-7MF046 for P420), plus 7MF0814 (diaphragm seal, ordered
-- separately, required for Level V/W process-connection options).
--
-- MERGE NOTE: the catalog prints "Gauge pressure (pressure series)" and
-- "Gauge and absolute pressure, flush-mounted" as separate tables, but they
-- share the SAME base codes (7MF030/7MF040 for gauge, 7MF032/7MF042 for
-- absolute) -- flush-mounted is just a differently-filtered view of the
-- same order-code space (process connection K, or additional hygienic
-- approvals E86/E87). Seeded here as one merged family per base code
-- rather than duplicating rows.
--
-- KNOWN LIMITATIONS (representative subset, not exhaustive -- consistent
-- with how migration 002/008 handled large accessory tables):
--   1. Process-flange / valve-manifold / sanitary-connection suffix
--      options (J/K/M/N/P/Q/R/S/T/U-series) run into the hundreds of
--      DN-and-class combinations across these families. Only a
--      representative sample per family is seeded; the rest stay as
--      manual costing lines or free-text "-Z" additions until there's a
--      concrete need to expand a specific family's flange table.
--   2. 7MF0814 (diaphragm seal) has an unusually shaped order code where
--      "process connection" is itself a 3-character compound value
--      (standard + nominal diameter + nominal pressure, e.g. '0BD' =
--      EN1092-1 DN25 PN10/16/25/40). Only the EN 1092-1 rows are seeded;
--      ASME B16.5 and J.I.S. rows are extensive and left for manual entry
--      or a follow-up migration.
--   3. Device settings (Y-series) and device options (D-series) are
--      seeded per family as printed; P420-only diagnostic/logging
--      features (trend log, diagnostic log, parameter change log) are
--      firmware behavior, not order-code positions, so intentionally
--      absent from the decode tables.


-- ============================================================
-- FAMILY: SITRANS P320 - Gauge pressure (7MF030)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF030', 'SITRANS P320 - Gauge pressure', 'Pressure Transmitter (Gauge)', 'SITRANS P320 digital pressure transmitter for gauge pressure. HART/PROFIBUS PA/FOUNDATION Fieldbus. Also covers flush-mounted-diaphragm and diaphragm-seal-pressure variants (process connection K/U) under the same order code.', 'P320 Gauge', 'Pressure Transmitter (Gauge)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF030'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (2,'4','Neobee oil'),
  (3,'F','250 mbar (3.6 psi)'),
  (3,'J','1000 mbar (14.5 psi)'),
  (3,'N','4000 mbar (58 psi)'),
  (3,'Q','16 bar (232 psi)'),
  (3,'T','63 bar (914 psi)'),
  (3,'V','160 bar (2321 psi)'),
  (3,'W','400 bar (5802 psi)'),
  (3,'X','700 bar (10153 psi)'),
  (4,'B','External thread M20 x 1.5'),
  (4,'D','External thread G1/2 (EN 837-1)'),
  (4,'E','Internal thread 1/2-14 NPT'),
  (4,'F','External thread 1/2-14 NPT'),
  (4,'G','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'H','Oval flange, fastening thread M10 (DIN 19213)'),
  (4,'J','Oval flange, fastening thread M12 (DIN 19213)'),
  (4,'K','Flush-mounted diaphragm (options M-R)'),
  (4,'U','Version for diaphragm seal pressure'),
  (5,'0','Stainless steel 316L/1.4404, stainless steel 316L/1.4404'),
  (5,'1','Stainless steel 316L/1.4404, alloy C276/2.4819'),
  (5,'2','Alloy C22/2.4602, alloy C276/2.4819'),
  (5,'7','Stainless steel 316L/1.4404, stainless steel 316L/1.4404 gold-plated'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('B36','Nameplate labeling: Russian (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('E86','Special approval: 3A (hygiene)'),
  ('E87','Special approval: EHEDG (hygiene)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF030'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Gauge pressure (7MF040)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF040', 'SITRANS P420 - Gauge pressure', 'Pressure Transmitter (Gauge)', 'SITRANS P420 digital pressure transmitter for gauge pressure. Ready for Digitalization, advanced diagnostics per NAMUR NE107. Also covers flush-mounted-diaphragm and diaphragm-seal-pressure variants (process connection K/U) under the same order code.', 'P420 Gauge', 'Pressure Transmitter (Gauge)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF040'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (2,'4','Neobee oil'),
  (3,'F','250 mbar (3.6 psi)'),
  (3,'J','1000 mbar (14.5 psi)'),
  (3,'N','4000 mbar (58 psi)'),
  (3,'Q','16 bar (232 psi)'),
  (3,'T','63 bar (914 psi)'),
  (3,'V','160 bar (2321 psi)'),
  (3,'W','400 bar (5802 psi)'),
  (3,'X','700 bar (10153 psi)'),
  (4,'B','External thread M20 x 1.5'),
  (4,'D','External thread G1/2 (EN 837-1)'),
  (4,'E','Internal thread 1/2-14 NPT'),
  (4,'F','External thread 1/2-14 NPT'),
  (4,'G','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'H','Oval flange, fastening thread M10 (DIN 19213)'),
  (4,'J','Oval flange, fastening thread M12 (DIN 19213)'),
  (4,'K','Flush-mounted diaphragm (options M-R)'),
  (4,'U','Version for diaphragm seal pressure'),
  (5,'0','Stainless steel 316L/1.4404, stainless steel 316L/1.4404'),
  (5,'1','Stainless steel 316L/1.4404, alloy C276/2.4819'),
  (5,'2','Alloy C22/2.4602, alloy C276/2.4819'),
  (5,'7','Stainless steel 316L/1.4404, stainless steel 316L/1.4404 gold-plated'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('B36','Nameplate labeling: Russian (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('E86','Special approval: 3A (hygiene)'),
  ('E87','Special approval: EHEDG (hygiene)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF040'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P320 - Gauge pressure (differential series) (7MF031)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF031', 'SITRANS P320 - Gauge pressure (differential series)', 'Pressure Transmitter (Gauge, DP body)', 'SITRANS P320 digital pressure transmitter for gauge pressure, differential-pressure-body/oval-flange series.', 'P320 Gauge DP', 'Pressure Transmitter (Gauge, DP body)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF031'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert filling liquid'),
  (3,'B','20 mbar (8.037 inH2O)'),
  (3,'D','60 mbar (24.11 inH2O)'),
  (3,'G','250 mbar (1005 inH2O)'),
  (3,'H','600 mbar (241.1 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (2009 inH2O)'),
  (3,'R','30 bar (435 psi)'),
  (3,'Y','160 bar (2320 psi)'),
  (4,'L','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'M','Oval flange, fastening thread M10 (PN 160), (DIN 19213)'),
  (4,'N','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'P','Oval flange, fastening thread M10 (PN 160) (DIN 19213) with lateral ventilation'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Alloy C22/2.4602 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum/tantalum, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'6','Monel 400/2.4360 both, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D52','Extension of medium temperature to -40C for measuring cell filling with inert filling liquid'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF031'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Gauge pressure (differential series) (7MF041)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF041', 'SITRANS P420 - Gauge pressure (differential series)', 'Pressure Transmitter (Gauge, DP body)', 'SITRANS P420 digital pressure transmitter for gauge pressure, differential-pressure-body/oval-flange series.', 'P420 Gauge DP', 'Pressure Transmitter (Gauge, DP body)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF041'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert filling liquid'),
  (3,'B','20 mbar (8.037 inH2O)'),
  (3,'D','60 mbar (24.11 inH2O)'),
  (3,'G','250 mbar (1005 inH2O)'),
  (3,'H','600 mbar (241.1 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (2009 inH2O)'),
  (3,'R','30 bar (435 psi)'),
  (3,'Y','160 bar (2320 psi)'),
  (4,'L','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'M','Oval flange, fastening thread M10 (PN 160), (DIN 19213)'),
  (4,'N','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'P','Oval flange, fastening thread M10 (PN 160) (DIN 19213) with lateral ventilation'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Alloy C22/2.4602 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum/tantalum, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'6','Monel 400/2.4360 both, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D52','Extension of medium temperature to -40C for measuring cell filling with inert filling liquid'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF041'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P320 - Absolute pressure (7MF032)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF032', 'SITRANS P320 - Absolute pressure', 'Pressure Transmitter (Absolute)', 'SITRANS P320 digital pressure transmitter for absolute pressure. Also covers flush-mounted-diaphragm variant (process connection K, hygienic approvals) under the same order code.', 'P320 Absolute', 'Pressure Transmitter (Absolute)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF032'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert filling liquid'),
  (3,'F','250 mbar a (100.5 inH2O a)'),
  (3,'L','1300 mbar a (18.9 psi a)'),
  (3,'P','5000 mbar a (72.5 psi a)'),
  (3,'R','30 bar a (435 psi a)'),
  (3,'V','160 bar a (2321 psi a)'),
  (3,'W','400 bar a (5802 psi a)'),
  (3,'X','700 bar a (10153 psi a)'),
  (4,'B','External thread M20 x 1.5'),
  (4,'D','External thread G1/2 (EN 837-1)'),
  (4,'E','Internal thread 1/2-14 NPT'),
  (4,'F','External thread 1/2-14 NPT'),
  (4,'G','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'H','Oval flange, fastening thread M10 (DIN 19213)'),
  (4,'J','Oval flange, fastening thread M12 (DIN 19213)'),
  (4,'K','Flush-mounted diaphragm'),
  (4,'U','Version for diaphragm seal pressure'),
  (5,'0','Stainless steel 316L/1.4404, stainless steel 316L/1.4404'),
  (5,'1','Stainless steel 316L/1.4404, alloy C276/2.4819'),
  (5,'2','Alloy C22/2.4602, alloy C276/2.4819'),
  (5,'7','Stainless steel 316L/1.4404, stainless steel 316L/1.4404 gold-plated'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('E86','Special approval: 3A (hygiene)'),
  ('E87','Special approval: EHEDG (hygiene)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF032'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Absolute pressure (7MF042)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF042', 'SITRANS P420 - Absolute pressure', 'Pressure Transmitter (Absolute)', 'SITRANS P420 digital pressure transmitter for absolute pressure. Also covers flush-mounted-diaphragm variant (process connection K, hygienic approvals) under the same order code.', 'P420 Absolute', 'Pressure Transmitter (Absolute)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF042'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert filling liquid'),
  (3,'F','250 mbar a (100.5 inH2O a)'),
  (3,'L','1300 mbar a (18.9 psi a)'),
  (3,'P','5000 mbar a (72.5 psi a)'),
  (3,'R','30 bar a (435 psi a)'),
  (3,'V','160 bar a (2321 psi a)'),
  (3,'W','400 bar a (5802 psi a)'),
  (3,'X','700 bar a (10153 psi a)'),
  (4,'B','External thread M20 x 1.5'),
  (4,'D','External thread G1/2 (EN 837-1)'),
  (4,'E','Internal thread 1/2-14 NPT'),
  (4,'F','External thread 1/2-14 NPT'),
  (4,'G','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'H','Oval flange, fastening thread M10 (DIN 19213)'),
  (4,'J','Oval flange, fastening thread M12 (DIN 19213)'),
  (4,'K','Flush-mounted diaphragm'),
  (4,'U','Version for diaphragm seal pressure'),
  (5,'0','Stainless steel 316L/1.4404, stainless steel 316L/1.4404'),
  (5,'1','Stainless steel 316L/1.4404, alloy C276/2.4819'),
  (5,'2','Alloy C22/2.4602, alloy C276/2.4819'),
  (5,'7','Stainless steel 316L/1.4404, stainless steel 316L/1.4404 gold-plated'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('E86','Special approval: 3A (hygiene)'),
  ('E87','Special approval: EHEDG (hygiene)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF042'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P320 - Absolute pressure (differential series) (7MF033)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF033', 'SITRANS P320 - Absolute pressure (differential series)', 'Pressure Transmitter (Absolute, DP body)', 'SITRANS P320 digital pressure transmitter for absolute pressure, differential-pressure-body/oval-flange series.', 'P320 Absolute DP', 'Pressure Transmitter (Absolute, DP body)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF033'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert filling liquid'),
  (3,'G','250 mbar a (100.5 inH2O a)'),
  (3,'L','1300 mbar a (522 inH2O a)'),
  (3,'P','5000 mbar a (72.5 psi a)'),
  (3,'R','30 bar a (435 psi a)'),
  (3,'Y','160 bar (2320 psi)'),
  (4,'Q','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'R','Oval flange, fastening thread M10 (DIN 19213)'),
  (4,'S','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'T','Oval flange, fastening thread M10 (DIN 19213) with lateral ventilation'),
  (4,'V','Version for diaphragm seal with fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'W','Version for diaphragm seal with fastening thread M10 (DIN 19213)'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Alloy C22/2.4602 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum/tantalum, process flange stainless steel 316/1.4408'),
  (5,'6','Monel 400/2.4360 both, process flange stainless steel 316/1.4408'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated, process flange stainless steel 316/1.4408'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF033'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Absolute pressure (differential series) (7MF043)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF043', 'SITRANS P420 - Absolute pressure (differential series)', 'Pressure Transmitter (Absolute, DP body)', 'SITRANS P420 digital pressure transmitter for absolute pressure, differential-pressure-body/oval-flange series.', 'P420 Absolute DP', 'Pressure Transmitter (Absolute, DP body)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF043'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert filling liquid'),
  (3,'G','250 mbar a (100.5 inH2O a)'),
  (3,'L','1300 mbar a (522 inH2O a)'),
  (3,'P','5000 mbar a (72.5 psi a)'),
  (3,'R','30 bar a (435 psi a)'),
  (3,'Y','160 bar (2320 psi)'),
  (4,'Q','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'R','Oval flange, fastening thread M10 (DIN 19213)'),
  (4,'S','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'T','Oval flange, fastening thread M10 (DIN 19213) with lateral ventilation'),
  (4,'V','Version for diaphragm seal with fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'W','Version for diaphragm seal with fastening thread M10 (DIN 19213)'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Alloy C22/2.4602 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum/tantalum, process flange stainless steel 316/1.4408'),
  (5,'6','Monel 400/2.4360 both, process flange stainless steel 316/1.4408'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated, process flange stainless steel 316/1.4408'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF043'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P320 - Differential pressure and flow, PN160 (7MF034)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF034', 'SITRANS P320 - Differential pressure and flow, PN160', 'Pressure Transmitter (DP/Flow)', 'SITRANS P320 digital pressure transmitter for differential pressure and flow, PN 160 (MAWP 2320 psi).', 'P320 DP/Flow PN160', 'Pressure Transmitter (DP/Flow)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF034'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (2,'4','Neobee oil'),
  (3,'B','20 mbar (8.037 inH2O)'),
  (3,'D','60 mbar (24.11 inH2O)'),
  (3,'G','250 mbar (100.5 inH2O)'),
  (3,'H','600 mbar (241.1 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (2009 inH2O)'),
  (3,'R','30 bar (435 psi)'),
  (3,'Y','160 bar (2320 psi)'),
  (4,'L','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'M','Oval flange, fastening thread M10 (PN 160) (DIN 19213)'),
  (4,'N','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'P','Oval flange, fastening thread M10 (PN 160) (DIN 19213) with lateral ventilation'),
  (4,'V','Version for diaphragm seal with fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'W','Version for diaphragm seal with fastening thread M10 (PN 160) (DIN 19213)'),
  (4,'X','Version for diaphragm seal (one side direct, other side capillary) with fastening thread 7/16-20 UNF (IEC 61518)'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Alloy C22/2.4602 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum/tantalum, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'6','Monel 400/2.4360 both, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated, process flange stainless steel 316/1.4408'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D52','Extension of medium temperature to -40C for measuring cell filling with inert filling liquid'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y02','Square-rooted characteristic curve [VSLN2, MSLN2]'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF034'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Differential pressure and flow, PN160 (7MF044)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF044', 'SITRANS P420 - Differential pressure and flow, PN160', 'Pressure Transmitter (DP/Flow)', 'SITRANS P420 digital pressure transmitter for differential pressure and flow, PN 160 (MAWP 2320 psi).', 'P420 DP/Flow PN160', 'Pressure Transmitter (DP/Flow)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF044'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (2,'4','Neobee oil'),
  (3,'B','20 mbar (8.037 inH2O)'),
  (3,'D','60 mbar (24.11 inH2O)'),
  (3,'G','250 mbar (100.5 inH2O)'),
  (3,'H','600 mbar (241.1 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (2009 inH2O)'),
  (3,'R','30 bar (435 psi)'),
  (3,'Y','160 bar (2320 psi)'),
  (4,'L','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'M','Oval flange, fastening thread M10 (PN 160) (DIN 19213)'),
  (4,'N','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'P','Oval flange, fastening thread M10 (PN 160) (DIN 19213) with lateral ventilation'),
  (4,'V','Version for diaphragm seal with fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'W','Version for diaphragm seal with fastening thread M10 (PN 160) (DIN 19213)'),
  (4,'X','Version for diaphragm seal (one side direct, other side capillary) with fastening thread 7/16-20 UNF (IEC 61518)'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Alloy C22/2.4602 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum/tantalum, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'6','Monel 400/2.4360 both, process flange stainless steel 316/1.4408 (not with 20/60 mbar span)'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated, process flange stainless steel 316/1.4408'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D52','Extension of medium temperature to -40C for measuring cell filling with inert filling liquid'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y02','Square-rooted characteristic curve [VSLN2, MSLN2]'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF044'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P320 - Differential pressure and flow, PN420 (7MF035)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF035', 'SITRANS P320 - Differential pressure and flow, PN420', 'Pressure Transmitter (DP/Flow, High Pressure)', 'SITRANS P320 digital pressure transmitter for differential pressure and flow, PN 420 (MAWP 6092 psi).', 'P320 DP/Flow PN420', 'Pressure Transmitter (DP/Flow, High Pressure)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF035'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (3,'G','250 mbar (100.5 inH2O)'),
  (3,'H','600 mbar (241.1 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (2009 inH2O)'),
  (3,'R','30 bar (435 psi)'),
  (4,'L','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'M','Oval flange, fastening thread M12 (PN 420) (DIN 19213)'),
  (4,'N','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'P','Oval flange, fastening thread M12 (PN 420) (DIN 19213) with lateral ventilation'),
  (4,'V','Version for diaphragm seal with fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'X','Version for diaphragm seal (one side direct, other side capillary) with fastening thread 7/16-20 UNF (IEC 61518)'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'8','Stainless steel 316L/1.4404 + gold-plated, process flange stainless steel 316/1.4408'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D50','Increase of pressure rating from PN 420 to PN 500 (per IEC 61010; fluid group 2 acc. to DGRL only; not for hazardous media)'),
  ('D52','Extension of medium temperature to -40C for measuring cell filling with inert filling liquid'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y02','Square-rooted characteristic curve [VSLN2, MSLN2]'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF035'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Differential pressure and flow, PN420 (7MF045)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF045', 'SITRANS P420 - Differential pressure and flow, PN420', 'Pressure Transmitter (DP/Flow, High Pressure)', 'SITRANS P420 digital pressure transmitter for differential pressure and flow, PN 420 (MAWP 6092 psi).', 'P420 DP/Flow PN420', 'Pressure Transmitter (DP/Flow, High Pressure)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF045'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (3,'G','250 mbar (100.5 inH2O)'),
  (3,'H','600 mbar (241.1 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (2009 inH2O)'),
  (3,'R','30 bar (435 psi)'),
  (4,'L','Oval flange, fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'M','Oval flange, fastening thread M12 (PN 420) (DIN 19213)'),
  (4,'N','Oval flange, fastening thread 7/16-20 UNF (IEC 61518) with lateral ventilation'),
  (4,'P','Oval flange, fastening thread M12 (PN 420) (DIN 19213) with lateral ventilation'),
  (4,'V','Version for diaphragm seal with fastening thread 7/16-20 UNF (IEC 61518)'),
  (4,'X','Version for diaphragm seal (one side direct, other side capillary) with fastening thread 7/16-20 UNF (IEC 61518)'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'8','Stainless steel 316L/1.4404 + gold-plated, process flange stainless steel 316/1.4408'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D50','Increase of pressure rating from PN 420 to PN 500 (per IEC 61010; fluid group 2 acc. to DGRL only; not for hazardous media)'),
  ('D52','Extension of medium temperature to -40C for measuring cell filling with inert filling liquid'),
  ('D60','Transmitter packaged in foil'),
  ('D61','Cleaning the measuring cell, grease-free per cleanliness level 2, DIN 25410; transmitter packaged in foil'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y02','Square-rooted characteristic curve [VSLN2, MSLN2]'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design')
) AS v(code, meaning)
WHERE base_code = '7MF045'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P320 - Level (7MF036)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF036', 'SITRANS P320 - Level', 'Pressure Transmitter (Level, Hydrostatic)', 'SITRANS P320 digital pressure transmitter for hydrostatic level measurement. Diaphragm-seal versions (V/W) require remote seal 7MF0814, ordered separately.', 'P320 Level', 'Pressure Transmitter (Level, Hydrostatic)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF036'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (3,'D','60 mbar (24.11 inH2O)'),
  (3,'G','250 mbar (100.5 inH2O)'),
  (3,'H','600 mbar (241 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (72.5 psi)'),
  (3,'R','30 bar (435 psi)'),
  (3,'Y','160 bar (2321 psi)'),
  (4,'V','Version for diaphragm seal, fastening thread 7/16-20 UNF (IEC 61518); remote seal 7MF0814 ordered separately'),
  (4,'W','Version for diaphragm seal, fastening thread M10 (DIN 19213); remote seal ordered separately'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Sensor pressure: alloy C22/2.4602 + C276/2.4819; sensor DP: alloy C276/2.4819 both; process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum, tantalum; process flange stainless steel 316/1.4408 (not with 60 mbar span)'),
  (5,'6','Monel 400/2.4360 both; process flange stainless steel 316/1.4408 (not with 60 mbar span)'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated; process flange stainless steel 316/1.4408 (not with 60 mbar span)'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design'),
  ('K40','Process flange: gasket 1x chambered, graphite'),
  ('K41','Process flange: gasket 1x chambered, PTFE'),
  ('K84','Process flange: vent valve in the material of the process flange')
) AS v(code, meaning)
WHERE base_code = '7MF036'
ON CONFLICT (family_id, code) DO NOTHING;


-- ============================================================
-- FAMILY: SITRANS P420 - Level (7MF046)
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF046', 'SITRANS P420 - Level', 'Pressure Transmitter (Level, Hydrostatic)', 'SITRANS P420 digital pressure transmitter for hydrostatic level measurement. Diaphragm-seal versions (V/W) require remote seal 7MF0814, ordered separately.', 'P420 Level', 'Pressure Transmitter (Level, Hydrostatic)')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF046'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Communication',false,false),
    (2,'Measuring cell filling',false,false),
    (3,'Maximum measuring span',false,false),
    (4,'Process connection',false,false),
    (5,'Material of wetted parts',false,false),
    (6,'Material of non-wetted parts',false,false),
    (7,'Enclosure',true,false),
    (8,'Type of protection',false,false),
    (9,'Electrical connections/cable entries',false,false),
    (10,'Local operation/display',false,false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0','HART, 4 ... 20 mA'),
  (1,'1','PROFIBUS PA'),
  (1,'2','FOUNDATION Fieldbus (FF)'),
  (2,'1','Silicone oil'),
  (2,'3','Inert liquid'),
  (3,'D','60 mbar (24.11 inH2O)'),
  (3,'G','250 mbar (100.5 inH2O)'),
  (3,'H','600 mbar (241 inH2O)'),
  (3,'M','1600 mbar (643 inH2O)'),
  (3,'P','5000 mbar (72.5 psi)'),
  (3,'R','30 bar (435 psi)'),
  (3,'Y','160 bar (2321 psi)'),
  (4,'V','Version for diaphragm seal, fastening thread 7/16-20 UNF (IEC 61518); remote seal 7MF0814 ordered separately'),
  (4,'W','Version for diaphragm seal, fastening thread M10 (DIN 19213); remote seal ordered separately'),
  (5,'0','Stainless steel 316L/1.4404 both, process flange stainless steel 316/1.4408'),
  (5,'1','Stainless steel 316L/1.4404 + alloy C276/2.4819, process flange stainless steel 316/1.4408'),
  (5,'2','Sensor pressure: alloy C22/2.4602 + C276/2.4819; sensor DP: alloy C276/2.4819 both; process flange stainless steel 316/1.4408'),
  (5,'4','Tantalum, tantalum; process flange stainless steel 316/1.4408 (not with 60 mbar span)'),
  (5,'6','Monel 400/2.4360 both; process flange stainless steel 316/1.4408 (not with 60 mbar span)'),
  (5,'8','Stainless steel 316L/1.4404 gold-plated; process flange stainless steel 316/1.4408 (not with 60 mbar span)'),
  (6,'1','Die-cast aluminum'),
  (6,'2','Stainless steel precision casting CF3M/1.4409 similar to 316L'),
  (7,'5','Dual chamber device'),
  (8,'A','Without Ex'),
  (8,'B','Intrinsic safety'),
  (8,'C','Flameproof enclosure'),
  (8,'D','Flameproof enclosure, intrinsic safety'),
  (8,'L','Dust protection by enclosure Zone 21/22 (DIP), increased safety Zone 2'),
  (8,'M','Intrinsic safety, dust protection by enclosure Zone 20/21/22 (DIP), increased safety Zone 2'),
  (8,'S','Combination of options B, C and L (Zone model)'),
  (8,'T','Combination of options B, C and L (Zone model, Class Division)'),
  (9,'F','2 x M20 x 1.5 (cable gland ordered separately as option Axx)'),
  (9,'M','2 x 1/2-14 NPT (cable gland ordered separately as option Axx)'),
  (10,'0','Without local display (lid closed)'),
  (10,'1','With local display (lid closed)'),
  (10,'2','With local display (lid with glass pane)')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('A00','Cable gland included: plastic'),
  ('A01','Cable gland included: metal'),
  ('A02','Cable gland included: stainless steel'),
  ('A03','Cable gland included: stainless steel 316L/1.4404'),
  ('A10','Cable gland: CMP, for XP devices'),
  ('A11','CAPRI ADE 4F, CuZn, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A12','CAPRI ADE 4F, stainless steel, cable inner dia 7-12mm, outer dia 10-16mm'),
  ('A20','Sealing plug included, plastic'),
  ('A21','Sealing plug included, metal'),
  ('A22','Sealing plug included, stainless steel'),
  ('A23','Sealing plug included, stainless steel 316L/1.4404'),
  ('A30','Device plug Han 7D (plastic, straight), mounted left'),
  ('A31','Device plug Han 7D (plastic, angled), mounted left'),
  ('A32','Device plug Han 7D (metal, straight), mounted left'),
  ('A33','Device plug Han 7D (metal, angled), mounted left'),
  ('A34','Device plug Han 8D (plastic, straight), mounted left'),
  ('A35','Device plug Han 8D (plastic, angled), mounted left'),
  ('A36','Device plug Han 8D (metal, straight), mounted left'),
  ('A37','Device plug Han 8D (metal, angled), mounted left'),
  ('A40','Cable socket included, plastic, for device plug Han 7D and Han 8D'),
  ('A41','Cable socket included, metal, for device plug Han 7D and Han 8D'),
  ('A62','Device plug M12 mounted left, stainless steel, without cable socket'),
  ('A63','Device plug M12 mounted left, stainless steel, with cable socket'),
  ('A90','2x sealing plugs M20x1.5, IP66/68 installed both sides (no Ex approval)'),
  ('A91','2x sealing plugs 1/2-14 NPT, IP66/68 installed both sides (no Ex approval)'),
  ('A97','Cable gland/device plug mounted left'),
  ('A98','Plug mounted right'),
  ('A99','Cable gland/device plug mounted right'),
  ('B11','Nameplate labeling: German (bar)'),
  ('B12','Nameplate labeling: French (bar)'),
  ('B13','Nameplate labeling: Spanish (bar)'),
  ('B14','Nameplate labeling: Italian (bar)'),
  ('B15','Nameplate labeling: Chinese (bar)'),
  ('B16','Nameplate labeling: Russian (bar)'),
  ('B20','Nameplate labeling: English (psi)'),
  ('B30','Nameplate labeling: English (Pa)'),
  ('B35','Nameplate labeling: Chinese (Pa)'),
  ('C11','Quality inspection certificate, 5-point factory calibration (IEC 62828-2)'),
  ('C12','Inspection certificate (EN 10204-3.1) - Material of pressurized and wetted parts'),
  ('C13','Factory certificate - NACE (MR 0103-2012 and MR 0175-2009)'),
  ('C14','Factory certificate (EN 10204-2.2) - Wetted parts'),
  ('C15','Inspection certificate (EN 10204-3.1) - PMI test of pressurized and wetted parts'),
  ('C20','Functional Safety (IEC 61508) - SIL2/3'),
  ('D20','Double layer coating (epoxy resin and polyester) 120um of enclosure and lid'),
  ('D21','FVMQ enclosure sealing'),
  ('D30','Degree of protection IP66/IP68 (not for device plug M12 and Han)'),
  ('D40','Unlabeled TAG plate'),
  ('D41','Without labeling of the measuring range on the TAG plate'),
  ('D42','Stainless steel Ex plate 1.4404/316L'),
  ('D62','Cleaning the measuring cell, grease-free (for oxygen version) and transmitter packaged in foil; particles < 50 mg/m2, oil/grease content HC < 100 mg/m2'),
  ('D70','Overvoltage protection up to 6 kV (internal)'),
  ('D71','Overvoltage protection up to 6 kV (external)'),
  ('D90','Labels on transport packaging (provided by customer)'),
  ('E00','General approval: Worldwide (CE, UKCA, RCM) except EAC, FM, CSA, KC'),
  ('E01','General approval: Worldwide (CE, UKCA, RCM, EAC, FM, CSA, KC)'),
  ('E06','General approval: CSA (USA and Canada)'),
  ('E07','General approval: EAC'),
  ('E08','General approval: FM'),
  ('E09','General approval: KC'),
  ('E20','Explosion protection: ATEX (Europe)'),
  ('E21','Explosion protection: CSA (USA and Canada)'),
  ('E22','Explosion protection: FM (USA and Canada)'),
  ('E23','Explosion protection: IECEx (Worldwide)'),
  ('E24','Explosion protection: EACEx (GOST-R, -K, -B)'),
  ('E25','Explosion protection: INMETRO (Brazil)'),
  ('E26','Explosion protection: KCs (Korea)'),
  ('E27','Explosion protection: NEPSI (China)'),
  ('E28','Explosion protection: PESO (India)'),
  ('E29','Explosion protection: CSA (Japan)'),
  ('E32','Explosion protection: ECASEx (UAE)'),
  ('E33','Explosion protection: UKEX (United Kingdom)'),
  ('E47','Explosion protection: ATEX (Europe), IECEx (Worldwide) and UKEX (UK)'),
  ('E48','Explosion protection: CSA (Canada) and FM (USA)'),
  ('E49','Explosion protection: ATEX (Europe) and IECEx (Worldwide) + CSA (Canada) and FM (USA)'),
  ('E50','Marine approval: DNV-GL (Det Norske Veritas/Germanischer Lloyd)'),
  ('E51','Marine approval: LR (Lloyds Register)'),
  ('E52','Marine approval: BV (Bureau Veritas)'),
  ('E53','Marine approval: ABS (American Bureau of Shipping)'),
  ('E55','Marine approval: RMR (Russian Maritime Register)'),
  ('E56','Marine approval: KR (Korean Register of Shipping)'),
  ('E57','Marine approval: RINA (Registro Italiano Navale)'),
  ('E58','Marine approval: CCS (China Classification Society)'),
  ('E60','Country-specific approval: CRN approval Canada (Canadian Registration Number)'),
  ('E80','Special approval: Oxygen application (with inert liquid, max. 160 bar at 100C)'),
  ('E81','Special approval: Dual Seal'),
  ('E83','Special approval: WRC/WRAS (drinking water); only with process flange O-rings made of EPDM'),
  ('E84','Special approval: NSF61 (drinking water)'),
  ('E85','Special approval: ACS (drinking water)'),
  ('Y01','Measuring span: lower/upper range value (max. 5 chars each), unit'),
  ('Y15','TAG (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y16','Measuring point description (on stainless steel plate and device parameters, max. 32 characters)'),
  ('Y17','TAG short (device parameters, max. 8 characters)'),
  ('Y21','Local display: [Pressure, Percent], reference [None, Absolute, Gauge]'),
  ('Y22','Local display: scaling with standard units'),
  ('Y23','Local display: scaling with user-specific units (max. 12 characters)'),
  ('Y25','Set PROFIBUS PA device address (1...126)'),
  ('Y30','Saturation limits instead of 3.8...20.5 mA'),
  ('Y31','Fault current instead of 3.6 mA [22.5 mA, 22.8 mA]'),
  ('Y32','Damping in seconds instead of 2 s (0.0...100.0 s)'),
  ('Y99','ID number of special design'),
  ('K40','Process flange: gasket 1x chambered, graphite'),
  ('K41','Process flange: gasket 1x chambered, PTFE'),
  ('K84','Process flange: vent valve in the material of the process flange')
) AS v(code, meaning)
WHERE base_code = '7MF046'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- FAMILY: SITRANS 7MF0814 diaphragm seal (accessory, ordered separately)
-- Required for SITRANS P320/P420 Level (7MF036/7MF046) process connection
-- options V/W. Order code shape is unusual (see KNOWN LIMITATIONS #2 at
-- top of file) -- simplified here to 4 positions: Process connection
-- (standard+diameter+pressure as a 3-character compound value, EN 1092-1
-- rows only -- ASME B16.5 and J.I.S. rows are extensive and NOT seeded,
-- use manual entry or expand later), Filling liquid, Material of wetted
-- parts (some values are 2-character compounds per the catalog, e.g. the
-- coated/gold-plated/duplex variants), and Tube length. The fixed digits
-- in the middle of the real article number (...-03-0...) are not modeled;
-- cross-check against the PIA configurator before quoting a decoded
-- 7MF0814 code verbatim.
-- ============================================================
INSERT INTO siemens_families (base_code, family, short_name, description, trade_name, instrument_type)
VALUES ('7MF0814', 'SITRANS diaphragm seal (7MF0814)', 'Diaphragm Seal (Flange, Remote)',
  'Diaphragm seal in flange design for SITRANS P320/P420 Level transmitters (process connection V/W). Ordered separately, scope of delivery 1 unit.',
  '7MF0814', 'Diaphragm Seal')
ON CONFLICT (base_code) DO NOTHING;

WITH fam AS (SELECT id FROM siemens_families WHERE base_code = '7MF0814'),
pos AS (
  INSERT INTO siemens_positions (family_id, position_no, name, is_fix, is_range)
  SELECT fam.id, v.position_no, v.name, v.is_fix, v.is_range FROM fam,
  (VALUES
    (1,'Process connection (standard/diameter/pressure)', false, false),
    (2,'Filling liquid', false, false),
    (3,'Material of wetted parts', false, false),
    (4,'Tube length', false, false)
  ) AS v(position_no, name, is_fix, is_range)
  ON CONFLICT (family_id, position_no) DO NOTHING
  RETURNING id, position_no
)
INSERT INTO siemens_position_options (position_id, character, meaning, short_label)
SELECT pos.id, v.character, v.meaning, NULL FROM pos JOIN (VALUES

  (1,'0BD','EN 1092-1, DN 25, PN 10/16/25/40'),
  (1,'0BF','EN 1092-1, DN 25, PN 63/100'),
  (1,'0BG','EN 1092-1, DN 25, PN 160'),
  (1,'0BH','EN 1092-1, DN 25, PN 250'),
  (1,'0DD','EN 1092-1, DN 40, PN 10/16/25/40'),
  (1,'0DF','EN 1092-1, DN 40, PN 63/100'),
  (1,'0DG','EN 1092-1, DN 40, PN 160'),
  (1,'0ED','EN 1092-1, DN 50, PN 10/16/25/40'),
  (1,'0EE','EN 1092-1, DN 50, PN 63'),
  (1,'0EF','EN 1092-1, DN 50, PN 100'),
  (1,'0GD','EN 1092-1, DN 80, PN 10/16/25/40'),
  (1,'0GF','EN 1092-1, DN 80, PN 100'),
  (1,'0HB','EN 1092-1, DN 100, PN 10/16'),
  (1,'0HD','EN 1092-1, DN 100, PN 25/40'),
  (1,'0JB','EN 1092-1, DN 125, PN 16'),
  (1,'0JD','EN 1092-1, DN 125, PN 40'),
  (1,'1KL','ASME B16.5, 1 inch, Class 150'),
  (1,'1KM','ASME B16.5, 1 inch, Class 300'),
  (1,'1MA','ASME B16.5, 2 inches, Class 150'),
  (1,'1PA','ASME B16.5, 3 inches, Class 150'),
  (1,'2ES','J.I.S., DN 50, 10K'),
  (1,'2GS','J.I.S., DN 80, 10K'),
  (1,'9AA','Other version, add order code and plain text'),
  (2,'B','Silicone oil M50 (optimized -10...+200C)'),
  (2,'C','High-temperature oil (optimized -10...+300C)'),
  (2,'A','Silicone oil M5 (optimized -40...+140C)'),
  (2,'E','Food oil, FDA listed (optimized -10...+140C)'),
  (2,'R','Neobee M20, FDA listed (optimized -10...+140C)'),
  (2,'D','Halocarbon oil (optimized -20...+60C)'),
  (2,'Z','Other version, add order code and plain text'),
  (3,'A','Stainless steel 316L, without coating'),
  (3,'D','Stainless steel 316L, with PFA coating'),
  (3,'E0','Stainless steel 316L, with PTFE coating'),
  (3,'F','Stainless steel 316L, with ECTFE coating'),
  (3,'G','Monel 400, 2.4360'),
  (3,'J','Hastelloy C276, 2.4819'),
  (3,'K','Tantalum'),
  (3,'L0','Titanium, 3.7035'),
  (3,'M0','Nickel 201'),
  (3,'Q','Diaphragm Duplex, 1.4462'),
  (3,'R','Diaphragm and flange Duplex, 1.4462'),
  (3,'S0','Stainless steel 316L, gold-plated'),
  (3,'U0','Hastelloy C4, 2.4610'),
  (3,'V0','Hastelloy C22, 2.4602'),
  (3,'Z','Other version, add order code and plain text'),
  (4,'0','None'),
  (4,'1','50 mm (2 inches)'),
  (4,'2','100 mm (4 inches)'),
  (4,'3','150 mm (6 inches)'),
  (4,'4','200 mm (8 inches)'),
  (4,'5','250 mm (10 inches)'),
  (4,'Z','Other version / customer-specific length, add order code and plain text')

) AS v(position_no, character, meaning) ON pos.position_no = v.position_no
ON CONFLICT (position_id, character) DO NOTHING;


INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('C11','Quality inspection certificate (5-point characteristic curve test) per IEC 62828-2'),
  ('C12','Inspection certificate per EN 10204-3.1 for main body and diaphragm'),
  ('C13','Manufacturer code per NACE (MR 0103-2012 and MR 0175-2009) - stainless steel 316L/Hastelloy only'),
  ('C15','Inspection certificate per EN 10204-3.1, PMI test of pressure containing and wetted parts'),
  ('C17','Certificate on FDA listing of the fill oil per EN 10204-2.2'),
  ('C20','Factory certificate functional safety (SIL2/3) per IEC 61508/61511'),
  ('D15','Epoxy resin coating (transparent), front/rear of remote seal + connecting pipe + process connection; max medium temp with lacquering 140C'),
  ('D42','Remote seal nameplate, stainless steel, with Article No. and order number'),
  ('D62','Volume deflagration flame arrester (VDEF) for differential pressure transmitter'),
  ('D83','Negative pressure service for differential pressure transmitters'),
  ('D88','Extended negative pressure service for differential pressure transmitters'),
  ('E60','Country-specific approval: CRN approval Canada (must also be selected on the transmitter)'),
  ('E80','Oil-free/grease-free cleaned version for oxygen application incl. EN 10204-2.2 certs (halocarbon oil, max 60C, max 50 bar)'),
  ('E87','Oil-free/grease-free cleaned version not for oxygen application, incl. EN 10204-2.2 certs'),
  ('M50','Sealing surface smooth, form B2/EN1092-1 or RFSF/ANSI 16.5 (316L only)'),
  ('S05','Elongated pipe, 150 mm instead of 100 mm'),
  ('S06','Elongated pipe, 200 mm instead of 100 mm'),
  ('W01','Desired remote seal supplier: Company WIKA, Klingenberg'),
  ('W02','Desired remote seal supplier: Company Labom, Hude'),
  ('X01','Special design: welded filling hole'),
  ('Y44','Customer-specific tube length (specify in plain text, mm)'),
  ('D66','Ambient temperature range: -10...+50C (14...+122F), preset'),
  ('D67','Ambient temperature range: -40...+50C (-40...+122F)'),
  ('D68','Ambient temperature range: -10...+85C (14...+185F)'),
  ('Y50','Process temperature min/max, specify in plain text (C/F)')
) AS v(code, meaning)
WHERE base_code = '7MF0814'
ON CONFLICT (family_id, code) DO NOTHING;

-- ============================================================
-- EXTRA SUFFIXES: mounting brackets and shut-off valve manifolds --
-- the most commercially common items from each family's larger
-- flange/valve-manifold tables (see KNOWN LIMITATIONS #1 at top of file).
-- ============================================================

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('T02','Shut-off valve: mounted valve manifold 7MF9011-4EA, G1/2 shank, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T03','Shut-off valve: mounted valve manifold 7MF9011-4FA, internal thread 1/2-14 NPT, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T05','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, steel fixing screws, pressure test certified (EN 10204-2.2)'),
  ('T06','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, stainless steel fixing screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF030'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('T02','Shut-off valve: mounted valve manifold 7MF9011-4EA, G1/2 shank, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T03','Shut-off valve: mounted valve manifold 7MF9011-4FA, internal thread 1/2-14 NPT, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T05','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, steel fixing screws, pressure test certified (EN 10204-2.2)'),
  ('T06','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, stainless steel fixing screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF040'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('T02','Shut-off valve: mounted valve manifold 7MF9011-4EA, G1/2 shank, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T03','Shut-off valve: mounted valve manifold 7MF9011-4FA, internal thread 1/2-14 NPT, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T05','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, steel fixing screws, pressure test certified (EN 10204-2.2)'),
  ('T06','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, stainless steel fixing screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF032'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('T02','Shut-off valve: mounted valve manifold 7MF9011-4EA, G1/2 shank, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T03','Shut-off valve: mounted valve manifold 7MF9011-4FA, internal thread 1/2-14 NPT, PTFE sealing ring, pressure test certified (EN 10204-2.2)'),
  ('T05','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, steel fixing screws, pressure test certified (EN 10204-2.2)'),
  ('T06','Shut-off valve: mounted valve manifold 7MF9411-5AA, oval flange, stainless steel fixing screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF042'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF031'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF041'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF033'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF043'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF034'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF044'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF035'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('U01','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U02','Valve manifold (3-way) 7MF9411-5BA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)'),
  ('U03','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, chrome-plated steel screws, pressure test certified (EN 10204-2.2)'),
  ('U04','Valve manifold (5-way) 7MF9411-5CA, PTFE sealing rings, stainless steel screws, pressure test certified (EN 10204-2.2)')
) AS v(code, meaning)
WHERE base_code = '7MF045'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF031'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF041'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF032'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF042'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF033'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF043'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF034'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF044'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF035'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('H01','Mounting bracket: zinc-plated steel'),
  ('H02','Mounting bracket: stainless steel 1.4301/304'),
  ('H03','Mounting bracket: stainless steel 1.4404/316L'),
  ('H05','Mounting bracket: zinc-plated steel, reinforced (KTA)')
) AS v(code, meaning)
WHERE base_code = '7MF045'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J70','Flange connection EN 1092-1 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J71','Flange connection EN 1092-1 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J72','Flange connection EN 1092-1 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF031'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J70','Flange connection EN 1092-1 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J71','Flange connection EN 1092-1 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J72','Flange connection EN 1092-1 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF041'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J70','Flange connection EN 1092-1 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J71','Flange connection EN 1092-1 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J72','Flange connection EN 1092-1 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF033'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J70','Flange connection EN 1092-1 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J71','Flange connection EN 1092-1 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J72','Flange connection EN 1092-1 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF043'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J80','Flange adapter G1/2 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J81','Flange adapter G1/2 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J82','Flange adapter G1/2 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF030'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J80','Flange adapter G1/2 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J81','Flange adapter G1/2 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J82','Flange adapter G1/2 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF040'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J80','Flange adapter G1/2 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J81','Flange adapter G1/2 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J82','Flange adapter G1/2 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF032'
ON CONFLICT (family_id, code) DO NOTHING;

INSERT INTO siemens_suffixes (family_id, code, meaning)
SELECT id, v.code, v.meaning FROM siemens_families,
(VALUES
  ('J80','Flange adapter G1/2 form B1: DN 25 PN 40, stainless steel 1.4571/316Ti'),
  ('J81','Flange adapter G1/2 form B1: DN 50 PN 40, stainless steel 1.4571/316Ti'),
  ('J82','Flange adapter G1/2 form B1: DN 80 PN 40, stainless steel 1.4571/316Ti')
) AS v(code, meaning)
WHERE base_code = '7MF042'
ON CONFLICT (family_id, code) DO NOTHING;
