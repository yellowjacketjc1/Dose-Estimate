/// Pure calculation engine for the containment tab.
///
/// Side-effect free and fully parameterized so it can be unit-tested without
/// a widget tree. ContainmentTabState delegates here — do not duplicate this
/// math in UI code.
library;

// ─── Constants ───────────────────────────────────────────────────────────────

/// cm² per ft² (area conversion for the contamination calculator).
const double cm2PerFt2 = 929.03;

/// Disintegrations per minute per µCi.
const double dpmPerMicroCurie = 2.22e6;

/// Working hours per year used in the containment sum-of-fractions.
const double workingHoursPerYear = 2000.0;

/// Annual Limit on Intake conversion: ALI (µCi) = DAC (µCi/mL) × 2.4e9 mL,
/// the volume of air breathed in a working year.
const double aliAirVolumeMl = 2.4e9;

/// Sum-of-fractions limit for both containment sufficiency and the bioassay
/// threshold (2% of the annual limit).
const double sumOfFractionsLimit = 0.02;

// ─── Contamination → activity ────────────────────────────────────────────────

/// Total activity (µCi) from a contamination level (dpm/100 cm²) over an
/// area entered in ft² by default, or cm² when [areaInCm2] is true.
/// Returns null when either input is not positive (not evaluable).
double? activityFromContamination(
  double contamDpmPer100cm2,
  double area, {
  required bool areaInCm2,
}) {
  if (contamDpmPer100cm2 <= 0 || area <= 0) return null;
  final areaCm2 = areaInCm2 ? area : area * cm2PerFt2;
  final totalDpm = contamDpmPer100cm2 * (areaCm2 / 100.0);
  return totalDpm / dpmPerMicroCurie;
}

/// Converts an area between ft² and cm² so the physical area is preserved when
/// the user flips the unit toggle.
///
/// Without this, switching units silently reinterprets the entered number as
/// the other unit — a 929× error in the derived activity.
double convertArea(double area, {required bool toCm2}) =>
    toCm2 ? area * cm2PerFt2 : area / cm2PerFt2;

/// Formats a converted area for display in the entry field.
///
/// Plain decimal at a readable precision, with trailing zeros trimmed, so a
/// converted value doesn't come back as float noise (`3716.1200000000003`) or
/// in exponential form the user then has to retype.
String formatArea(double area) {
  if (!area.isFinite) return '';
  if (area == 0) return '0';
  final abs = area.abs();
  String s;
  if (abs >= 1000) {
    s = area.toStringAsFixed(1);
  } else if (abs >= 1) {
    s = area.toStringAsFixed(3);
  } else {
    // Small ft² values need more decimals to survive a round trip.
    s = area.toStringAsFixed(6);
  }
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

// ─── PIF ─────────────────────────────────────────────────────────────────────

/// PIF = R × C × D × O × S × U × 1e-6.
double computePif({
  required double r,
  required double c,
  required double d,
  required double o,
  required double s,
  required double u,
}) => r * c * d * o * s * u * 1e-6;

// ─── Containment / bioassay ──────────────────────────────────────────────────

/// One source-term row: activity fraction and DAC (µCi/mL).
typedef SourceTermRow = ({double fraction, double dac});

class ContainmentResult {
  /// Sum-of-fractions vs [sumOfFractionsLimit]; null = not evaluable
  /// (no contributing rows, or a row with fraction > 0 lacks a DAC).
  final double? sumOfFractions;

  /// Whether containment is sufficient; null when [sumOfFractions] is null.
  final bool? isSufficient;

  /// Bioassay threshold (µCi); null when not evaluable (no release pathway,
  /// no resolved source term).
  final double? bioassayThreshold;

  /// Whether bioassay is required; null when [bioassayThreshold] is null.
  final bool? bioassayRequired;

  const ContainmentResult({
    this.sumOfFractions,
    this.isSufficient,
    this.bioassayThreshold,
    this.bioassayRequired,
  });
}

/// Containment sum-of-fractions and bioassay threshold.
///
/// A row with a positive fraction but no resolved DAC would silently
/// under-count the sum-of-fractions (non-conservative), so the result is
/// not evaluable until every contributing row has a DAC.
ContainmentResult computeContainment({
  required double activity,
  required double volume,
  required double mixing,
  required double fa,
  required double fr,
  required double uncertainty,
  required List<SourceTermRow> rows,
  double? pif,
}) {
  double totalResult = 0.0;
  bool hasContribution = false;
  bool hasUnresolvedRow = false;
  for (final row in rows) {
    if (row.fraction <= 0) continue;
    if (row.dac <= 0) {
      hasUnresolvedRow = true;
      continue;
    }
    final nuclideActivity = activity * row.fraction;
    final numerator = nuclideActivity * fr * fa * uncertainty;
    final denominator = workingHoursPerYear * volume * mixing * row.dac;
    if (denominator > 0) {
      totalResult += numerator / denominator;
      hasContribution = true;
    } else {
      hasUnresolvedRow = true;
    }
  }
  final containmentEvaluable = hasContribution && !hasUnresolvedRow;

  // Bioassay threshold: 0.02 / (PIF × Σ fraction/ALI)
  double sumRisk = 0.0;
  for (final row in rows) {
    if (row.fraction <= 0 || row.dac <= 0) continue;
    final ali = row.dac * aliAirVolumeMl;
    if (ali > 0) {
      sumRisk += row.fraction / ali;
    }
  }

  // Threshold (and the required/not-required verdict) is only meaningful
  // with a real release pathway (PIF > 0) and a resolved source term.
  double? threshold;
  if (sumRisk > 0 && pif != null && pif > 0 && !hasUnresolvedRow) {
    threshold = sumOfFractionsLimit / (pif * sumRisk);
  }

  return ContainmentResult(
    sumOfFractions: containmentEvaluable ? totalResult : null,
    isSufficient: containmentEvaluable
        ? totalResult <= sumOfFractionsLimit
        : null,
    bioassayThreshold: threshold,
    bioassayRequired: threshold != null ? activity > threshold : null,
  );
}
