-- Fix the public read policies for wavetables and patterns.
-- The original policies compared file_path to itself instead of
-- comparing to the storage object name.

DROP POLICY IF EXISTS "Anyone can read public wavetable files" ON storage.objects;
CREATE POLICY "Anyone can read public wavetable files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'wavetables'
    AND EXISTS (
      SELECT 1 FROM wavetables
      WHERE wavetables.file_path = objects.name
        AND wavetables.is_public = true
    )
  );

DROP POLICY IF EXISTS "Anyone can read public pattern files" ON storage.objects;
CREATE POLICY "Anyone can read public pattern files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'patterns'
    AND EXISTS (
      SELECT 1 FROM patterns
      WHERE patterns.file_path = objects.name
        AND patterns.is_public = true
    )
  );
