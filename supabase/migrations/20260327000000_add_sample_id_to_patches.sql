ALTER TABLE patches
  ADD COLUMN sample_id uuid REFERENCES samples(id) ON DELETE SET NULL;
