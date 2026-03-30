-- The constraint kept its original name (bank_slots_slot_number_check) after
-- the table was renamed from bank_slots to pack_slots.  Drop by the actual
-- name and re-create with the correct name and widened range.
ALTER TABLE pack_slots
  DROP CONSTRAINT IF EXISTS bank_slots_slot_number_check;

ALTER TABLE pack_slots
  DROP CONSTRAINT IF EXISTS pack_slots_slot_number_check;

ALTER TABLE pack_slots
  ADD CONSTRAINT pack_slots_slot_number_check
  CHECK (slot_number >= 0 AND slot_number <= 63);
