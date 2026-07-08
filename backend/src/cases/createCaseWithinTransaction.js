// Shared by POST /api/cases and POST /api/inquiries/:id/convert — both
// need to resolve-or-create a customer and insert a new case the same
// way, so there's one source of truth instead of two copies drifting.
// Caller owns the transaction (BEGIN/COMMIT/ROLLBACK) and passes in the
// connected client.
export async function createCaseWithinTransaction(client, { customer, requirement_text, inquiry_type, scheduled_offer_date, segment }, userId) {
  let customerId = customer.id;
  if (!customerId) {
    const { rows } = await client.query(
      `INSERT INTO customers (name, code, contact_person, email, phone, address, gst_number)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
      [
        customer.name, customer.code || null, customer.contact_person || null,
        customer.email || null, customer.phone || null, customer.address || null, customer.gst_number || null,
      ]
    );
    customerId = rows[0].id;
  }

  const { rows: caseRows } = await client.query(
    `INSERT INTO cases (customer_id, requirement_text, assigned_sales_engineer, stage, inquiry_type, scheduled_offer_date, segment)
     VALUES ($1,$2,$3,'enquiry',$4,$5,$6) RETURNING *`,
    [customerId, requirement_text || null, userId, inquiry_type || null, scheduled_offer_date || null, segment || null]
  );
  const created = caseRows[0];

  await client.query(
    `INSERT INTO case_events (case_id, from_stage, to_stage, changed_by, note)
     VALUES ($1, NULL, 'enquiry', $2, $3)`,
    [created.id, userId, "Case created"]
  );

  return created;
}
