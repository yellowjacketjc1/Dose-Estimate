import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/calc/dose_calculator.dart';
import 'package:dose_dart_version/models/task_data.dart';

/// Hand-checkable reference task: mPIF = 1e-6 × 0.1 × 100 × 1 × 1 × 1 × 1
///   = 1e-5.
TaskData referenceTask({
  int workers = 2,
  double hours = 4,
  double doseRate = 0,
  double pfe = 1.0,
  double pfr = 1.0,
  List<NuclideEntry>? nuclides,
  List<ExtremityEntry>? extremities,
}) => TaskData(
  workers: workers,
  hours: hours,
  mpifR: 0.1,
  mpifC: 100,
  mpifD: 1,
  mpifS: 1,
  mpifU: 1,
  doseRate: doseRate,
  pfe: pfe,
  pfr: pfr,
  nuclides: nuclides,
  extremities: extremities,
);

void main() {
  group('computeMPIF', () {
    test('product of factors times 1e-6', () {
      expect(computeMPIF(referenceTask()), closeTo(1e-5, 1e-20));
    });

    test('returns 0 (not set) when any factor is unselected', () {
      expect(computeMPIF(TaskData()), 0.0);
      expect(computeMPIF(TaskData(mpifR: 0.1, mpifC: 100)), 0.0);
    });

    test('custom C sentinel (-1.0) uses mpifCCustom', () {
      final t = TaskData(
        mpifR: 1.0,
        mpifC: -1.0,
        mpifCCustom: 5.0,
        mpifD: 1,
        mpifS: 1,
        mpifU: 2,
      );
      expect(computeMPIF(t), closeTo(1e-6 * 1.0 * 5.0 * 1 * 1 * 2, 1e-20));
    });

    test('custom C sentinel without a value means not set', () {
      final t = TaskData(mpifR: 1.0, mpifC: -1.0, mpifD: 1, mpifS: 1, mpifU: 1);
      expect(computeMPIF(t), 0.0);
    });
  });

  group('getDAC', () {
    test('reads the DAC table', () {
      expect(getDAC(NuclideEntry(name: 'Cs-137')), 8e-8);
      expect(getDAC(NuclideEntry(name: 'Co-60')), 3e-8);
    });

    test('returns 0 when no nuclide selected', () {
      expect(getDAC(NuclideEntry()), 0.0);
    });

    test('Other uses the custom DAC when set, table default otherwise', () {
      expect(getDAC(NuclideEntry(name: 'Other', customDAC: 4e-9)), 4e-9);
      // Without a custom value, 'Other' falls back to the table's
      // conservative alpha/SF default.
      expect(getDAC(NuclideEntry(name: 'Other')), 2e-13);
    });

    test('named-but-unknown nuclide gets the conservative default', () {
      expect(getDAC(NuclideEntry(name: 'Xx-999')), defaultAlphaDac);
    });
  });

  group('getAppendixDBaseLevel', () {
    test('category levels', () {
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'U-nat')), 1000.0);
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'Am-241')), 20.0);
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'Sr-90')), 200.0);
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'H-3')), 10000.0);
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'Cs-137')), 1000.0);
      expect(getAppendixDBaseLevel(NuclideEntry()), 100.0);
    });

    test('every nuclide named in Appendix D keeps its regulation row', () {
      const named = {
        'U-235': 1000.0,
        'U-238': 1000.0,
        'Ra-226': 20.0,
        'Ra-228': 20.0,
        'Th-230': 20.0,
        'Th-228': 20.0,
        'Pa-231': 20.0,
        'Ac-227': 20.0,
        'I-125': 20.0,
        'I-129': 20.0,
        'Pu-239': 20.0,
        'Am-241': 20.0,
        'Cm-244': 20.0,
        'Np-237': 20.0,
        'Th-232': 200.0,
        'Sr-90': 200.0,
        'Ra-223': 200.0,
        'Ra-224': 200.0,
        'U-232': 200.0,
        'I-126': 200.0,
        'I-131': 200.0,
        'I-133': 200.0,
        'H-3': 10000.0,
      };
      named.forEach((name, level) {
        expect(
          getAppendixDBaseLevel(NuclideEntry(name: name)),
          level,
          reason: '$name must map to the $level dpm/100cm² Appendix D row',
        );
      });
    });

    test('alpha emitters never fall through to the beta-gamma row', () {
      // Appendix D's 1,000 dpm row is explicitly "nuclides with decay modes
      // other than alpha emission or spontaneous fission".
      for (final name in alphaEmittersNotNamedInAppendixD) {
        expect(
          getAppendixDBaseLevel(NuclideEntry(name: name)),
          20.0,
          reason: '$name is an alpha emitter and must not use 1,000 dpm',
        );
      }
      // Case-insensitive, matching how names are stored in the DAC table.
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'Po-210')), 20.0);
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'Pb-210')), 20.0);
    });

    test('Other uses the conservative row, not beta-gamma', () {
      expect(getAppendixDBaseLevel(NuclideEntry(name: 'Other')), 20.0);
    });
  });

  group('extremity dosimetry threshold', () {
    test('ring dosimetry threshold is 500 mrem, well below alara3', () {
      // Ring dosimetry is a separate, much lower bar than the 5,000 mrem
      // ALARA extremity review trigger.
      expect(extremityDosimetryThresholdMrem, 500.0);
      expect(
        extremityDosimetryThresholdMrem,
        lessThan(5000.0),
        reason: 'dosimetry must trigger before the ALARA extremity review',
      );
    });

    test('500 mrem individual extremity does not fire alara3', () {
      // The dose that requires a ring must not by itself demand ALARA review.
      final t = referenceTask(
        workers: 1,
        extremities: [ExtremityEntry(doseRate: 250, time: 2)], // 500 mrem
      );
      final totals = calculateTaskTotals(t);
      expect(totals['individualExtremity'], closeTo(500.0, 1e-9));
      expect(computeGlobalTriggers([t])['alara3'], isFalse);
    });
  });

  group('computeNuclideDose', () {
    test('hand-computed chain for Cs-137', () {
      final t = referenceTask(); // mPIF = 1e-5, 2 workers × 4 hr = 8 p-hr
      final n = NuclideEntry(name: 'Cs-137', contam: 1000); // dpm/100cm²
      final res = computeNuclideDose(n, t);

      // airConc = (1000/100) × 1e-5 × (1/100) × (1/2.22e6)
      final expectedAirConc = 10 * 1e-5 / 100 / 2.22e6;
      expect(res['airConc'], closeTo(expectedAirConc, expectedAirConc * 1e-12));

      // dacFractionRaw = airConc / 8e-8
      final expectedDacFrac = expectedAirConc / 8e-8;
      expect(
        res['dacFractionRaw'],
        closeTo(expectedDacFrac, expectedDacFrac * 1e-12),
      );

      // collective = dacFrac × (8/2000) × 5000  (PFE = PFR = 1)
      final expectedCollective = expectedDacFrac * (8 / 2000) * 5000;
      expect(
        res['collective'],
        closeTo(expectedCollective, expectedCollective * 1e-12),
      );
      expect(
        res['individual'],
        closeTo(expectedCollective / 2, expectedCollective * 1e-12),
      );
    });

    test('PFE and PFR divide the DAC fraction and dose', () {
      final t = referenceTask(pfe: 1000, pfr: 50);
      final n = NuclideEntry(name: 'Cs-137', contam: 1000);
      final res = computeNuclideDose(n, t);
      final raw = res['dacFractionRaw']!;
      expect(res['dacFractionEngOnly'], closeTo(raw / 1000, raw * 1e-12));
      expect(res['dacFractionWithBoth'], closeTo(raw / 50000, raw * 1e-12));
      // collective = afterPFE / PFR
      expect(
        res['collective'],
        closeTo(res['afterPFE']! / 50, res['afterPFE']! * 1e-12),
      );
    });

    test('row with no nuclide selected contributes exactly zero', () {
      final t = referenceTask();
      final n = NuclideEntry(contam: 1e9); // huge contamination, no nuclide
      final res = computeNuclideDose(n, t);
      expect(res['collective'], 0.0);
      expect(res['dacFractionRaw'], 0.0);
    });
  });

  group('calculateTaskTotals', () {
    test('external dose = rate × person-hours', () {
      final t = referenceTask(doseRate: 10); // 2 × 4 = 8 person-hours
      final totals = calculateTaskTotals(t);
      expect(totals['personHours'], 8.0);
      expect(totals['collectiveExternal'], closeTo(80.0, 1e-9));
      expect(totals['individualEffective'], closeTo(40.0, 1e-9));
      expect(totals['respiratorPenalty'], 1.0);
    });

    test('respirator penalty multiplies external and internal by 1.15', () {
      final noResp = calculateTaskTotals(referenceTask(doseRate: 10));
      final withResp = calculateTaskTotals(
        referenceTask(doseRate: 10, pfr: 50),
      );
      expect(withResp['respiratorPenalty'], respiratorTimePenalty);
      expect(
        withResp['collectiveExternal'],
        closeTo(noResp['collectiveExternal']! * 1.15, 1e-9),
      );
    });

    test('zero workers yields zero individual dose without dividing by 0', () {
      final totals = calculateTaskTotals(
        referenceTask(workers: 0, doseRate: 10),
      );
      expect(totals['individualEffective'], 0.0);
      expect(totals['collectiveExternal'], 0.0);
    });

    test('extremity entries need positive rate AND time', () {
      final t = referenceTask(
        extremities: [
          ExtremityEntry(doseRate: 100, time: 2), // 200 mrem/person
          ExtremityEntry(doseRate: 100, time: 0), // excluded
        ],
      );
      final totals = calculateTaskTotals(t);
      expect(totals['individualExtremity'], closeTo(200.0, 1e-9));
      expect(totals['collectiveExtremity'], closeTo(400.0, 1e-9));
    });
  });

  group('computeGlobalTriggers', () {
    test('alara2 fires on the sum of individual dose across tasks', () {
      // Three tasks at 200 mrem individual each (1 worker, 20 hr × 10 mrem/hr)
      final tasks = List.generate(
        3,
        (_) => referenceTask(workers: 1, hours: 20, doseRate: 10),
      );
      final triggers = computeGlobalTriggers(tasks);
      expect(triggers['totalIndividualEffectiveDose'], closeTo(600.0, 1e-9));
      expect(triggers['alara2'], isTrue);

      // A single task stays under the limit.
      expect(computeGlobalTriggers([tasks.first])['alara2'], isFalse);
    });

    test('alara4 fires on collective dose > 750 person-mrem', () {
      final t = referenceTask(workers: 10, hours: 10, doseRate: 10); // 1000
      expect(computeGlobalTriggers([t])['alara4'], isTrue);
    });

    test('alara8 fires on dose rate > 10 rem/hr', () {
      expect(
        computeGlobalTriggers([referenceTask(doseRate: 10001)])['alara8'],
        isTrue,
      );
      expect(
        computeGlobalTriggers([referenceTask(doseRate: 9999)])['alara8'],
        isFalse,
      );
    });

    test('rows with no nuclide selected do not fire airborne triggers', () {
      final t = referenceTask(
        nuclides: [NuclideEntry(contam: 1e12)], // no name → excluded
      );
      final triggers = computeGlobalTriggers([t]);
      expect(triggers['alara5'], isFalse);
      expect(triggers['sampling1'], isFalse);
      expect(triggers['maxDacHrsEngOnly'], 0.0);
    });

    test('sampling2 fires when any task prescribes a respirator', () {
      expect(
        computeGlobalTriggers([referenceTask(pfr: 50)])['sampling2'],
        isTrue,
      );
      expect(computeGlobalTriggers([referenceTask()])['sampling2'], isFalse);
    });
  });

  group('computeTriggerReasons', () {
    test('combined-tasks reason appears when no single task exceeds 500', () {
      final tasks = List.generate(
        3,
        (_) => referenceTask(workers: 1, hours: 20, doseRate: 10),
      );
      final reasons = computeTriggerReasons(tasks);
      expect(reasons['alara2'], contains('All tasks combined'));
    });

    test('per-task reason wins when one task exceeds the limit alone', () {
      final reasons = computeTriggerReasons([
        referenceTask(workers: 1, hours: 60, doseRate: 10), // 600 mrem
      ]);
      expect(reasons['alara2'], contains('Task 1'));
    });
  });
}
