-- Allow users to overwrite their own wavetable files in storage.
-- Needed for editing existing wavetables (upsert).
CREATE POLICY "Users can update own wavetable files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'wavetables'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
