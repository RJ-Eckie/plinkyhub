-- Recompute preset content_hash with P_SAMPLE zeroed out.
--
-- The save-to-device flow remaps P_SAMPLE to match the target sample slot
-- layout, so the hash must be independent of the sample slot value.
-- P_SAMPLE occupies bytes 832-833 (little-endian Int16) in the preset binary
-- which is stored as base64 in the preset_data column.
--
-- We decode the base64 preset_data, zero out bytes at offset 832-833,
-- then SHA-256 hash the result.

UPDATE presets
SET content_hash = encode(
  extensions.digest(
    set_byte(set_byte(decode(preset_data, 'base64'), 832, 0), 833, 0),
    'sha256'
  ),
  'hex'
)
WHERE content_hash IS NOT NULL
  AND preset_data IS NOT NULL
  AND length(decode(preset_data, 'base64')) > 833;
