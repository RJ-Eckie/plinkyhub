-- Fix the public sample read policy to also cover pcm_file_path.
-- The original policy only matched file_path (WAV), so public PCM
-- downloads failed.

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
