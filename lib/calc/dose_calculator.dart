/// Pure calculation engine for the dose estimate.
///
/// Everything in this library is side-effect free and takes its inputs as
/// parameters, so it can be unit-tested without a widget tree. The widgets in
/// main.dart delegate here — do not duplicate any of this math in UI code.
library;

import '../models/task_data.dart';
import '../nuclides.dart';

// ─── Regulatory / conversion constants ───────────────────────────────────────

/// Disintegrations per minute per µCi (2.22e6 dpm/µCi).
const double dpmPerMicroCurie = 2.22e6;

/// Working hours per year used for DAC-hour conversions (10 CFR 835: 2,000 hr).
const double workingHoursPerYear = 2000.0;

/// Committed effective dose (mrem) from one year at 1 DAC (2,000 DAC-hrs).
const double mremPerDacYear = 5000.0;

/// Respirator work-rate penalty applied to time-based doses when PFR > 1.
const double respiratorTimePenalty = 1.15;

/// Individual extremity/skin dose (mrem) at or above which extremity ring
/// dosimetry is required. Distinct from — and far below — the 5,000 mrem
/// ALARA extremity review trigger (alara3).
const double extremityDosimetryThresholdMrem = 500.0;

/// Conservative alpha/spontaneous-fission default DAC (µCi/mL) for named
/// nuclides that are missing from the DAC table. Matches NuclideData.getDac.
const double defaultAlphaDac = 2e-13;

// ─── mPIF ────────────────────────────────────────────────────────────────────

/// mPIF = 1e-6 × R × C × D × O × S × U. Returns 0.0 as a sentinel meaning
/// "not set" when any required factor has not been selected.
double computeMPIF(TaskData t) {
  // Resolve C: -1.0 means custom, use mpifCCustom
  final effectiveC = t.mpifC == -1.0 ? (t.mpifCCustom ?? 0.0) : t.mpifC;
  // require all mPIF factors to be selected (non-zero) before computing
  if (t.mpifR == null ||
      effectiveC <= 0.0 ||
      t.mpifD <= 0.0 ||
      t.mpifS <= 0.0 ||
      t.mpifU <= 0.0) {
    return 0.0; // sentinel meaning 'not set'
  }
  return 1e-6 *
      (t.mpifR!) *
      effectiveC *
      (t.mpifD) *
      (t.mpifO) *
      (t.mpifS) *
      (t.mpifU);
}

// ─── DAC lookup ──────────────────────────────────────────────────────────────

/// DAC value (µCi/mL) for a nuclide row, using the custom DAC for "Other"
/// entries. Returns 0.0 when no nuclide is selected — callers must skip those
/// rows rather than compute with a placeholder DAC.
double getDAC(NuclideEntry n) {
  if (n.name == 'Other' && n.customDAC != null && n.customDAC! > 0) {
    return n.customDAC!;
  }
  if (n.name == null) return 0.0;
  return NuclideData.dacValues[n.name] ?? defaultAlphaDac;
}

/// Alpha- and spontaneous-fission-emitting nuclides in the DAC table that are
/// not matched by the explicit name checks in [getAppendixDBaseLevel].
///
/// 10 CFR 835 Appendix D defines its 1,000 dpm/100 cm² row as "beta-gamma
/// emitters (nuclides with decay modes other than alpha emission or
/// spontaneous fission)", so an alpha emitter must never fall through to it.
/// These are grouped with the transuranics at 20 dpm/100 cm² — the
/// conservative choice, and the row most of them belong to as members of the
/// Ra-226/Ac-227/Th-229 decay chains.
const Set<String> alphaEmittersNotNamedInAppendixD = {
  'GD-148',
  'ND-144',
  'PB-210', // Ra-226 chain
  'PO-208',
  'PO-209',
  'PO-210', // Ra-226 chain
  'RA-225', // Ac-227/Th-229 chain
  'SM-147',
  'TH-227', // Ac-227 chain
  'TH-229',
  'U-230',
  'U-233',
};

