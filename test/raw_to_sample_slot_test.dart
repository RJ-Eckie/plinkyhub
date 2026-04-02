// ignore_for_file: avoid_print

import 'package:plinkyhub/utils/presets_uf2.dart';
import 'package:test/test.dart';

void main() {
  group('rawToSampleSlot', () {
    test('raw 0 returns -1 (no sample)', () {
      expect(rawToSampleSlot(0), equals(-1));
    });

    test('maps firmware midpoint values to correct slots', () {
      // These are the actual raw values the Plinky firmware stores
      // for each sample slot (midpoints of 0-based 8-segment encoding).
      const firmwareValues = {
        56: 0,
        170: 1,
        284: 2,
        398: 3,
        512: 4,
        625: 5,
        739: 6,
        853: 7,
      };

      for (final entry in firmwareValues.entries) {
        expect(
          rawToSampleSlot(entry.key),
          equals(entry.value),
          reason: 'raw=${entry.key} should map to slot ${entry.value}',
        );
      }
    });

    test('clamps out-of-range values to slot 7', () {
      expect(rawToSampleSlot(967), equals(7));
      expect(rawToSampleSlot(1024), equals(7));
    });

    test('values near segment boundaries map correctly', () {
      // Boundary between slot 0 and slot 1 is at 1024/8 * 0.5 = 64
      expect(rawToSampleSlot(63), equals(0));
      expect(rawToSampleSlot(65), equals(1));

      // Boundary between slot 3 and slot 4 is at 1024/8 * 3.5 = 448
      expect(rawToSampleSlot(447), equals(3));
      expect(rawToSampleSlot(449), equals(4));
    });
  });
}
