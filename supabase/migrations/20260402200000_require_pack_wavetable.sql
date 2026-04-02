-- Backfill any packs missing a wavetable with the default one.
UPDATE packs
SET wavetable_id = '6c69183b-ea82-4b31-9a7d-1afc6446714c'
WHERE wavetable_id IS NULL;

-- Make wavetable_id NOT NULL with the default wavetable.
ALTER TABLE packs
  ALTER COLUMN wavetable_id SET DEFAULT '6c69183b-ea82-4b31-9a7d-1afc6446714c',
  ALTER COLUMN wavetable_id SET NOT NULL;