/// Appendix D base contamination level (dpm/100cm²) for the removable
/// contamination trigger. The ALARA trigger fires above 1,000 × this level.
double getAppendixDBaseLevel(NuclideEntry n) {
  final name = n.name?.toUpperCase();
  if (name == null) return 100.0; // Default if no nuclide selected

  // "Other" carries a user-supplied DAC and an unknown decay mode; treat it
  // conservatively rather than as a beta-gamma emitter.
  if (name == 'OTHER') return 20.0;

  // U-nat, U-235, U-238, and associated decay products
  if (name.contains('U-NAT') ||
      name == 'U-235' ||
      name == 'U-238' ||
      name.startsWith('U-') &&
          (name.contains('235') ||
              name.contains('238') ||
              name.contains('NAT'))) {
    return 1000.0;
  }

  // Transuranics: Ra-226, Ra-228, Th-230, Th-228, Pa-231, Ac-227, I-125, I-129
  if (name == 'RA-226' ||
      name == 'RA-228' ||
      name == 'TH-230' ||
      name == 'TH-228' ||
      name == 'PA-231' ||
      name == 'AC-227' ||
      name == 'I-125' ||
      name == 'I-129' ||
      name.startsWith('PU-') ||
      name.startsWith('AM-') ||
      name.startsWith('CM-') ||
      name.startsWith('NP-') ||
      name.startsWith('BK-') ||
      name.startsWith('CF-') ||
      name.startsWith('ES-') ||
      name.startsWith('FM-') ||
      alphaEmittersNotNamedInAppendixD.contains(name)) {
    return 20.0;
  }

  // Th-nat, Th-232, Sr-90, Ra-223, Ra-224, U-232, I-126, I-131, I-133
  if (name.contains('TH-NAT') ||
      name == 'TH-232' ||
      name == 'SR-90' ||
      name == 'RA-223' ||
      name == 'RA-224' ||
      name == 'U-232' ||
      name == 'I-126' ||
      name == 'I-131' ||
      name == 'I-133' ||
      name.startsWith('TH-') &&
          (name.contains('232') || name.contains('NAT'))) {
    return 200.0;
  }

  // Tritium and STCs (Special Tritium Compounds)
  if (name == 'H-3' || name == 'TRITIUM' || name.contains('TRITIUM')) {
    return 10000.0;
  }

  // Beta-gamma emitters (default category for most nuclides)
  return 1000.0;
}

// ─── Per-nuclide dose ────────────────────────────────────────────────────────

/// Per-nuclide dose components. The single source of truth — the UI, the
/// task totals, and the trigger logic all consume this.
Map<String, double> computeNuclideDose(NuclideEntry n, TaskData t) {
  final dac = getDAC(n);
  // No nuclide selected — contribute nothing rather than computing with a
  // placeholder DAC (which inflated doses by ~12 orders of magnitude).
  if (dac <= 0.0) {
    return {
      'dac': 0.0,
      'airConc': 0.0,
      'dacFractionRaw': 0.0,
      'dacFractionEngOnly': 0.0,
      'dacFractionWithBoth': 0.0,
      'unprotected': 0.0,
      'afterPFE': 0.0,
      'collective': 0.0,
      'individual': 0.0,
    };
  }
  final mPIF = computeMPIF(t);
  // Airborne concentration (µCi/mL): contamination (dpm/100 cm²) ÷ 100
  // (per cm²) × mPIF × 1/100 × 1/(2.22e6 dpm/µCi), per HPP 9.1.
  final airConc = (n.contam / 100) * mPIF * (1 / 100) * (1 / dpmPerMicroCurie);
  final dacFractionRaw = (airConc / dac);
  final dacFractionEngOnly = dacFractionRaw / (t.pfe == 0.0 ? 1.0 : t.pfe);
  final dacFractionWithBoth =
      dacFractionRaw /
      ((t.pfe == 0.0 ? 1.0 : t.pfe) * (t.pfr == 0.0 ? 1.0 : t.pfr));

  final workers = t.workers;
  final personHours = workers * t.hours;

  // Unprotected collective dose
  final unprotected =
      dacFractionRaw * (personHours / workingHoursPerYear) * mremPerDacYear;
  final afterPFE =
      dacFractionEngOnly * (personHours / workingHoursPerYear) * mremPerDacYear;
  final collective =
      dacFractionEngOnly *
      (personHours / workingHoursPerYear) *
      mremPerDacYear /
      (t.pfr == 0.0 ? 1.0 : t.pfr);

  return {
    'dac': dac,
    'airConc': airConc,
    'dacFractionRaw': dacFractionRaw,
    'dacFractionEngOnly': dacFractionEngOnly,
    'dacFractionWithBoth': dacFractionWithBoth,
    'unprotected': unprotected,
    'afterPFE': afterPFE,
    'collective': collective,
    'individual': workers > 0 ? collective / workers : 0.0,
  };
}

