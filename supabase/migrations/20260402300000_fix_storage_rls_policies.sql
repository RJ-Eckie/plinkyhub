-- Fix the public read policies for wavetables, patterns, and samples.
-- The original wavetable/pattern policies compared file_path to itself
-- instead of to objects.name. The sample policy didn't cover pcm_file_path.

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

DROP POLICY IF EXISTS "Anyone can read public sample files" ON storage.objects;
CREATE POLICY "Anyone can read public sample files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'samples'
    AND EXISTS (
      SELECT 1 FROM samples
      WHERE (samples.file_path = objects.name
             OR samples.pcm_file_path = objects.name)
        AND samples.is_public = true
    )
  );
