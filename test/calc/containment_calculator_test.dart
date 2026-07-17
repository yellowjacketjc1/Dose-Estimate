import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/calc/containment_calculator.dart';

void main() {
  group('activityFromContamination', () {
    test('ft² default converts at 929.03 cm²/ft²', () {
      // 1000 dpm/100cm² over 10 ft²:
      // 10 ft² × 929.03 = 9290.3 cm² → 1000 × 92.903 dpm → / 2.22e6 µCi
      final uci = activityFromContamination(1000, 10, areaInCm2: false)!;
      expect(uci, closeTo(1000 * (9290.3 / 100) / 2.22e6, 1e-12));
    });

    test('cm² mode uses the area directly', () {
      final uci = activityFromContamination(1000, 9290.3, areaInCm2: true)!;
      final uciFt = activityFromContamination(1000, 10, areaInCm2: false)!;
      expect(uci, closeTo(uciFt, 1e-15));
    });

    test('not evaluable on non-positive inputs', () {
      expect(activityFromContamination(0, 10, areaInCm2: false), isNull);
      expect(activityFromContamination(1000, 0, areaInCm2: false), isNull);
    });
  });

  group('computePif', () {
    test('product of factors times 1e-6', () {
      expect(
        computePif(r: 0.01, c: 100.0, d: 1.0, o: 10.0, s: 1.0, u: 1.0),
        closeTo(0.01 * 100 * 10 * 1e-6, 1e-18),
      );
    });

    test('encapsulated (R=0) gives PIF 0 — no release pathway', () {
      expect(computePif(r: 0, c: 100, d: 1, o: 10, s: 1, u: 1), 0.0);
    });
  });

  group('computeContainment', () {
    // Single-nuclide reference case, hand-checkable:
    // sum = (activity × fr × fa × U) / (2000 × volume × mixing × dac)
    const activity = 100.0; // µCi
    const volume = 2.0e8; // cm³
    const mixing = 0.6;
    const fa = 1.0;
    const fr = 0.01;
    const dac = 8e-8; // Cs-137

    test('hand-computed sum of fractions', () {
      final result = computeContainment(
        activity: activity,
        volume: volume,
        mixing: mixing,
        fa: fa,
        fr: fr,
        uncertainty: 1.0,
        rows: [(fraction: 1.0, dac: dac)],
        pif: 1e-4,
      );
      final expected = (activity * fr * fa) / (2000 * volume * mixing * dac);
      expect(result.sumOfFractions, closeTo(expected, expected * 1e-12));
      expect(result.isSufficient, expected <= 0.02);
    });

    test('fractions split the activity between nuclides', () {
      final whole = computeContainment(
        activity: activity,
        volume: volume,
        mixing: mixing,
        fa: fa,
        fr: fr,
        uncertainty: 1.0,
        rows: [(fraction: 1.0, dac: dac)],
      );
      final split = computeContainment(
        activity: activity,
        volume: volume,
        mixing: mixing,
        fa: fa,
        fr: fr,
        uncertainty: 1.0,
        rows: [(fraction: 0.5, dac: dac), (fraction: 0.5, dac: dac)],
      );
      expect(
        split.sumOfFractions,
        closeTo(whole.sumOfFractions!, whole.sumOfFractions! * 1e-12),
      );
    });

    test('not evaluable when a contributing row lacks a DAC', () {
      final result = computeContainment(
        activity: activity,
        volume: volume,
        mixing: mixing,
        fa: fa,
        fr: fr,
        uncertainty: 1.0,
        rows: [(fraction: 0.5, dac: dac), (fraction: 0.5, dac: 0.0)],
      );
      expect(result.sumOfFractions, isNull);
      expect(result.isSufficient, isNull);
      expect(result.bioassayRequired, isNull);
    });

    test('not evaluable with zero contributing rows', () {
      final result = computeContainment(
        activity: activity,
        volume: volume,
        mixing: mixing,
        fa: fa,
        fr: fr,
        uncertainty: 1.0,
        rows: [(fraction: 0.0, dac: dac)],
      );
      expect(result.sumOfFractions, isNull);
      expect(result.isSufficient, isNull);
    });

    test('bioassay threshold = 0.02 / (PIF × Σ fraction/ALI)', () {
      const pif = 1e-4;
      final result = computeContainment(
        activity: activity,
        volume: volume,
        mixing: mixing,
        fa: fa,
        fr: fr,
        uncertainty: 1.0,
        rows: [(fraction: 1.0, dac: dac)],
        pif: pif,
      );
      final ali = dac * 2.4e9;
      final expectedThreshold = 0.02 / (pif * (1.0 / ali));
      expect(
        result.bioassayThreshold,
        closeTo(expectedThreshold, expectedThreshold * 1e-12),
      );
      expect(result.bioassayRequired, activity > expectedThreshold);
    });

    test('bioassay not evaluable when PIF is zero or absent', () {
      for (final pif in <double?>[null, 0.0]) {
        final result = computeContainment(
          activity: activity,
          volume: volume,
          mixing: mixing,
          fa: fa,
          fr: fr,
          uncertainty: 1.0,
          rows: [(fraction: 1.0, dac: dac)],
          pif: pif,
        );
        expect(result.bioassayThreshold, isNull);
        expect(result.bioassayRequired, isNull);
      }
    });
  });
}