// ─── Task totals ─────────────────────────────────────────────────────────────

/// Aggregate external/internal/extremity totals for one task.
Map<String, double> calculateTaskTotals(TaskData t) {
  final workers = t.workers;
  final hours = t.hours;
  final personHours = workers * hours;
  final mPIF = computeMPIF(t);

  // We'll compute a few different intermediate values for clarity and triggers:
  // - dacFractionRaw: airConc / dac (before any protections)
  // - dacFractionEngOnly: dacFractionRaw / PFE (after engineering controls only)
  // - dacFractionWithResp: dacFractionRaw / (PFE * PFR) used for certain trigger calculations
  double totalDacFraction = 0.0; // current UI field (post-PFE sum)
  double totalDacFractionEngOnly = 0.0; // sum after engineering controls only
  double totalDacFractionWithResp =
      0.0; // sum after both eng + resp (used for some triggers)
  double totalCollectiveInternal = 0.0;
  double totalCollectiveInternalUnprotected = 0.0;
  double totalCollectiveInternalAfterPFE = 0.0;

  for (final n in t.nuclides) {
    final res = computeNuclideDose(n, t);
    final dacFractionEngOnly = res['dacFractionEngOnly'] ?? 0.0;
    final dacFractionWithBoth = res['dacFractionWithBoth'] ?? 0.0;
    final nuclideDoseAfterBoth = res['collective'] ?? 0.0;
    final nuclideDoseUnprotected = res['unprotected'] ?? 0.0;
    final nuclideDoseAfterPFE = res['afterPFE'] ?? 0.0;

    totalDacFraction += dacFractionEngOnly;
    totalDacFractionEngOnly += dacFractionEngOnly;
    totalDacFractionWithResp += dacFractionWithBoth;

    totalCollectiveInternal += nuclideDoseAfterBoth;
    totalCollectiveInternalUnprotected += nuclideDoseUnprotected;
    totalCollectiveInternalAfterPFE += nuclideDoseAfterPFE;
  }

  // Apply 15% respirator penalty if using a respirator (pfr > 1)
  final respiratorPenalty = t.pfr > 1.0 ? respiratorTimePenalty : 1.0;

  final collectiveExternal = t.doseRate * personHours * respiratorPenalty;
  final collectiveInternalWithPenalty =
      totalCollectiveInternal * respiratorPenalty;
  final collectiveEffective =
      collectiveExternal + collectiveInternalWithPenalty;
  final individualEffective = workers > 0 ? collectiveEffective / workers : 0.0;

  // Calculate extremity dose ONLY from manually entered extremity entries
  // Each entry contributes: doseRate (mrem/hr) * time (hr) = total mrem per person
  double totalExtremityDose = 0.0;
  for (final e in t.extremities) {
    // Only include entries with positive dose rate AND time
    if (e.doseRate > 0.0 && e.time > 0.0) {
      totalExtremityDose += e.doseRate * e.time;
    }
  }

  // totalExtremityDose currently holds per-person extremity dose (sum of e.doseRate*e.time)
  final individualExtremity = workers > 0 ? totalExtremityDose : 0.0;
  final collectiveExtremity = totalExtremityDose * workers;

  return {
    'personHours': personHours,
    'mPIF': mPIF,
    'totalDacFraction':
        totalDacFraction, // post-PFE (what the UI previously showed)
    'totalDacFractionEngOnly': totalDacFractionEngOnly,
    'totalDacFractionWithResp': totalDacFractionWithResp,
    'collectiveInternal': collectiveInternalWithPenalty,
    'collectiveInternalUnprotected': totalCollectiveInternalUnprotected,
    'collectiveInternalAfterPFE': totalCollectiveInternalAfterPFE,
    'collectiveExternal': collectiveExternal,
    'collectiveEffective': collectiveEffective,
    'individualEffective': individualEffective,
    'respiratorPenalty': respiratorPenalty,
    // keep backwards compatibility: 'totalExtremityDose' represents the collective extremity
    // so that callers dividing by workers obtain the per-person dose as before.
    'totalExtremityDose': collectiveExtremity,
    'individualExtremity': individualExtremity,
    'collectiveExtremity': collectiveExtremity,
  };
}

