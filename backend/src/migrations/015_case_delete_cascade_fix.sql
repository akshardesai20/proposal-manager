-- Needed before cases can be deleted (see the new admin-only DELETE
-- /api/cases/:id endpoint). Every other table referencing cases(id)
-- already cascades on delete (case_events, costing_items, offers,
-- case_followups, reminders) — inbound_inquiries.created_case_id was the
-- one exception, added in migration 013 with no ON DELETE action, which
-- would block deleting any case that started life as a converted email
-- inquiry. SET NULL keeps the inquiry's own history intact (it's still
-- marked 'converted') while just detaching it from the now-deleted case.
ALTER TABLE inbound_inquiries DROP CONSTRAINT IF EXISTS inbound_inquiries_created_case_id_fkey;
ALTER TABLE inbound_inquiries
  ADD CONSTRAINT inbound_inquiries_created_case_id_fkey
  FOREIGN KEY (created_case_id) REFERENCES cases(id) ON DELETE SET NULL;
