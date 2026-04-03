-- Recompute pack content_hash excluding wavetable.
-- The wavetable only appears on the emulated drive when transferred in the
-- same session, so it should not affect pack identity.
--
-- Hash format matches the Dart computePackContentHash():
--   sorted preset parts "p{index}:{hash}" joined by "|"
--   then sorted sample parts "s{index}:{hash}"
--   then sorted pattern parts "t{index}:{hash}"
-- SHA-256 hex digest of the resulting UTF-8 string.

-- Constants matching the Dart code:
--   presetSlotStart  = 0
--   patternSlotStart = 32  (presetCount)
--   sampleSlotStart  = 56  (presetCount + patternCount)

UPDATE packs
SET content_hash = encode(
  extensions.digest(
    (
      SELECT string_agg(part, '|' ORDER BY type_order, idx)
      FROM (
        -- Presets: slot_number 0..31, index = slot_number
        SELECT
          1 AS type_order,
          ps.slot_number AS idx,
          'p' || ps.slot_number || ':' || p.content_hash AS part
        FROM pack_slots ps
        JOIN presets p ON p.id = ps.preset_id
        WHERE ps.pack_id = packs.id
          AND ps.slot_number < 32
          AND p.content_hash IS NOT NULL

        UNION ALL

        -- Samples: slot_number 56..63, index = slot_number - 56
        SELECT
          2 AS type_order,
          ps.slot_number - 56 AS idx,
          's' || (ps.slot_number - 56) || ':' || s.content_hash AS part
        FROM pack_slots ps
        JOIN samples s ON s.id = ps.sample_id
        WHERE ps.pack_id = packs.id
          AND ps.slot_number >= 56
          AND s.content_hash IS NOT NULL

        UNION ALL

        -- Patterns: slot_number 32..55, index = slot_number - 32
        SELECT
          3 AS type_order,
          ps.slot_number - 32 AS idx,
          't' || (ps.slot_number - 32) || ':' || pt.content_hash AS part
        FROM pack_slots ps
        JOIN patterns pt ON pt.id = ps.pattern_id
        WHERE ps.pack_id = packs.id
          AND ps.slot_number >= 32
          AND ps.slot_number < 56
          AND pt.content_hash IS NOT NULL
      ) parts
    ),
    'sha256'
  ),
  'hex'
)
WHERE content_hash IS NOT NULL;
