-- Move pattern references from packs to pack_slots, matching how
-- presets and samples are linked via slots.
ALTER TABLE pack_slots
  ADD COLUMN pattern_id uuid REFERENCES patterns(id);

ALTER TABLE packs
  DROP COLUMN pattern_id;
