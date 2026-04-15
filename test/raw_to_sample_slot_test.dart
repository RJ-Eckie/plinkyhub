// ignore_for_file: avoid_print

import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:test/test.dart';

void main() {
  group('rawToSampleSlot', () {
    test('raw 0 returns -1 (no sample)', () {
      expect(rawToSampleSlot(0), equals(-1));
    });

    test('raws below slot 0 boundary return -1 (no sample)', () {
      // The firmware encodes P_SAMPLE 1-based: storedIndex = slot + 1,
      // storedIndex 0 is NO_SAMPLE. Slot 0 starts at raw 114, so any
      // raw below that maps back to NO_SAMPLE.
      expect(rawToSampleSlot(1), equals(-1));
      expect(rawToSampleSlot(56), equals(-1));
      expect(rawToSampleSlot(113), equals(-1));
    });

    test('maps each slot midpoint to its slot', () {
      // Midpoints of each firmware slot's raw range (width ≈ 1024/9).
      const midpointValues = {
        170: 0,
        284: 1,
        398: 2,
        512: 3,
        625: 4,
        739: 5,
        853: 6,
        967: 7,
      };

      for (final entry in midpointValues.entries) {
        expect(
          rawToSampleSlot(entry.key),
          equals(entry.value),
          reason: 'raw=${entry.key} should map to slot ${entry.value}',
        );
      }
    });

    test('round-trips canonical raw values from sampleSlotToRaw', () {
      for (var slot = 0; slot < 8; slot++) {
        final raw = sampleSlotToRaw(slot);
        expect(
          rawToSampleSlot(raw),
          equals(slot),
          reason: 'raw=$raw (from sampleSlotToRaw($slot)) should round-trip',
        );
      }
    });

    test('clamps out-of-range values to slot 7', () {
      // Raw values above the slot-7 range clamp to slot 7, matching the
      // firmware's clampi in save_param_index.
      expect(rawToSampleSlot(1024), equals(7));
      expect(rawToSampleSlot(2000), equals(7));
    });

    test('values near segment boundaries map correctly', () {
      // Boundary between NO_SAMPLE and slot 0 is at raw 114.
      expect(rawToSampleSlot(113), equals(-1));
      expect(rawToSampleSlot(114), equals(0));

      // Boundary between slot 0 and slot 1 is at raw 228.
      expect(rawToSampleSlot(227), equals(0));
      expect(rawToSampleSlot(228), equals(1));

      // Boundary between slot 3 and slot 4 is at raw 569.
      expect(rawToSampleSlot(568), equals(3));
      expect(rawToSampleSlot(569), equals(4));

      // Boundary between slot 6 and slot 7 is at raw 911.
      expect(rawToSampleSlot(910), equals(6));
      expect(rawToSampleSlot(911), equals(7));
    });
  });
}
