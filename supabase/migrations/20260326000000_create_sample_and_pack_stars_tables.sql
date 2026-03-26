-- Sample stars
CREATE TABLE sample_stars (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sample_id uuid NOT NULL REFERENCES samples(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sample_id, user_id)
);

ALTER TABLE sample_stars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read sample stars" ON sample_stars FOR SELECT USING (true);
CREATE POLICY "Users can insert own sample stars" ON sample_stars FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own sample stars" ON sample_stars FOR DELETE USING (auth.uid() = user_id);

-- Pack stars
CREATE TABLE pack_stars (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pack_id uuid NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (pack_id, user_id)
);

ALTER TABLE pack_stars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read pack stars" ON pack_stars FOR SELECT USING (true);
CREATE POLICY "Users can insert own pack stars" ON pack_stars FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own pack stars" ON pack_stars FOR DELETE USING (auth.uid() = user_id);
