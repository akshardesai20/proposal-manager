import { pool } from "../db.js";

// Takes the already-validated rows from validateRows.js (only ones with
// status !== 'error' should be passed in — the route filters this) and
// actually creates the customers/cases. Runs as one transaction for the
// whole batch: if anything unexpected fails partway through, nothing is
// left half-imported — safer to redo the whole batch than reason about a
// partially-applied one against live business data.
export async function commitRows(rows, { userId, batchId }) {
  const client = await pool.connect();
  const created = [];
  try {
    await client.query("BEGIN");

    for (const row of rows) {
      let customerId = row.customer.id;
      if (row.customer.willCreate) {
        const { rows: custRows } = await client.query(
          `INSERT INTO customers (name, code, contact_person, email, phone, address, gst_number)
           VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
          [
            row.customer.name, row.customer.code, row.customer.contact_person,
            row.customer.email, row.customer.phone, row.customer.address, row.customer.gst_number,
          ]
        );
        customerId = custRows[0].id;
      }

      const c = row.case;
      const { rows: caseRows } = await client.query(
        `INSERT INTO cases (
           customer_id, requirement_text, assigned_sales_engineer, stage, segment,
           inquiry_type, reference, created_at, costing_completed_at, offer_prepared_at,
           offer_sent_at, negotiation_completed_at, closed_at, outcome, expected_order_date,
           notes, import_batch_id
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
         RETURNING id`,
        [
          customerId, c.requirement_text, c.assigned_user_id, c.stage, c.segment,
          c.inquiry_type, c.reference, c.created_at, c.costing_completed_at, c.offer_prepared_at,
          c.offer_sent_at, c.negotiation_completed_at, c.closed_at, c.outcome, c.expected_order_date,
          c.notes, batchId,
        ]
      );
      const caseId = caseRows[0].id;

      await client.query(
        `INSERT INTO case_events (case_id, from_stage, to_stage, changed_by, note)
         VALUES ($1, NULL, $2, $3, 'Imported from bulk upload')`,
        [caseId, c.stage, userId]
      );

      if (c.offer_value !== null && c.offer_value !== undefined) {
        await client.query(
          `INSERT INTO costing_items (case_id, source, description, instrument_name, qty, list_price, discount_pct, margin_pct, final_unit_price, sort_order)
           VALUES ($1,'manual',$2,$3,1,$4,0,0,$4,0)`,
          [
            caseId,
            "Imported — aggregate offer value (line-item detail not migrated)",
            "Imported total value",
            c.offer_value,
          ]
        );
      }

      created.push({ rowNumber: row.rowNumber, caseId, customerId });
    }

    await client.query(
      `UPDATE import_batches SET row_count = $1 WHERE id = $2`,
      [created.length, batchId]
    );

    await client.query("COMMIT");
    return created;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
