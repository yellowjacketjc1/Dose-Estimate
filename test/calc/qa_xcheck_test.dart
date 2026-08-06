import 'package:flutter_test/flutter_test.dart';
import 'package:dose_dart_version/calc/dose_calculator.dart';
import 'package:dose_dart_version/calc/containment_calculator.dart';
import 'package:dose_dart_version/models/task_data.dart';

TaskData mk({
  int workers = 1,
  double hours = 1,
  double doseRate = 0,
  double pfe = 1.0,
  double pfr = 1.0,
  double mpif = 1e-5,
  List<NuclideEntry>? nuclides,
  List<ExtremityEntry>? extremities,
}) => TaskData(
  workers: workers,
  hours: hours,
  // mPIF = 1e-6*R*C*D*O*S*U ; pick R=mpif/1e-6 with rest 1
  mpifR: mpif / 1e-6,
  mpifC: 1,
  mpifD: 1,
  mpifS: 1,
  mpifU: 1,
  doseRate: doseRate,
  pfe: pfe,
  pfr: pfr,
  nuclides: nuclides,
  extremities: extremities,
);

/// Assert a numeric result matches the QA workbook's hand calculation.
void p(String tc, String label, double got, double exp, {double rel = 0.005}) {
  if (exp == 0) {
    expect(got.abs(), lessThan(1e-12), reason: '$tc $label');
  } else {
    expect(got, closeTo(exp, exp.abs() * rel), reason: '$tc $label');
  }
}

/// Assert a trigger boolean matches the QA workbook's expected result.
void pb(String tc, String label, bool got, bool exp) {
  expect(got, exp, reason: '$tc $label');
}

