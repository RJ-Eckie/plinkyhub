-- Add content_hash columns to enable deduplication of public content.
-- Hashes are computed client-side (SHA-256 of raw binary data) and stored
-- at upload time. When loading from Plinky, the client queries for existing
-- public entries with matching hashes to avoid creating duplicates.

ALTER TABLE presets
  ADD COLUMN content_hash text;

ALTER TABLE samples
  ADD COLUMN content_hash text;

ALTER TABLE wavetables
  ADD COLUMN content_hash text;

ALTER TABLE patterns
  ADD COLUMN content_hash text;

-- Index for fast lookups on public entries by hash.
CREATE INDEX idx_presets_public_hash ON presets (content_hash) WHERE is_public = true AND content_hash IS NOT NULL;
CREATE INDEX idx_samples_public_hash ON samples (content_hash) WHERE is_public = true AND content_hash IS NOT NULL;
CREATE INDEX idx_wavetables_public_hash ON wavetables (content_hash) WHERE is_public = true AND content_hash IS NOT NULL;
CREATE INDEX idx_patterns_public_hash ON patterns (content_hash) WHERE is_public = true AND content_hash IS NOT NULL;