// ─── Triggers ────────────────────────────────────────────────────────────────

/// Compute global ALARA and air-sampling triggers across all tasks.
Map<String, dynamic> computeGlobalTriggers(List<TaskData> tasks) {
  double totalIndividualEffectiveDose = 0.0;
  double totalIndividualExtremityDose = 0.0;
  double totalCollectiveDose = 0.0;

  double maxDacHrsWithResp = 0.0;
  double maxDacSpikeEngOnly = 0.0;
  double maxDacHrsEngOnly = 0.0;
  double maxContamination = 0.0;
  double maxDoseRate = 0.0;

  for (final t in tasks) {
    final totals = calculateTaskTotals(t);
    final workers = t.workers;
    final individualExternal = workers > 0
        ? (totals['collectiveExternal']! / workers)
        : 0.0;
    final individualInternal = workers > 0
        ? (totals['collectiveInternal']! / workers)
        : 0.0;
    totalIndividualEffectiveDose += individualExternal + individualInternal;
    totalIndividualExtremityDose += totals['individualExtremity']!;
    totalCollectiveDose += totals['collectiveEffective']!;

    maxDoseRate = maxDoseRate > t.doseRate ? maxDoseRate : t.doseRate;

    double taskDacWithResp = 0.0;
    double taskDacEngOnly = 0.0;

    for (final n in t.nuclides) {
      final res = computeNuclideDose(n, t);
      if ((res['dac'] ?? 0.0) <= 0.0) continue; // no nuclide selected

      taskDacWithResp += res['dacFractionWithBoth'] ?? 0.0;
      taskDacEngOnly += res['dacFractionEngOnly'] ?? 0.0;

      // Calculate contamination ratio using radionuclide-specific Appendix D base level
      final appendixDBase = getAppendixDBaseLevel(n);
      final contamRatio = n.contam / (appendixDBase * 1000);
      maxContamination = maxContamination > contamRatio
          ? maxContamination
          : contamRatio;
      maxDacSpikeEngOnly = maxDacSpikeEngOnly > taskDacEngOnly
          ? maxDacSpikeEngOnly
          : taskDacEngOnly;
    }

    final dacHrsWithResp = taskDacWithResp * t.hours;
    maxDacHrsWithResp = maxDacHrsWithResp > dacHrsWithResp
        ? maxDacHrsWithResp
        : dacHrsWithResp;

    final dacHrsEngOnly = taskDacEngOnly * t.hours;
    maxDacHrsEngOnly = maxDacHrsEngOnly > dacHrsEngOnly
        ? maxDacHrsEngOnly
        : dacHrsEngOnly;
  }

  // derive individual trigger booleans similar to the original HTML logic
  final alara2 = totalIndividualEffectiveDose > 500;
  final alara3 = totalIndividualExtremityDose > 5000;
  final alara4 = totalCollectiveDose > 750;
  final alara5 = maxDacHrsEngOnly > 200 || maxDacSpikeEngOnly > 1000;
  final alara6 = maxContamination > 1;
  final alara8 = maxDoseRate > 10000;

  // calculate internal-only totals for alara7
  double totalInternalDoseOnly = 0.0;
  for (final t in tasks) {
    final totals = calculateTaskTotals(t);
    final workers = t.workers;
    final individualInternal = workers > 0
        ? (totals['collectiveInternal']! / workers)
        : 0.0;
    totalInternalDoseOnly += individualInternal;
  }
  final alara7 = totalInternalDoseOnly > 100;

  // Do not auto-check 'Non-routine or complex work' — user should decide this.
  const alara1 = false;

  final sampling1 = maxDacHrsWithResp > 40;
  final sampling2 = tasks.any((t) => t.pfr > 1);
  const sampling3 = false; // subjective, left for user to check
  final sampling4 = tasks.any((t) {
    final totals = calculateTaskTotals(t);
    final workers = t.workers;
    final individualInternal = workers > 0
        ? (totals['collectiveInternal']! / workers)
        : 0.0;
    return individualInternal > 500;
  });
  final condition1 = (maxDacHrsEngOnly / 40) > 0.3;
  final condition2 = maxDacSpikeEngOnly > 1.0;
  final sampling5 = condition1 || condition2;
  final sampling7 = sampling5;
  const sampling6 =
      false; // subjective job-based triggers left unchecked automatically

  final camsRequired = maxDacHrsWithResp > 40;

  // Aggregate some higher-level flags used by the UI
  final alaraReview =
      alara1 ||
      alara2 ||
      alara3 ||
      alara4 ||
      alara5 ||
      alara6 ||
      alara7 ||
      alara8;
  final airSampling =
      sampling1 ||
      sampling2 ||
      sampling3 ||
      sampling4 ||
      sampling5 ||
      sampling6 ||
      sampling7;

  return {
    'alara1': alara1,
    'alara2': alara2,
    'alara3': alara3,
    'alara4': alara4,
    'alara5': alara5,
    'alara6': alara6,
    'alara7': alara7,
    'alara8': alara8,
    'sampling1': sampling1,
    'sampling2': sampling2,
    'sampling3': sampling3,
    'sampling4': sampling4,
    'sampling5': sampling5,
    'sampling6': sampling6,
    'sampling7': sampling7,
    'camsRequired': camsRequired,
    'alaraReview': alaraReview,
    'airSampling': airSampling,
    'totalIndividualEffectiveDose': totalIndividualEffectiveDose,
    'totalIndividualExtremityDose': totalIndividualExtremityDose,
    'totalCollectiveDose': totalCollectiveDose,
    // Values the PDF trigger-detail table reads; keep in sync with the
    // trigger booleans above.
    'maxDacHrsWithResp': maxDacHrsWithResp,
    'maxDacHrsEngOnly': maxDacHrsEngOnly,
    'maxDacSpikeEngOnly': maxDacSpikeEngOnly,
    'maxContamination': maxContamination,
    'maxDoseRate': maxDoseRate,
    'totalInternalDoseOnly': totalInternalDoseOnly,
  };
}