void main() {
  test('QA workbook cross-check', () {
    // TC-01 mPIF
    p(
      'TC-01',
      'mPIF',
      computeMPIF(
        TaskData(mpifR: 0.1, mpifC: 100, mpifD: 1, mpifS: 1, mpifU: 1),
      ),
      1e-5,
    );
    // TC-02
    p(
      'TC-02',
      'mPIF',
      computeMPIF(
        TaskData(mpifR: 1, mpifC: 0.1, mpifD: 10, mpifS: 0.1, mpifU: 3),
      ),
      3e-7,
    );
    // TC-03 R=0 -> not set
    p(
      'TC-03',
      'mPIF',
      computeMPIF(TaskData(mpifR: 0, mpifC: 100, mpifD: 1, mpifS: 1, mpifU: 1)),
      0,
    );

    // TC-04 3w x 6hr @15
    var t = mk(workers: 3, hours: 6, doseRate: 15);
    var tot = calculateTaskTotals(t);
    p('TC-04', 'personHours', tot['personHours']!, 18);
    p('TC-04', 'collExt', tot['collectiveExternal']!, 270);
    p('TC-04', 'indExt', tot['collectiveExternal']! / 3, 90);

    // TC-05 respirator penalty
    t = mk(workers: 2, hours: 3, doseRate: 5, pfr: 50);
    tot = calculateTaskTotals(t);
    p('TC-05', 'collExt', tot['collectiveExternal']!, 34.5);
    p('TC-05', 'indExt', tot['collectiveExternal']! / 2, 17.25);

    // TC-06 extremity
    t = mk(
      workers: 4,
      extremities: [
        ExtremityEntry(doseRate: 75, time: 2),
        ExtremityEntry(doseRate: 25, time: 1),
      ],
    );
    tot = calculateTaskTotals(t);
    p('TC-06', 'indExtremity', tot['individualExtremity']!, 175);
    p('TC-06', 'collExtremity', tot['collectiveExtremity']!, 700);

    // TC-07 zero workers
    t = mk(workers: 0, hours: 10, doseRate: 10);
    tot = calculateTaskTotals(t);
    p('TC-07', 'personHours', tot['personHours']!, 0);
    p('TC-07', 'indEff', tot['individualEffective']!, 0);
    p('TC-07', 'collExt', tot['collectiveExternal']!, 0);

    // TC-08 Cs-137 5000 dpm, 10w x 1hr
    t = mk(
      workers: 10,
      hours: 1,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 5000)],
    );
    var res = computeNuclideDose(t.nuclides[0], t);
    p('TC-08', 'airConc', res['airConc']!, 2.252e-12);
    p('TC-08', 'dacFrac', res['dacFractionRaw']!, 2.815e-5);
    p(
      'TC-08',
      'collInt',
      calculateTaskTotals(t)['collectiveInternal']!,
      7.038e-4,
    );

    // TC-09 PFE=1000
    t = mk(
      workers: 10,
      hours: 1,
      pfe: 1000,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 5000)],
    );
    res = computeNuclideDose(t.nuclides[0], t);
    p('TC-09', 'dacFracPFE', res['dacFractionEngOnly']!, 2.815e-8);
    p(
      'TC-09',
      'collInt',
      calculateTaskTotals(t)['collectiveInternal']!,
      7.038e-7,
    );

    // TC-10 multi-nuclide
    t = mk(
      workers: 10,
      hours: 1,
      nuclides: [
        NuclideEntry(name: 'Cs-137', contam: 5000),
        NuclideEntry(name: 'Am-241', contam: 5000),
      ],
    );
    tot = calculateTaskTotals(t);
    p('TC-10', 'totalDacFrac', tot['totalDacFraction']!, 4.505e-1);
    p('TC-10', 'collInt', tot['collectiveInternal']!, 1.126e1);

    // TC-11 Other custom DAC
    t = mk(
      workers: 10,
      hours: 1,
      nuclides: [NuclideEntry(name: 'Other', contam: 10000, customDAC: 1e-9)],
    );
    res = computeNuclideDose(t.nuclides[0], t);
    p('TC-11', 'dacFracRaw', res['dacFractionRaw']!, 4.505e-3);
    // Workbook states 1.126E-02 for collective internal, which corresponds to
    // 1 worker; TC-11 shares the 10-worker setup of TC-08..TC-10, so the
    // correct collective value is 10x that. The DAC fraction above (the value
    // the test case is actually verifying) matches the workbook exactly.
    p(
      'TC-11',
      'collInt',
      calculateTaskTotals(t)['collectiveInternal']!,
      1.126e-1,
    );

    // TC-12 zero contam
    t = mk(
      workers: 10,
      hours: 1,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 0)],
    );
    res = computeNuclideDose(t.nuclides[0], t);
    p('TC-12', 'airConc', res['airConc']!, 0);
    p('TC-12', 'dacFrac', res['dacFractionRaw']!, 0);

    // TC-13 Pu-239
    t = mk(
      workers: 1,
      hours: 1,
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 5000)],
    );
    res = computeNuclideDose(t.nuclides[0], t);
    p('TC-13', 'dacFracRaw', res['dacFractionRaw']!, 4.505e-1);
    p('TC-13', 'Pu239 DAC', res['dac']!, 5e-12);

    // TC-14 PFE=1000 PFR=50
    t = mk(
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 5000)],
      pfe: 1000,
      pfr: 50,
    );
    res = computeNuclideDose(t.nuclides[0], t);
    p('TC-14', 'postPFE', res['dacFractionEngOnly']!, 4.505e-4);
    p('TC-14', 'postBoth', res['dacFractionWithBoth']!, 9.009e-6);

    // TC-15 PFE=100000
    t = mk(nuclides: [NuclideEntry(name: 'Pu-239', contam: 5000)], pfe: 100000);
    res = computeNuclideDose(t.nuclides[0], t);
    p('TC-15', 'postPFE', res['dacFractionEngOnly']!, 4.505e-6);

    // TC-16 5w x 2hr @10, Cs-137 5e7
    t = mk(
      workers: 5,
      hours: 2,
      doseRate: 10,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 50000000)],
    );
    tot = calculateTaskTotals(t);
    p('TC-16', 'collEff', tot['collectiveEffective']!, 107.04);
    p('TC-16', 'indEff', tot['individualEffective']!, 21.41);

    // TC-17 two tasks
    var t1 = mk(
      workers: 10,
      hours: 1,
      doseRate: 5,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 50000000)],
    );
    var t2 = mk(
      workers: 5,
      hours: 2,
      doseRate: 2,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 50000000)],
    );
    var g = computeGlobalTriggers([t1, t2]);
    p('TC-17', 'totalColl', g['totalCollectiveDose']! as double, 84.08);
    p(
      'TC-17',
      'totalIndEff',
      g['totalIndividualEffectiveDose']! as double,
      11.11,
    );

    // TC-18 respirator effective
    t = mk(
      workers: 1,
      hours: 4,
      doseRate: 10,
      pfr: 50,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 50000000)],
    );
    tot = calculateTaskTotals(t);
    p('TC-18', 'collEff', tot['collectiveEffective']!, 46.06, rel: 0.01);

    // TC-19 zero workers
    t = mk(
      workers: 0,
      hours: 10,
      doseRate: 100,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 5000)],
    );
    tot = calculateTaskTotals(t);
    p('TC-19', 'indEff', tot['individualEffective']!, 0);
    p('TC-19', 'collEff', tot['collectiveEffective']!, 0);

    // ---- Containment TC-20..24
    var c = computeContainment(
      activity: 50,
      volume: 2e8,
      mixing: 0.6,
      fa: 1,
      fr: 1,
      uncertainty: 1,
      rows: [(fraction: 1.0, dac: 8e-8)],
    );
    p('TC-20', 'SOF', c.sumOfFractions!, 2.604e-3);
    pb('TC-20', 'adequate', c.isSufficient!, true);

    c = computeContainment(
      activity: 384,
      volume: 2e8,
      mixing: 0.6,
      fa: 1,
      fr: 1,
      uncertainty: 1,
      rows: [(fraction: 1.0, dac: 8e-8)],
    );
    p('TC-21', 'SOF', c.sumOfFractions!, 2.0e-2);
    pb('TC-21', 'adequate(boundary)', c.isSufficient!, true);

    c = computeContainment(
      activity: 100,
      volume: 1e5,
      mixing: 0.6,
      fa: 1,
      fr: 0.01,
      uncertainty: 1,
      rows: [(fraction: 1.0, dac: 8e-8)],
    );
    p('TC-22', 'SOF', c.sumOfFractions!, 1.042e-1);
    pb('TC-22', 'inadequate', c.isSufficient!, false);

    c = computeContainment(
      activity: 0.01,
      volume: 2e8,
      mixing: 0.6,
      fa: 1,
      fr: 0.001,
      uncertainty: 1,
      rows: [(fraction: 0.5, dac: 8e-8), (fraction: 0.5, dac: 5e-12)],
    );
    p('TC-23', 'SOF', c.sumOfFractions!, 4.167e-6);

    final act = activityFromContamination(222000, 100, areaInCm2: true);
    p('TC-24', 'activity', act!, 1.0e-1);
    c = computeContainment(
      activity: act,
      volume: 2e8,
      mixing: 0.6,
      fa: 1,
      fr: 1,
      uncertainty: 1,
      rows: [(fraction: 1.0, dac: 8e-8)],
    );
    p('TC-24', 'SOF', c.sumOfFractions!, 5.208e-6);

    // ---- Triggers TC-28..41
    t = mk(
      workers: 1,
      hours: 3,
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 150000)],
    );
    g = computeGlobalTriggers([t]);
    p('TC-28', 'dacHrsWithResp', g['maxDacHrsWithResp']! as double, 40.54);
    pb('TC-28', 'sampling1', g['sampling1'] as bool, true);
    pb('TC-28', 'camsRequired', g['camsRequired'] as bool, true);
    pb('TC-28', 'sampling5', g['sampling5'] as bool, true);
    pb('TC-28', 'alara6 contam', g['alara6'] as bool, true);
    pb('TC-28', 'alara7 internal>100', g['alara7'] as bool, true);
    pb('TC-28', 'alaraReview', g['alaraReview'] as bool, true);
    pb('TC-28', 'airSampling', g['airSampling'] as bool, true);

    // TC-29 PFR only
    g = computeGlobalTriggers([
      mk(workers: 1, hours: 1, doseRate: 0.1, pfr: 50),
    ]);
    pb('TC-29', 'sampling2', g['sampling2'] as bool, true);
    pb('TC-29', 'alaraReview clear', g['alaraReview'] as bool, false);

    // TC-31 Pu-239 750000
    t = mk(
      workers: 1,
      hours: 3,
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 750000)],
    );
    g = computeGlobalTriggers([t]);
    p(
      'TC-31',
      'indInternal',
      calculateTaskTotals(t)['collectiveInternal']!,
      506.76,
      rel: 0.01,
    );
    pb('TC-31', 'sampling4 >500', g['sampling4'] as bool, true);
    pb('TC-31', 'alara5 airborne', g['alara5'] as bool, true);
    pb('TC-31', 'sampling1', g['sampling1'] as bool, true);
    pb('TC-31', 'alara6', g['alara6'] as bool, true);
    pb('TC-31', 'alara7', g['alara7'] as bool, true);

    // TC-32 Pu-239 22200, 1w x 1hr
    t = mk(
      workers: 1,
      hours: 1,
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 22200)],
    );
    g = computeGlobalTriggers([t]);
    p('TC-32', 'dacSpikeEngOnly', g['maxDacSpikeEngOnly']! as double, 2.00);
    p('TC-32', 'dacHrsWithResp', g['maxDacHrsWithResp']! as double, 2.00);
    pb('TC-32', 'sampling5 spike', g['sampling5'] as bool, true);
    pb('TC-32', 'alara6', g['alara6'] as bool, true);
    pb('TC-32', 'sampling1 clear', g['sampling1'] as bool, false);
    pb('TC-32', 'cams clear', g['camsRequired'] as bool, false);

    // TC-34 individual TED
    g = computeGlobalTriggers([mk(workers: 1, hours: 10, doseRate: 54)]);
    p('TC-34', 'indTED', g['totalIndividualEffectiveDose']! as double, 540);
    pb('TC-34', 'alara2', g['alara2'] as bool, true);

    // TC-35 extremity
    g = computeGlobalTriggers([
      mk(workers: 1, extremities: [ExtremityEntry(doseRate: 600, time: 10)]),
    ]);
    p(
      'TC-35',
      'indExtremity',
      g['totalIndividualExtremityDose']! as double,
      6000,
    );
    pb('TC-35', 'alara3', g['alara3'] as bool, true);

    // TC-36 collective
    g = computeGlobalTriggers([mk(workers: 10, hours: 10, doseRate: 8)]);
    p('TC-36', 'collective', g['totalCollectiveDose']! as double, 800);
    pb('TC-36', 'alara4', g['alara4'] as bool, true);

    // TC-37 Pu-239 1.11e6, 3hr, PFR=50
    t = mk(
      workers: 1,
      hours: 3,
      pfr: 50,
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 1110000)],
    );
    g = computeGlobalTriggers([t]);
    p('TC-37', 'dacHrsEngOnly', g['maxDacHrsEngOnly']! as double, 300.0);
    p('TC-37', 'dacHrsWithResp', g['maxDacHrsWithResp']! as double, 6.0);
    pb('TC-37', 'alara5', g['alara5'] as bool, true);
    pb('TC-37', 'alara6', g['alara6'] as bool, true);
    pb('TC-37', 'sampling2', g['sampling2'] as bool, true);
    pb('TC-37', 'sampling5', g['sampling5'] as bool, true);
    pb('TC-37', 'sampling1 clear', g['sampling1'] as bool, false);
    pb('TC-37', 'cams clear', g['camsRequired'] as bool, false);

    // TC-38 Cs-137 contamination ratio
    t = mk(
      workers: 1,
      hours: 1,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 1100000)],
    );
    g = computeGlobalTriggers([t]);
    p('TC-38', 'contamRatio', g['maxContamination']! as double, 1.10);
    pb('TC-38', 'alara6', g['alara6'] as bool, true);

    // TC-39 Pu-239 150000 internal >100
    t = mk(
      workers: 1,
      hours: 3,
      nuclides: [NuclideEntry(name: 'Pu-239', contam: 150000)],
    );
    p(
      'TC-39',
      'indInternal',
      calculateTaskTotals(t)['collectiveInternal']!,
      101.35,
      rel: 0.01,
    );

    // TC-40 dose rate
    g = computeGlobalTriggers([mk(workers: 1, hours: 0.01, doseRate: 10001)]);
    pb('TC-40', 'alara8', g['alara8'] as bool, true);

    // TC-41 all clear
    t = mk(
      workers: 1,
      hours: 2,
      doseRate: 0.5,
      mpif: 1e-7,
      nuclides: [NuclideEntry(name: 'Cs-137', contam: 5000)],
    );
    g = computeGlobalTriggers([t]);
    pb('TC-41', 'alaraReview clear', g['alaraReview'] as bool, false);
    pb('TC-41', 'airSampling clear', g['airSampling'] as bool, false);
    pb('TC-41', 'cams clear', g['camsRequired'] as bool, false);
    p(
      'TC-41',
      'indEff',
      calculateTaskTotals(t)['individualEffective']!,
      1.00,
      rel: 0.02,
    );
  });
}
