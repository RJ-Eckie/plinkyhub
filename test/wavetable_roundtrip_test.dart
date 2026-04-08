import 'dart:math';

import 'package:plinkyhub/utils/uf2.dart';
import 'package:plinkyhub/utils/wavetable.dart';
import 'package:test/test.dart';

List<double> _makeSawtooth() {
  return List<double>.generate(
    wavetableSamplesPerCycle,
    (i) => 2.0 * i / wavetableSamplesPerCycle - 1.0,
  );
}

List<double> _makeSine() {
  return List<double>.generate(
    wavetableSamplesPerCycle,
    (i) => sin(2.0 * pi * i / wavetableSamplesPerCycle),
  );
}

double _correlation(List<double> a, List<double> b) {
  assert(a.length == b.length);
  var sumAb = 0.0;
  var sumA2 = 0.0;
  var sumB2 = 0.0;
  for (var i = 0; i < a.length; i++) {
    sumAb += a[i] * b[i];
    sumA2 += a[i] * a[i];
    sumB2 += b[i] * b[i];
  }
  if (sumA2 == 0 || sumB2 == 0) {
    return 0;
  }
  return sumAb / sqrt(sumA2 * sumB2);
}

void main() {
  group('wavetable round-trip', () {
    late List<List<double>> extractedSlots;

    setUpAll(() {
      final slots = List<List<double>>.generate(
        wavetableUserShapeCount,
        (i) => i == 0 ? _makeSawtooth() : _makeSine(),
      );
      final uf2Bytes = generateWavetableUf2FromSamples(slots);
      final rawData = uf2ToData(uf2Bytes);
      extractedSlots = extractSamplesFromWavetableData(rawData);
    });

    test('extracts 15 slots', () {
      expect(extractedSlots.length, equals(wavetableUserShapeCount));
    });

    test('c0 correlates with sawtooth, not sine', () {
      final sawtooth = _makeSawtooth();
      final sine = _makeSine();
      final sawCorr = _correlation(extractedSlots[0], sawtooth);
      final sineCorr = _correlation(extractedSlots[0], sine).abs();
      expect(
        sawCorr,
        greaterThan(0.9),
        reason: 'c0 should correlate strongly with sawtooth (got $sawCorr)',
      );
      expect(
        sineCorr,
        lessThan(sawCorr),
        reason: 'c0 should correlate less with sine than sawtooth',
      );
    });

    test('c1 through c14 correlate with sine', () {
      final sine = _makeSine();
      for (var i = 1; i < wavetableUserShapeCount; i++) {
        final corr = _correlation(extractedSlots[i], sine);
        expect(
          corr,
          greaterThan(0.9),
          reason: 'c$i should correlate with sine (got $corr)',
        );
      }
    });
  });
}