/// Human-readable reasons for each trigger that fired.
Map<String, String> computeTriggerReasons(List<TaskData> tasks) {
  final reasons = <String, String>{};
  if (tasks.isEmpty) return reasons;

  // Check for sampling1/cams (DAC-hrs > 40 with resp protection taken into account)
  for (var i = 0; i < tasks.length; i++) {
    final t = tasks[i];
    final totals = calculateTaskTotals(t);
    // compute per-nuclide DAC fraction with both protections
    double taskDacWithResp = 0.0;
    double taskDacEngOnly = 0.0;
    for (final n in t.nuclides) {
      final res = computeNuclideDose(n, t);
      if ((res['dac'] ?? 0.0) <= 0.0) continue; // no nuclide selected
      taskDacWithResp += res['dacFractionWithBoth'] ?? 0.0;
      taskDacEngOnly += res['dacFractionEngOnly'] ?? 0.0;
    }
    final dacHrsWithResp = taskDacWithResp * t.hours;
    final dacHrsEngOnly = taskDacEngOnly * t.hours;

    if (dacHrsWithResp > 40) {
      reasons['sampling1'] =
          'Task ${i + 1} (> ${dacHrsWithResp.toStringAsFixed(2)} DAC-hrs)';
      reasons['camsRequired'] =
          'Task ${i + 1} (> ${dacHrsWithResp.toStringAsFixed(2)} DAC-hrs)';
    }
    if (dacHrsEngOnly / 40 > 0.3) {
      reasons['sampling5'] =
          'Task ${i + 1} (avg ${(dacHrsEngOnly / 40).toStringAsFixed(2)} DAC)';
    }
    if (taskDacEngOnly > 1.0) {
      reasons['sampling5'] =
          '${reasons['sampling5'] ?? ''} spike by Task ${i + 1}';
    }

    // alara triggers
    if ((totals['individualEffective'] ?? 0) > 500) {
      reasons['alara2'] = 'Task ${i + 1} individual effective > 500 mrem';
    }
    if (t.workers > 0 &&
        (totals['totalExtremityDose'] ?? 0) / t.workers > 5000) {
      reasons['alara3'] = 'Task ${i + 1} extremity > 5000 mrem';
    }
    if ((totals['collectiveEffective'] ?? 0) > 750) {
      reasons['alara4'] = 'Task ${i + 1} collective > 750 mrem';
    }
    if (taskDacEngOnly * t.hours > 200) {
      reasons['alara5'] = 'Task ${i + 1} DAC-hrs eng-only > 200';
    }
    if (t.nuclides.any(
      (n) => getDAC(n) > 0 && n.contam / (getAppendixDBaseLevel(n) * 1000) > 1,
    )) {
      reasons['alara6'] = 'Task ${i + 1} contamination > 1000x Appendix D';
    }
    if (t.workers > 0 &&
        (totals['collectiveInternal'] ?? 0) / t.workers > 100) {
      reasons['alara7'] = 'Task ${i + 1} internal > 100 mrem';
    }
    if (t.doseRate > 10000) {
      reasons['alara8'] = 'Task ${i + 1} dose rate > 10 rem/hr';
    }
  }

  // alara2/3/7 fire on the summed individual dose across all tasks (same
  // basis as computeGlobalTriggers), so add a combined reason when no
  // single task exceeded the limit on its own.
  double sumIndEff = 0.0;
  double sumIndExt = 0.0;
  double sumIndInt = 0.0;
  for (final t in tasks) {
    final totals = calculateTaskTotals(t);
    sumIndEff += totals['individualEffective'] ?? 0.0;
    sumIndExt += totals['individualExtremity'] ?? 0.0;
    if (t.workers > 0) {
      sumIndInt += (totals['collectiveInternal'] ?? 0.0) / t.workers;
    }
  }
  if (sumIndEff > 500) {
    reasons.putIfAbsent(
      'alara2',
      () =>
          'All tasks combined: individual effective ${sumIndEff.toStringAsFixed(0)} mrem > 500',
    );
  }
  if (sumIndExt > 5000) {
    reasons.putIfAbsent(
      'alara3',
      () =>
          'All tasks combined: extremity ${sumIndExt.toStringAsFixed(0)} mrem > 5000',
    );
  }
  if (sumIndInt > 100) {
    reasons.putIfAbsent(
      'alara7',
      () =>
          'All tasks combined: internal ${sumIndInt.toStringAsFixed(0)} mrem > 100',
    );
  }

  return reasons;
}
