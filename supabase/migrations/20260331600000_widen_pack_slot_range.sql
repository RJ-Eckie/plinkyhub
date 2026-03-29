-- Widen slot_number range to accommodate presets (0-31),
-- patterns (32-55), and samples (56-63).
ALTER TABLE pack_slots
  DROP CONSTRAINT pack_slots_slot_number_check;

ALTER TABLE pack_slots
  ADD CONSTRAINT pack_slots_slot_number_check
  CHECK (slot_number >= 0 AND slot_number <= 63);

-- Update the unique constraint to use the new pack_id column name
-- (was bank_id, renamed in a previous migration).
