// Seeds realistic-but-entirely-fake demo data for a sales-demo deployment
// of this portal — separate customers, cases across every pipeline stage,
// follow-ups, and a couple of generated offers, so the app looks lived-in
// rather than empty on a first login.
//
// Usage (run once, against the DEMO database only — never against a real
// customer's live database):
//   node scripts/seedDemoData.js
//
// Safe to re-run: it checks for a marker customer first and exits early
// if demo data already exists, rather than creating duplicates.
import bcrypt from "bcryptjs";

const DAYS = 86400000;
const ago = (days) => new Date(Date.now() - days * DAYS);
const fromNow = (days) => new Date(Date.now() + days * DAYS);

export async function seedDemoData(pool) {
  const marker = await pool.query(`SELECT id FROM customers WHERE code = 'DEMO-BW'`);
  if (marker.rows.length) {
    console.log("Demo data already present (found DEMO-BW) — skipping. Nothing changed.");
    return { alreadySeeded: true };
  }

  console.log("Seeding demo data...");

  // --- Users -------------------------------------------------------
  const demoPassword = "Demo@1234";
  const hash = await bcrypt.hash(demoPassword, 10);

  const admin = (await pool.query(
    `INSERT INTO users (name, email, password_hash, role, designation)
     VALUES ('Demo Admin', 'admin@demo.local', $1, 'admin', 'Director')
     RETURNING id`, [hash]
  )).rows[0];
  const asha = (await pool.query(
    `INSERT INTO users (name, email, password_hash, role, designation, phone)
     VALUES ('Asha Mehta', 'asha@demo.local', $1, 'sales', 'Sales Engineer', '9800011122')
     RETURNING id`, [hash]
  )).rows[0];
  const rahul = (await pool.query(
    `INSERT INTO users (name, email, password_hash, role, designation, phone)
     VALUES ('Rahul Verma', 'rahul@demo.local', $1, 'proposal', 'Proposal Engineer', '9800033344')
     RETURNING id`, [hash]
  )).rows[0];

  // --- Customers -----------------------------------------------------
  const bluewave = (await pool.query(
    `INSERT INTO customers (name, code, contact_person, email, phone, address, gst_number)
     VALUES ('Bluewave Engineering Pvt Ltd', 'DEMO-BW', 'Mr. Sanjay Rao', 'purchase@bluewave-demo.local',
             '9811100011', '14 Industrial Estate, Pune - 411019', '27ABCDE1234F1Z5') RETURNING id`
  )).rows[0];
  const coastal = (await pool.query(
    `INSERT INTO customers (name, code, contact_person, email, phone, address, gst_number)
     VALUES ('Coastal Process Systems', 'DEMO-CP', 'Ms. Priya Nair', 'procurement@coastal-demo.local',
             '9822200022', 'Plot 7, Chemical Zone, Vadodara - 390010', '24FGHIJ5678K1Z2') RETURNING id`
  )).rows[0];
  const meridian = (await pool.query(
    `INSERT INTO customers (name, code, contact_person, email, phone, address, gst_number)
     VALUES ('Meridian Industries Ltd', 'DEMO-MI', 'Mr. Vikram Shah', 'vikram@meridian-demo.local',
             '9833300033', 'B-22 MIDC Area, Nashik - 422010', '27LMNOP9012Q1Z8') RETURNING id`
  )).rows[0];

  // --- Helper to insert a case with explicit backdated timestamps -----
  async function makeCase({ customer, requirement, segment, stage, assignedTo, createdDaysAgo,
    scheduledOfferDate, offerPreparedDaysAgo, negotiationCompletedDaysAgo, closedDaysAgo, outcome,
    expectedOrderDate, reference }) {
    const created = ago(createdDaysAgo);
    const { rows } = await pool.query(
      `INSERT INTO cases (customer_id, requirement_text, assigned_sales_engineer, stage, segment,
                           inquiry_type, reference, created_at, scheduled_offer_date,
                           costing_completed_at, offer_prepared_at, offer_sent_at,
                           negotiation_completed_at, closed_at, outcome, expected_order_date)
       VALUES ($1,$2,$3,$4,$5,'purchase',$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
       RETURNING *`,
      [
        customer, requirement, assignedTo, stage, segment, reference, created,
        scheduledOfferDate || null,
        ["costing_complete", "offer_prepared", "offer_sent", "negotiation_complete", "won", "lost"].includes(stage) ? ago(createdDaysAgo - 1) : null,
        offerPreparedDaysAgo != null ? ago(offerPreparedDaysAgo) : null,
        stage === "offer_sent" || stage === "negotiation_complete" || stage === "won" || stage === "lost" ? ago(Math.max(offerPreparedDaysAgo - 1, 0)) : null,
        negotiationCompletedDaysAgo != null ? ago(negotiationCompletedDaysAgo) : null,
        closedDaysAgo != null ? ago(closedDaysAgo) : null,
        outcome || null,
        expectedOrderDate || null,
      ]
    );
    return rows[0];
  }

  async function addCosting(caseId, lines) {
    let sort = 0;
    for (const l of lines) {
      await pool.query(
        `INSERT INTO costing_items (case_id, source, instrument_name, model_code, product_name, description,
                                     range_value, qty, list_price, discount_pct, margin_pct, final_unit_price, sort_order)
         VALUES ($1,'manual',$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
        [caseId, l.name, l.model, l.name, l.desc, l.range, l.qty, l.list, l.disc, l.margin, l.unit, sort++]
      );
    }
  }

  async function addFollowup(caseId, daysAgoVal, text, userId) {
    await pool.query(
      `INSERT INTO case_followups (case_id, followup_date, update_text, created_by, created_at)
       VALUES ($1,$2,$3,$4,$5)`,
      [caseId, ago(daysAgoVal), text, userId, ago(daysAgoVal)]
    );
  }

  async function addOffer(caseRow, preparedBy, revision, daysAgoVal) {
    const items = (await pool.query(
      `SELECT * FROM costing_items WHERE case_id = $1 ORDER BY sort_order`, [caseRow.id]
    )).rows;
    const itemsSnapshot = items.map((it) => ({
      description: it.description, instrument_name: it.instrument_name, product_name: it.product_name,
      range_value: it.range_value, qty: it.qty, final_unit_price: it.final_unit_price, model_code: it.model_code,
    }));
    const codeForRef = caseRow.customer_code || "CUSTOMER";
    const ref = `SI/${caseRow.reference}/${codeForRef}/R${revision}`;
    await pool.query(
      `INSERT INTO offers (case_id, ref, revision, prepared_by, items_snapshot, terms_snapshot, generated_at)
       VALUES ($1,$2,$3,$4,$5,'[]'::jsonb,$6)`,
      [caseRow.id, ref, revision, preparedBy, JSON.stringify(itemsSnapshot), ago(daysAgoVal)]
    );
  }

  // --- Cases across every stage, spread across both demo users -------

  const c1 = await makeCase({
    customer: bluewave.id, requirement: "Pressure transmitters for new boiler feed line",
    segment: "ww", stage: "enquiry", assignedTo: asha.id, createdDaysAgo: 2, reference: "DEMO-0001",
  });
  await addFollowup(c1.id, 1, "Initial call done, awaiting spec sheet from customer.", asha.id);

  const c2 = await makeCase({
    customer: coastal.id, requirement: "Level transmitters for effluent treatment tanks",
    segment: "instrument_service", stage: "enquiry", assignedTo: rahul.id, createdDaysAgo: 20, reference: "DEMO-0002",
  }); // deliberately no follow-up logged — shows up in "needs follow-up"
  void c2;

  const c3 = await makeCase({
    customer: meridian.id, requirement: "Flow measurement upgrade for cooling water circuit",
    segment: "industries", stage: "costing_complete", assignedTo: asha.id, createdDaysAgo: 12, reference: "DEMO-0003",
  });
  await addCosting(c3.id, [
    { name: "SITRANS FM MAG 3100", model: "7ME6520", desc: "Electromagnetic flow sensor", range: "0-50 m3/h", qty: 2, list: 85000, disc: 55, margin: 25, unit: 47800 },
  ]);

  const c4 = await makeCase({
    customer: bluewave.id, requirement: "Pressure gauges for compressor station",
    segment: "ww", stage: "offer_prepared", assignedTo: rahul.id, createdDaysAgo: 15,
    scheduledOfferDate: ago(6), offerPreparedDaysAgo: 4, reference: "DEMO-0004",
  }); // scheduled 6 days ago, prepared 4 days ago -> LATE (shows in punctuality as a miss)
  await addCosting(c4.id, [
    { name: "SITRANS P320", model: "7MF0350", desc: "Gauge pressure transmitter", range: "0-16 bar", qty: 4, list: 32000, disc: 50, margin: 30, unit: 20800 },
  ]);
  await addOffer({ ...c4, customer_code: "BLUEWAVE" }, rahul.id, 0, 4);

  const c5 = await makeCase({
    customer: coastal.id, requirement: "Ultrasonic flowmeter retrofit for existing pipeline",
    segment: "instrument_service", stage: "offer_sent", assignedTo: asha.id, createdDaysAgo: 18,
    scheduledOfferDate: ago(9), offerPreparedDaysAgo: 10, reference: "DEMO-0005",
  }); // scheduled 9 days ago, prepared 10 days ago -> ON TIME (prepared before the deadline)
  await addCosting(c5.id, [
    { name: "SITRANS FSS100", model: "7ME3810", desc: "Ultrasonic retrofit kit", range: "DN100", qty: 1, list: 210000, disc: 45, margin: 28, unit: 148000 },
  ]);
  await addOffer({ ...c5, customer_code: "COASTAL" }, asha.id, 0, 10);
  await addFollowup(c5.id, 2, "Customer reviewing internally, expects to revert by next week.", asha.id);

  const c6 = await makeCase({
    customer: meridian.id, requirement: "Positioner replacement for control valve fleet",
    segment: "industries", stage: "negotiation_complete", assignedTo: rahul.id, createdDaysAgo: 30,
    scheduledOfferDate: ago(20), offerPreparedDaysAgo: 19, negotiationCompletedDaysAgo: 3,
    expectedOrderDate: fromNow(5), reference: "DEMO-0006",
  });
  await addCosting(c6.id, [
    { name: "SIPART PS2", model: "6DR5", desc: "Electropneumatic positioner", range: "—", qty: 6, list: 28000, disc: 48, margin: 26, unit: 18300 },
  ]);
  await addOffer({ ...c6, customer_code: "MERIDIAN" }, rahul.id, 0, 19);

  const c7 = await makeCase({
    customer: bluewave.id, requirement: "Diaphragm seal assembly for corrosive service line",
    segment: "ww", stage: "won", assignedTo: asha.id, createdDaysAgo: 25,
    scheduledOfferDate: ago(16), offerPreparedDaysAgo: 15, negotiationCompletedDaysAgo: 5,
    closedDaysAgo: 1, outcome: "won", reference: "DEMO-0007",
  });
  await addCosting(c7.id, [
    { name: "7MF0814 Diaphragm Seal", model: "7MF0814", desc: "Remote diaphragm seal", range: "—", qty: 3, list: 45000, disc: 50, margin: 25, unit: 28100 },
  ]);
  await addOffer({ ...c7, customer_code: "BLUEWAVE" }, asha.id, 0, 15);

  const c8 = await makeCase({
    customer: coastal.id, requirement: "Radar level transmitters for storage tanks",
    segment: "instrument_service", stage: "lost", assignedTo: rahul.id, createdDaysAgo: 40,
    scheduledOfferDate: ago(28), offerPreparedDaysAgo: 27, negotiationCompletedDaysAgo: 12,
    closedDaysAgo: 8, outcome: "lost", reference: "DEMO-0008",
  });
  await addCosting(c8.id, [
    { name: "SITRANS LT500", model: "7ML5", desc: "Radar level transmitter", range: "0-20m", qty: 2, list: 95000, disc: 48, margin: 22, unit: 60300 },
  ]);
  await addOffer({ ...c8, customer_code: "COASTAL" }, rahul.id, 0, 27);

  const c9 = await makeCase({
    customer: meridian.id, requirement: "Temperature transmitters for reactor monitoring",
    segment: "ww", stage: "negotiation_complete", assignedTo: asha.id, createdDaysAgo: 22,
    scheduledOfferDate: ago(14), offerPreparedDaysAgo: 13, negotiationCompletedDaysAgo: 2,
    expectedOrderDate: ago(1), reference: "DEMO-0009",
  }); // expected date already passed -> shows as OVERDUE in forecast
  await addCosting(c9.id, [
    { name: "SITRANS TF Field Transmitter", model: "7NG31", desc: "Field-mount temperature transmitter", range: "-50 to 250°C", qty: 5, list: 22000, disc: 52, margin: 24, unit: 13100 },
  ]);
  await addOffer({ ...c9, customer_code: "MERIDIAN" }, asha.id, 0, 13);

  // A case of admin's own, so admin's personal dashboard (not just the
  // Team Pipeline table) has something to show too.
  const c10 = await makeCase({
    customer: bluewave.id, requirement: "Annual maintenance contract renewal — instrumentation",
    segment: "instrument_service", stage: "offer_prepared", assignedTo: admin.id, createdDaysAgo: 8,
    scheduledOfferDate: ago(1), offerPreparedDaysAgo: 1, reference: "DEMO-0010",
  });
  await addCosting(c10.id, [
    { name: "Annual Calibration & AMC Service", model: "—", desc: "Preventive maintenance contract, 12 instruments", range: "—", qty: 1, list: 180000, disc: 10, margin: 15, unit: 186300 },
  ]);
  await addOffer({ ...c10, customer_code: "BLUEWAVE" }, admin.id, 0, 1);

  console.log("\nDemo data seeded successfully.");
  console.log("Login with any of:");
  console.log(`  admin@demo.local / ${demoPassword}  (admin — sees the Team Pipeline table)`);
  console.log(`  asha@demo.local  / ${demoPassword}  (sales)`);
  console.log(`  rahul@demo.local / ${demoPassword}  (proposal)`);
  console.log("\nChange these passwords before sharing the demo link with anyone external.");
  return { alreadySeeded: false, credentials: { admin: "admin@demo.local", asha: "asha@demo.local", rahul: "rahul@demo.local", password: demoPassword } };
}
