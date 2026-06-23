import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'nuclides.dart';

// --- Unified Data Models ---
class UnifiedConfinementType {
  final String name;
  final double pifC; // C
  final double defaultFa;
  final double minFa;
  final double maxFa;

  const UnifiedConfinementType(
    this.name,
    this.pifC,
    this.defaultFa,
    this.minFa,
    this.maxFa,
  );
}

class PhysicalFormType {
  final String name;
  final double defaultFr;
  final double minFr;
  final double maxFr;

  const PhysicalFormType(this.name, this.defaultFr, this.minFr, this.maxFr);
}

class PifReleaseType {
  final String name;
  final double value; // R
  const PifReleaseType(this.name, this.value);
}

class OccupancyType {
  final String name;
  final double value; // O
  const OccupancyType(this.name, this.value);
}

class DispersibilityType {
  final String name;
  final double value; // D
  const DispersibilityType(this.name, this.value);
}

class SpecialFormType {
  final String name;
  final double value; // S
  const SpecialFormType(this.name, this.value);
}

class NuclideMixEntry {
  final LocalKey key;
  String name;
  double fraction;
  double dac;
  final TextEditingController nameController;

  NuclideMixEntry({required this.name, this.fraction = 0.0, this.dac = 0.0})
    : key = UniqueKey(),
      nameController = TextEditingController(text: name);

  void dispose() {
    nameController.dispose();
  }
}

// --- Constants ---

const List<UnifiedConfinementType> confinementTypes = [
  UnifiedConfinementType(
    'Glovebox, hot cell',
    0.01,
    0.00000001,
    0.00000001,
    0.000001,
  ),
  UnifiedConfinementType(
    'Enhanced fume hood (enclosed)',
    0.1,
    0.001,
    0.001,
    0.01,
  ),
  UnifiedConfinementType('Fume hood, bagged material', 1.0, 0.001, 0.001, 0.01),
  UnifiedConfinementType(
    'Bagged/wrapped material, greenhouses',
    10.0,
    1.0,
    1.0,
    1.0,
  ),
  UnifiedConfinementType(
    'Open benchtop or surface contamination',
    100.0,
    1.0,
    1.0,
    1.0,
  ),
];

const List<PhysicalFormType> physicalFormTypes = [
  PhysicalFormType('Volatiles', 1.0, 1.0, 1.0),
  PhysicalFormType('Powders', 0.1, 0.01, 0.1),
  PhysicalFormType('Liquids', 0.01, 0.001, 0.01),
];

const List<PifReleaseType> pifReleaseTypes = [
  PifReleaseType('Gases, strongly volatile liquids', 1.0),
  PifReleaseType('Nonvolatile powders, somewhat volatile liquids', 0.1),
  PifReleaseType('Liquids', 0.01),
  PifReleaseType('General (large area) contamination', 0.01),
  PifReleaseType('Solids, spotty contamination', 0.001),
  PifReleaseType('Encapsulated material', 0.0),
];

const List<OccupancyType> occupancyTypes = [
  OccupancyType('Annually (1 time)', 1.0),
  OccupancyType('Monthly (few times/yr)', 10.0),
  OccupancyType('Weekly (10s times/yr)', 50.0),
  OccupancyType('Daily (essentially daily)', 250.0),
];

const List<DispersibilityType> dispersibilityTypes = [
  DispersibilityType('No', 1.0),
  DispersibilityType('Yes', 10.0),
];

const List<SpecialFormType> specialFormTypes = [
  SpecialFormType('Normal', 1.0),
  SpecialFormType('Special Form', 0.1),
];

class ContainmentTab extends StatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onLoad;

  const ContainmentTab({super.key, this.onSave, this.onLoad});

  @override
  State<ContainmentTab> createState() => ContainmentTabState();
}

class ContainmentTabState extends State<ContainmentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Controllers
  final TextEditingController totalActivityController = TextEditingController();
  final TextEditingController volumeController = TextEditingController(
    text: '2.0E8',
  );
  final TextEditingController mixingController = TextEditingController(
    text: '0.6',
  );
  final TextEditingController faController = TextEditingController();
  final TextEditingController frController = TextEditingController();
  final TextEditingController uncertaintyController = TextEditingController(
    text: '1',
  );

  // Justification for using the minimum release fraction (HPP 9.5 §8 step 1.3)
  final TextEditingController frJustificationController =
      TextEditingController();

  // Contamination Calculator Controllers
  final TextEditingController contaminationController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  // State
  UnifiedConfinementType? selectedConfinement;
  PhysicalFormType? selectedForm;
  PifReleaseType? selectedPifRelease;
  OccupancyType? selectedOccupancy;
  DispersibilityType? selectedDispersibility;
  SpecialFormType? selectedSpecialForm;

  // Results
  double? calculatedResult;
  bool? isSufficient;

  double? pifResult;
  double? bioassayThreshold;
  bool? bioassayRequired;

  // Source Term State
  List<NuclideMixEntry> sourceTerm = [];
  bool useContaminationInput = false;

  @override
  void initState() {
    super.initState();
    // Defaults
    selectedConfinement = confinementTypes[4]; // Open Bench top
    selectedForm = physicalFormTypes[2]; // Liquids
    selectedPifRelease = pifReleaseTypes[2]; // Liquids (0.01)
    selectedOccupancy = occupancyTypes[1]; // Monthly
    selectedDispersibility = dispersibilityTypes[0]; // No
    selectedSpecialForm = specialFormTypes[0]; // Normal

    faController.text = selectedConfinement!.defaultFa.toString();
    frController.text = selectedForm!.defaultFr.toString();

    // Add initial row with empty search placeholder
    addNuclideRow();
  }

  @override
  void dispose() {
    totalActivityController.dispose();
    volumeController.dispose();
    mixingController.dispose();
    faController.dispose();
    frController.dispose();
    uncertaintyController.dispose();
    contaminationController.dispose();
    areaController.dispose();
    frJustificationController.dispose();
    for (var e in sourceTerm) {
      e.dispose();
    }
    super.dispose();
  }

  void resetState() {
    setState(() {
      for (final e in sourceTerm) {
        e.dispose();
      }
      sourceTerm = [];
      selectedConfinement = confinementTypes[4];
      selectedForm = physicalFormTypes[2];
      selectedPifRelease = pifReleaseTypes[2];
      selectedOccupancy = occupancyTypes[1];
      selectedDispersibility = dispersibilityTypes[0];
      selectedSpecialForm = specialFormTypes[0];
      faController.text = selectedConfinement!.defaultFa.toString();
      frController.text = selectedForm!.defaultFr.toString();
      totalActivityController.clear();
      volumeController.text = '2.0E8';
      mixingController.text = '0.6';
      uncertaintyController.text = '1';
      contaminationController.clear();
      areaController.clear();
      frJustificationController.clear();
      calculatedResult = null;
      isSufficient = null;
      pifResult = null;
      bioassayThreshold = null;
      bioassayRequired = null;
      useContaminationInput = false;
    });
    addNuclideRow();
  }

  /// Pre-selects the confinement type based on the mPIF C factor from the
  /// dose estimate. Only applies when the confinement is still at the default
  /// (Open benchtop) so user-made selections are never overwritten.
  void suggestConfinement(double? mpifC) {
    if (mpifC == null || mpifC <= 0) return;
    // Only auto-set if still at the default (Open benchtop, pifC == 100)
    if (selectedConfinement?.pifC != 100.0) return;
    final match = confinementTypes.where((c) => c.pifC == mpifC).firstOrNull;
    if (match == null) return;
    setState(() {
      selectedConfinement = match;
      faController.text = match.defaultFa.toString();
    });
    calculate();
  }

  /// Pre-fills the source term with nuclide names from the dose estimate.
  /// Only runs if the source term is currently empty or all-blank; won't
  /// overwrite work the user has already entered.
  void populateNuclides(List<String> names) {
    final hasData = sourceTerm.any((e) => e.name.isNotEmpty);
    if (hasData) return;
    if (names.isEmpty) return;

    setState(() {
      for (final e in sourceTerm) {
        e.dispose();
      }
      sourceTerm = names
          .where((n) => NuclideData.dacValues.containsKey(n))
          .map(
            (n) => NuclideMixEntry(
              name: n,
              fraction: names.length == 1 ? 1.0 : 0.0,
              dac: NuclideData.dacValues[n] ?? 0.0,
            ),
          )
          .toList();
      if (sourceTerm.isEmpty) sourceTerm.add(NuclideMixEntry(name: '', fraction: 0.0, dac: 0.0));
    });
    calculate();
  }

  void addNuclideRow() {
    setState(() {
      // Start with empty name so placeholder shows
      sourceTerm.add(NuclideMixEntry(name: '', fraction: 0.0, dac: 0.0));
    });
    calculate();
  }

  void removeNuclideRow(int index) {
    setState(() {
      final removed = sourceTerm.removeAt(index);
      removed.dispose();
    });
    calculate();
  }

  void updateNuclide(int index, String name) {
    if (NuclideData.dacValues.containsKey(name)) {
      setState(() {
        sourceTerm[index].name = name;
        sourceTerm[index].dac = NuclideData.dacValues[name] ?? 0.0;
        if (sourceTerm[index].nameController.text != name) {
          sourceTerm[index].nameController.text = name;
        }
      });
      calculate();
    }
  }

  void updateFraction(int index, String value) {
    final val = double.tryParse(value) ?? 0.0;
    setState(() {
      sourceTerm[index].fraction = val;
    });
    calculate();
  }

  void calculateContamination() {
    final contam = double.tryParse(contaminationController.text) ?? 0.0;
    final areaFt2 = double.tryParse(areaController.text) ?? 0.0;

    if (contam > 0 && areaFt2 > 0) {
      // Convert ft² → cm²: 1 ft² = 929.03 cm²
      final areaCm2 = areaFt2 * 929.03;
      final totalDpm = contam * (areaCm2 / 100.0);
      final totalUci = totalDpm / 2.22e6;
      totalActivityController.text = totalUci.toStringAsExponential(3);
      calculate();
    }
  }

  void calculate() {
    final activity = double.tryParse(totalActivityController.text);
    final volume = double.tryParse(volumeController.text);
    final mixing = double.tryParse(mixingController.text);
    final fa = double.tryParse(faController.text);
    final fr = double.tryParse(frController.text);
    final uncertainty = double.tryParse(uncertaintyController.text) ?? 1.0;

    // --- PIF Calculation (independent of containment inputs) ---
    // PIF = R * C * D * O * S * U * 1e-6
    double? pif;
    if (selectedPifRelease != null &&
        selectedConfinement != null &&
        selectedDispersibility != null &&
        selectedOccupancy != null &&
        selectedSpecialForm != null) {
      final R = selectedPifRelease!.value;
      final C = selectedConfinement!.pifC;
      final D = selectedDispersibility!.value;
      final O = selectedOccupancy!.value;
      final S = selectedSpecialForm!.value;
      final U = uncertainty;
      pif = R * C * D * O * S * U * 1e-6;
    }

    if (activity == null ||
        volume == null ||
        mixing == null ||
        fa == null ||
        fr == null ||
        sourceTerm.isEmpty ||
        selectedConfinement == null ||
        selectedForm == null) {
      setState(() {
        calculatedResult = null;
        isSufficient = null;
        pifResult = pif;
        bioassayRequired = null;
        bioassayThreshold = null;
      });
      return;
    }

    // --- Containment Calculation ---
    double totalResult = 0.0;
    for (final entry in sourceTerm) {
      if (entry.dac <= 0) continue;
      final nuclideActivity = activity * entry.fraction;
      final numerator = nuclideActivity * fr * fa * uncertainty;
      final denominator = 2000 * volume * mixing * entry.dac;
      if (denominator > 0) {
        totalResult += numerator / denominator;
      }
    }

    // --- Bioassay Threshold ---
    double sumRisk = 0.0;
    for (final entry in sourceTerm) {
      if (entry.dac <= 0) continue;
      final ali = entry.dac * 2.4e9;
      if (ali > 0) {
        sumRisk += entry.fraction / ali;
      }
    }

    double threshold = 0.0;
    if (sumRisk > 0 && pif != null && pif > 0) {
      threshold = 0.02 / (pif * sumRisk);
    }

    setState(() {
      calculatedResult = totalResult;
      isSufficient = totalResult <= 0.02;

      pifResult = pif;
      bioassayThreshold = threshold;
      bioassayRequired = activity > threshold;
    });
  }

  void onConfinementChanged(UnifiedConfinementType? v) {
    if (v != null) {
      setState(() {
        selectedConfinement = v;
        faController.text = v.defaultFa.toString();
      });
      calculate();
    }
  }

  void onPhysicalFormChanged(PhysicalFormType? v) {
    if (v != null) {
      setState(() {
        selectedForm = v;
        frController.text = v.defaultFr.toString();
      });
      calculate();
    }
  }

  UnifiedConfinementType? _findConfinementByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final option in confinementTypes) {
      if (option.name == name) return option;
    }
    return null;
  }

  PhysicalFormType? _findPhysicalFormByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final option in physicalFormTypes) {
      if (option.name == name) return option;
    }
    return null;
  }

  PifReleaseType? _findPifReleaseByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final option in pifReleaseTypes) {
      if (option.name == name) return option;
    }
    return null;
  }

  OccupancyType? _findOccupancyByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final option in occupancyTypes) {
      if (option.name == name) return option;
    }
    return null;
  }

  DispersibilityType? _findDispersibilityByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final option in dispersibilityTypes) {
      if (option.name == name) return option;
    }
    return null;
  }

  SpecialFormType? _findSpecialFormByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final option in specialFormTypes) {
      if (option.name == name) return option;
    }
    return null;
  }

  Map<String, dynamic> exportState() => {
    'selectedConfinement': selectedConfinement?.name,
    'selectedForm': selectedForm?.name,
    'selectedPifRelease': selectedPifRelease?.name,
    'selectedOccupancy': selectedOccupancy?.name,
    'selectedDispersibility': selectedDispersibility?.name,
    'selectedSpecialForm': selectedSpecialForm?.name,
    'useContaminationInput': useContaminationInput,
    'controllers': {
      'totalActivity': totalActivityController.text,
      'volume': volumeController.text,
      'mixing': mixingController.text,
      'fa': faController.text,
      'fr': frController.text,
      'uncertainty': uncertaintyController.text,
      'contamination': contaminationController.text,
      'area': areaController.text,
      'frJustification': frJustificationController.text,
    },
    'sourceTerm': sourceTerm
        .map(
          (entry) => {
            'name': entry.name,
            'fraction': entry.fraction,
            'dac': entry.dac,
          },
        )
        .toList(),
  };

  void importState(Map<String, dynamic>? state) {
    if (state == null) return;

    final controllers = state['controllers'] is Map
        ? Map<String, dynamic>.from(state['controllers'])
        : const <String, dynamic>{};
    final importedSourceTerm = (state['sourceTerm'] as List? ?? [])
        .whereType<Map>()
        .map((raw) {
          final entry = Map<String, dynamic>.from(raw);
          final name = (entry['name'] ?? '').toString();
          final resolvedDac =
              NuclideData.dacValues[name] ?? (entry['dac'] ?? 0.0);
          return NuclideMixEntry(
            name: name,
            fraction: (entry['fraction'] ?? 0.0).toDouble(),
            dac: resolvedDac.toDouble(),
          );
        })
        .toList();

    final confinement = _findConfinementByName(
      state['selectedConfinement']?.toString(),
    );
    final form = _findPhysicalFormByName(state['selectedForm']?.toString());

    setState(() {
      selectedConfinement =
          confinement ?? selectedConfinement ?? confinementTypes[4];
      selectedForm = form ?? selectedForm ?? physicalFormTypes[2];
      selectedPifRelease =
          _findPifReleaseByName(state['selectedPifRelease']?.toString()) ??
          selectedPifRelease ??
          pifReleaseTypes[2];
      selectedOccupancy =
          _findOccupancyByName(state['selectedOccupancy']?.toString()) ??
          selectedOccupancy ??
          occupancyTypes[1];
      selectedDispersibility =
          _findDispersibilityByName(
            state['selectedDispersibility']?.toString(),
          ) ??
          selectedDispersibility ??
          dispersibilityTypes[0];
      selectedSpecialForm =
          _findSpecialFormByName(state['selectedSpecialForm']?.toString()) ??
          selectedSpecialForm ??
          specialFormTypes[0];

      useContaminationInput = state['useContaminationInput'] == true;

      totalActivityController.text = (controllers['totalActivity'] ?? '')
          .toString();
      volumeController.text = (controllers['volume'] ?? '2.0E8').toString();
      mixingController.text = (controllers['mixing'] ?? '0.6').toString();
      faController.text =
          (controllers['fa'] ?? selectedConfinement?.defaultFa ?? 1.0)
              .toString();
      frController.text = (controllers['fr'] ?? selectedForm?.defaultFr ?? 1.0)
          .toString();
      uncertaintyController.text = (controllers['uncertainty'] ?? '1')
          .toString();
      contaminationController.text = (controllers['contamination'] ?? '')
          .toString();
      areaController.text = (controllers['area'] ?? '').toString();
      frJustificationController.text =
          (controllers['frJustification'] ?? '').toString();

      for (final entry in sourceTerm) {
        entry.dispose();
      }
      sourceTerm = importedSourceTerm.isEmpty
          ? [NuclideMixEntry(name: '', fraction: 0.0, dac: 0.0)]
          : importedSourceTerm;
    });

    if (useContaminationInput) {
      calculateContamination();
    } else {
      calculate();
    }
  }

  Future<void> printContainmentReport() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 2)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Containment Analysis Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated: ${DateTime.now().toString().substring(0, 19)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Section 1: Confinement Selection
                pw.Text(
                  '1. Confinement Type',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple50,
                    border: pw.Border.all(color: PdfColors.purple200),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    selectedConfinement?.name ?? 'Not selected',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Section 2: Source Term
                pw.Text(
                  '2. Source Term & Activity',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Total Activity: ${totalActivityController.text} µCi',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 8),

                // Nuclide Mixture Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Nuclide',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Fraction',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'DAC (µCi/mL)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    ...sourceTerm
                        .map(
                          (entry) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  entry.name.isEmpty
                                      ? 'Not specified'
                                      : entry.name,
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  entry.fraction.toStringAsFixed(4),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  entry.dac.toStringAsExponential(2),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Section 3: Containment Assessment
                pw.Text(
                  '3. Containment Assessment',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue200, width: 2),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Physical Form: ${selectedForm?.name ?? "Not selected"}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Release Fraction (fr): ${frController.text}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Escape Fraction (fa): ${faController.text}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Room Volume: ${volumeController.text} cm³',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Mixing Factor: ${mixingController.text}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Uncertainty: ${uncertaintyController.text}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Containment Result
                if (calculatedResult != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: isSufficient!
                          ? PdfColors.green50
                          : PdfColors.red50,
                      border: pw.Border.all(
                        color: isSufficient! ? PdfColors.green : PdfColors.red,
                        width: 2,
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isSufficient!
                              ? 'CONTAINMENT SUFFICIENT ✓'
                              : 'CONTAINMENT NOT SUFFICIENT ✗',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: isSufficient!
                                ? PdfColors.green900
                                : PdfColors.red900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Value: ${calculatedResult!.toStringAsExponential(3)} (Limit: 0.02)',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
                pw.SizedBox(height: 20),

                // Section 4: Bioassay Assessment
                pw.Text(
                  '4. Bioassay Assessment',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200, width: 2),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Release Factor (R): ${selectedPifRelease?.name ?? "Not selected"} (${selectedPifRelease?.value ?? 0})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Confinement Factor (C): ${selectedConfinement?.pifC ?? 0}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dispersibility (D): ${selectedDispersibility?.name ?? "Not selected"} (${selectedDispersibility?.value ?? 0})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Occupancy (O): ${selectedOccupancy?.name ?? "Not selected"} (${selectedOccupancy?.value ?? 0})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Special Form (S): ${selectedSpecialForm?.name ?? "Not selected"} (${selectedSpecialForm?.value ?? 0})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Bioassay Results
                if (pifResult != null && bioassayThreshold != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PIF: ${pifResult!.toStringAsExponential(3)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Bioassay Threshold: ${bioassayThreshold!.toStringAsExponential(3)} µCi',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          bioassayRequired!
                              ? 'BIOASSAY REQUIRED ✓'
                              : 'BIOASSAY NOT REQUIRED',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: bioassayRequired!
                                ? PdfColors.orange900
                                : PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'containment_analysis.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
  }

  // ─── Design token shorthands (warm-gray system from main.dart) ───────────
  static const _accent = Color(0xFF2B4B7A);
  static const _accentWash = Color(0xFFEAF0F9);
  static const _ok = Color(0xFF2E7D4F);
  static const _okWash = Color(0xFFE8F2EB);
  static const _warn = Color(0xFFB5711F);
  static const _danger = Color(0xFFB23434);
  static const _dangerWash = Color(0xFFF8E4E2);
  static const _ink1 = Color(0xFF1A1A18);
  static const _ink2 = Color(0xFF3D3C38);
  static const _ink3 = Color(0xFF6B6A63);
  static const _ink4 = Color(0xFF9A9892);
  static const _hairline = Color(0xFFE7E5DE);
  static const _surface3 = Color(0xFFF2F1EC);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2E2D28) : _hairline;
    final surface3 = isDark ? const Color(0xFF2A2A27) : _surface3;
    final ink1 = isDark ? const Color(0xFFEEEDEA) : _ink1;
    final ink2 = isDark ? const Color(0xFFB8B7B0) : _ink2;
    final ink3 = isDark ? const Color(0xFF7A7972) : _ink3;
    final ink4 = isDark ? const Color(0xFF5A5950) : _ink4;

    // ── Helper: section card ─────────────────────────────────────────────
    Widget sectionCard({
      required String sectionNum,
      required String title,
      String? hint,
      required Widget child,
    }) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text(
                    '$sectionNum — $title',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ink1,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(width: 10),
                    Text(hint, style: TextStyle(fontSize: 11, color: ink4)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ],
        ),
      );
    }

    // ── Helper: pill selector row ─────────────────────────────────────────
    Widget pillSelect<T>({
      required List<T> options,
      required T? selected,
      required String Function(T) label,
      required String Function(T) sublabel,
      required void Function(T) onTap,
    }) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options.map((o) {
          final isSelected = selected == o;
          return GestureDetector(
            onTap: () => onTap(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _accent : surface3,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? _accent : cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label(o),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : ink2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    sublabel(o),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white.withOpacity(0.75) : ink4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // ── Derived values for validation ────────────────────────────────────
    final double totalFraction = sourceTerm.fold(0.0, (s, e) => s + e.fraction);
    final bool fractionError = (totalFraction - 1.0).abs() > 0.001;
    final double currentFa = double.tryParse(faController.text) ?? 0.0;
    final bool faError =
        selectedConfinement != null &&
        (currentFa < selectedConfinement!.minFa ||
            currentFa > selectedConfinement!.maxFa);
    final double currentFr = double.tryParse(frController.text) ?? 0.0;
    final bool frError =
        selectedForm != null &&
        (currentFr < selectedForm!.minFr || currentFr > selectedForm!.maxFr);

    // ── Per-nuclide contributions for side panel ─────────────────────────
    final List<({String name, double contrib, double pct})> nuclideContribs =
        [];
    if (calculatedResult != null && calculatedResult! > 0) {
      final fr = double.tryParse(frController.text) ?? 0.0;
      final fa = double.tryParse(faController.text) ?? 0.0;
      final volume = double.tryParse(volumeController.text) ?? 1.0;
      final mixing = double.tryParse(mixingController.text) ?? 1.0;
      final uncertainty = double.tryParse(uncertaintyController.text) ?? 1.0;
      final activity = double.tryParse(totalActivityController.text) ?? 0.0;
      for (final e in sourceTerm) {
        if (e.dac <= 0 || e.fraction <= 0) continue;
        final contrib =
            (activity * e.fraction * fr * fa * uncertainty) /
            (2000 * volume * mixing * e.dac);
        final pct = (contrib / calculatedResult!) * 100;
        nuclideContribs.add((
          name: e.name,
          contrib: contrib,
          pct: pct.clamp(0.0, 100.0),
        ));
      }
    }

    // ════════════════════════════════════════════════════════════════════
    // MAIN LAYOUT — 2-column: scrollable content | fixed 380px side panel
    // ════════════════════════════════════════════════════════════════════
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── LEFT: scrollable form content ──────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentWash,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'CONTAINMENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Confinement adequacy assessment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: ink1,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sum-of-fractions and bioassay threshold per RPP-742',
                            style: TextStyle(fontSize: 12, color: ink4),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onLoad != null)
                      TextButton.icon(
                        onPressed: widget.onLoad,
                        icon: const Icon(Icons.folder_open_outlined, size: 15),
                        label: const Text(
                          'Load',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(foregroundColor: _accent),
                      ),
                    if (widget.onSave != null)
                      TextButton.icon(
                        onPressed: widget.onSave,
                        icon: const Icon(Icons.save_outlined, size: 15),
                        label: const Text(
                          'Save',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(foregroundColor: _accent),
                      ),
                    TextButton.icon(
                      onPressed: printContainmentReport,
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text(
                        'Print',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(foregroundColor: _accent),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── 01 Confinement type ──────────────────────────────────────
                sectionCard(
                  sectionNum: '01',
                  title: 'Confinement type',
                  hint: 'Determines C factor and default fa range',
                  child: pillSelect<UnifiedConfinementType>(
                    options: confinementTypes,
                    selected: selectedConfinement,
                    label: (c) => c.name,
                    sublabel: (c) => 'C=${c.pifC}',
                    onTap: onConfinementChanged,
                  ),
                ),

                // ── 02 Source term & activity ────────────────────────────────
                sectionCard(
                  sectionNum: '02',
                  title: 'Source term & activity',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle
                      Row(
                        children: [
                          _PillToggle(
                            options: const ['Direct activity', 'Contamination'],
                            selectedIndex: useContaminationInput ? 1 : 0,
                            onChanged: (i) => setState(() {
                              useContaminationInput = i == 1;
                            }),
                            accent: _accent,
                            surface3: surface3,
                            cardBorder: cardBorder,
                            ink2: ink2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (useContaminationInput) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: contaminationController,
                                decoration: const InputDecoration(
                                  labelText: 'Contamination (dpm/100cm²)',
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => calculateContamination(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: areaController,
                                decoration: const InputDecoration(
                                  labelText: 'Area (ft²)',
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => calculateContamination(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _accentWash,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: _accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Calculated activity: ${totalActivityController.text} µCi',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        TextField(
                          controller: totalActivityController,
                          decoration: const InputDecoration(
                            labelText: 'Total activity (µCi)',
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => calculate(),
                        ),
                      const SizedBox(height: 16),

                      // Nuclide mixture table
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nuclide mixture',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ink3,
                              letterSpacing: 0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: addNuclideRow,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: surface3,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 13, color: _accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add nuclide',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: cardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: surface3,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'NUCLIDE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ink4,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'FRACTION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ink4,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'DAC (µCi/mL)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ink4,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 36),
                                ],
                              ),
                            ),
                            ...sourceTerm.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return Container(
                                key: item.key,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: cardBorder),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Nuclide autocomplete
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: LayoutBuilder(
                                          builder: (ctx, constraints) => RawAutocomplete<String>(
                                            textEditingController:
                                                item.nameController,
                                            focusNode: FocusNode(),
                                            optionsBuilder: (tv) {
                                              if (NuclideData.dacValues
                                                      .containsKey(tv.text) &&
                                                  item.name != tv.text) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback(
                                                      (_) => updateNuclide(
                                                        idx,
                                                        tv.text,
                                                      ),
                                                    );
                                              }
                                              return tv.text.isEmpty
                                                  ? NuclideData.dacValues.keys
                                                  : NuclideData.dacValues.keys
                                                        .where(
                                                          (o) => o
                                                              .toLowerCase()
                                                              .contains(
                                                                tv.text
                                                                    .toLowerCase(),
                                                              ),
                                                        );
                                            },
                                            onSelected: (s) =>
                                                updateNuclide(idx, s),
                                            fieldViewBuilder:
                                                (
                                                  ctx,
                                                  ctrl,
                                                  fn,
                                                  onSub,
                                                ) => TextFormField(
                                                  controller: ctrl,
                                                  focusNode: fn,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            'Search radionuclide',
                                                        isDense: true,
                                                        border:
                                                            InputBorder.none,
                                                      ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: ink1,
                                                  ),
                                                  onFieldSubmitted: (_) =>
                                                      onSub(),
                                                ),
                                            optionsViewBuilder:
                                                (ctx, onSel, options) => Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Material(
                                                    elevation: 4,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: SizedBox(
                                                      width:
                                                          constraints.maxWidth,
                                                      height: 200,
                                                      child: ListView.builder(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        itemCount:
                                                            options.length,
                                                        itemBuilder: (_, i) {
                                                          final opt = options
                                                              .elementAt(i);
                                                          return ListTile(
                                                            dense: true,
                                                            title: Text(opt),
                                                            subtitle: Text(
                                                              'DAC: ${(NuclideData.dacValues[opt] ?? 0.0).toStringAsExponential(2)}',
                                                            ),
                                                            onTap: () =>
                                                                onSel(opt),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Fraction
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: TextFormField(
                                          initialValue: item.fraction
                                              .toString(),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: ink1,
                                          ),
                                          onChanged: (v) =>
                                              updateFraction(idx, v),
                                        ),
                                      ),
                                    ),
                                    // DAC display
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          item.dac > 0
                                              ? item.dac.toStringAsExponential(
                                                  2,
                                                )
                                              : '—',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            color: ink3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Remove
                                    SizedBox(
                                      width: 36,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          size: 16,
                                          color: _danger,
                                        ),
                                        onPressed: () => removeNuclideRow(idx),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fraction validation
                      if (fractionError)
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: _warn,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Fractions sum to ${totalFraction.toStringAsFixed(3)} (should be 1.000)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _warn,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else if (sourceTerm.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: _ok,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Fractions sum to ${totalFraction.toStringAsFixed(3)} ✓',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _ok,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // ── 03 Release & room parameters ─────────────────────────────
                sectionCard(
                  sectionNum: '03',
                  title: 'Release & room parameters',
                  child: Column(
                    children: [
                      // Physical form pills + fr
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Physical form',
                                  style: TextStyle(fontSize: 11, color: ink3),
                                ),
                                const SizedBox(height: 6),
                                pillSelect<PhysicalFormType>(
                                  options: physicalFormTypes,
                                  selected: selectedForm,
                                  label: (p) => p.name,
                                  sublabel: (p) => 'fr=${p.defaultFr}',
                                  onTap: onPhysicalFormChanged,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Release fraction (fr)',
                                  style: TextStyle(fontSize: 11, color: ink3),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: frController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    errorText: frError ? 'Out of range' : null,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => calculate(),
                                ),
                                if (selectedForm != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Range ${selectedForm!.minFr}–${selectedForm!.maxFr}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ink4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // HPP 9.5 §8 1.3: justify use of minimum fr value
                      if (selectedForm != null &&
                          currentFr <= selectedForm!.minFr &&
                          currentFr > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE6C96A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 15,
                                    color: Color(0xFF9A7000),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Justification required (HPP 9.5 §8 step 1.3)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ink2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You are using the minimum release fraction for this form type. '
                                'Document your justification below.',
                                style: TextStyle(fontSize: 11, color: ink3),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: frJustificationController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Enter justification…',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Escape fraction (fa)',
                                  style: TextStyle(fontSize: 11, color: ink3),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: faController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    errorText: faError ? 'Out of range' : null,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => calculate(),
                                ),
                                if (selectedConfinement != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Range ${selectedConfinement!.minFa}–${selectedConfinement!.maxFa}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: ink4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room volume (cm³)',
                                  style: TextStyle(fontSize: 11, color: ink3),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: volumeController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    helperText: 'Typical: 1×10⁶–1×10⁹ cm³',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => calculate(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mixing factor (λv)',
                                  style: TextStyle(fontSize: 11, color: ink3),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: mixingController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    helperText: 'Typical: 0.1–1.0',
                                    errorText: () {
                                      final v = double.tryParse(
                                        mixingController.text,
                                      );
                                      if (v != null && (v <= 0 || v > 2)) {
                                        return 'Enter a value > 0';
                                      }
                                      return null;
                                    }(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => calculate(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 04 Bioassay PIF factors ───────────────────────────────────
                sectionCard(
                  sectionNum: '04',
                  title: 'Bioassay PIF factors',
                  hint: 'R × C × D × O × S × U × 10⁻⁶',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 680;
                          final children = [
                            _PifFactorField<PifReleaseType>(
                              label: 'Release factor (R)',
                              value: selectedPifRelease,
                              options: pifReleaseTypes,
                              titleFor: (e) => e.name,
                              valueFor: (e) => e.value.toString(),
                              onChanged: (e) {
                                setState(() => selectedPifRelease = e);
                                calculate();
                              },
                              ink2: ink2,
                              ink3: ink3,
                            ),
                            _PifFactorField<OccupancyType>(
                              label: 'Occupancy (O)',
                              value: selectedOccupancy,
                              options: occupancyTypes,
                              titleFor: (e) => e.name,
                              valueFor: (e) => e.value.toString(),
                              onChanged: (e) {
                                setState(() => selectedOccupancy = e);
                                calculate();
                              },
                              ink2: ink2,
                              ink3: ink3,
                            ),
                            _PifFactorField<DispersibilityType>(
                              label: 'Dispersibility (D)',
                              value: selectedDispersibility,
                              options: dispersibilityTypes,
                              titleFor: (e) => e.name,
                              valueFor: (e) => e.value.toString(),
                              onChanged: (e) {
                                setState(() => selectedDispersibility = e);
                                calculate();
                              },
                              ink2: ink2,
                              ink3: ink3,
                            ),
                            _PifFactorField<SpecialFormType>(
                              label: 'Special form (S)',
                              value: selectedSpecialForm,
                              options: specialFormTypes,
                              titleFor: (e) => e.name,
                              valueFor: (e) => e.value.toString(),
                              onChanged: (e) {
                                setState(() => selectedSpecialForm = e);
                                calculate();
                              },
                              ink2: ink2,
                              ink3: ink3,
                            ),
                            _PifNumberField(
                              label: 'Uncertainty (U)',
                              controller: uncertaintyController,
                              onChanged: (_) => calculate(),
                              ink3: ink3,
                            ),
                            _ReadOnlyFactorField(
                              label: 'Confinement (C)',
                              value:
                                  selectedConfinement?.pifC.toString() ?? '—',
                              caption: 'Set by confinement type',
                              surface3: surface3,
                              cardBorder: cardBorder,
                              ink3: ink3,
                            ),
                          ];

                          if (isNarrow) {
                            return Column(
                              children: children
                                  .map(
                                    (child) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: child,
                                    ),
                                  )
                                  .toList(),
                            );
                          }

                          return Column(
                            children: [
                              for (var i = 0; i < children.length; i += 2)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i + 2 >= children.length ? 0 : 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: children[i]),
                                      const SizedBox(width: 12),
                                      Expanded(child: children[i + 1]),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: surface3,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'PIF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ink4,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pifResult != null
                                    ? pifResult!.toStringAsExponential(3)
                                    : 'Complete factors to calculate',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  color: ink2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── RIGHT: live assessment side panel (380px) ──────────────────────
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A18) : const Color(0xFFFAF9F7),
            border: Border(left: BorderSide(color: cardBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: cardBorder)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Assessment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ink1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _ok,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _ok,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Big metric: containment sum-of-fractions ──────────────
                      _BigMetric(
                        label: 'Containment sum-of-fractions',
                        value: calculatedResult != null
                            ? calculatedResult!.toStringAsExponential(2)
                            : '—',
                        badge: calculatedResult == null
                            ? null
                            : (isSufficient! ? 'Sufficient' : 'Insufficient'),
                        badgeOk: isSufficient ?? true,
                        sub: 'Threshold 2×10⁻²',
                        isOk: isSufficient ?? true,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        ink1: ink1,
                        ink3: ink3,
                        ink4: ink4,
                      ),
                      if (calculatedResult != null && isSufficient == false)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _ResultNotice(
                            icon: Icons.warning_amber_rounded,
                            title: '2% DAC limit exceeded',
                            detail:
                                'Containment is insufficient: ${calculatedResult!.toStringAsExponential(2)} > 2.00E-02',
                            color: _danger,
                            wash: _dangerWash,
                            ink: ink1,
                          ),
                        ),
                      const SizedBox(height: 10),

                      // ── Big metric: bioassay ──────────────────────────────────
                      _BigMetric(
                        label: 'Bioassay requirement',
                        value: bioassayRequired == null
                            ? '—'
                            : (bioassayRequired! ? 'Required' : 'Not required'),
                        badge: null,
                        badgeOk: !(bioassayRequired ?? false),
                        sub: bioassayThreshold != null && bioassayThreshold! > 0
                            ? 'Threshold ${bioassayThreshold!.toStringAsExponential(2)} µCi'
                            : 'Threshold —',
                        isOk: !(bioassayRequired ?? false),
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        ink1: ink1,
                        ink3: ink3,
                        ink4: ink4,
                      ),
                      const SizedBox(height: 16),

                      // ── Inputs summary ────────────────────────────────────────
                      Text(
                        'Inputs',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ink4,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'Effective activity',
                        value: totalActivityController.text.isNotEmpty
                            ? '${double.tryParse(totalActivityController.text)?.toStringAsExponential(2) ?? "—"} µCi'
                            : '—',
                        ink1: ink1,
                        ink3: ink3,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _MetricRow(
                        label: 'PIF',
                        value: pifResult != null
                            ? pifResult!.toStringAsExponential(2)
                            : '—',
                        ink1: ink1,
                        ink3: ink3,
                      ),
                      Divider(height: 1, color: cardBorder),
                      _MetricRow(
                        label: 'Σ fraction / ALI',
                        value: calculatedResult != null
                            ? (() {
                                double sumRisk = 0.0;
                                for (final e in sourceTerm) {
                                  if (e.dac <= 0) continue;
                                  final ali = e.dac * 2.4e9;
                                  if (ali > 0) sumRisk += e.fraction / ali;
                                }
                                return sumRisk.toStringAsExponential(2);
                              })()
                            : '—',
                        ink1: ink1,
                        ink3: ink3,
                      ),
                      const SizedBox(height: 16),

                      // ── Per-nuclide contributions ─────────────────────────────
                      if (nuclideContribs.isNotEmpty) ...[
                        Text(
                          'Per-nuclide contribution',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ink4,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...nuclideContribs
                            .map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          n.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ink1,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          n.contrib.toStringAsExponential(2),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ink3,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: n.pct / 100,
                                        minHeight: 4,
                                        backgroundColor: cardBorder,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              (isSufficient ?? true)
                                                  ? _accent
                                                  : _danger,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _PillToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onChanged;
  final Color accent, surface3, cardBorder, ink2;

  const _PillToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.accent,
    required this.surface3,
    required this.cardBorder,
    required this.ink2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface3,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((e) {
          final selected = e.key == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : ink2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PifFactorField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) titleFor;
  final String Function(T) valueFor;
  final void Function(T) onChanged;
  final Color ink2, ink3;

  const _PifFactorField({
    required this.label,
    required this.value,
    required this.options,
    required this.titleFor,
    required this.valueFor,
    required this.onChanged,
    required this.ink2,
    required this.ink3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: ink3)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          style: TextStyle(fontSize: 12, color: ink2),
          selectedItemBuilder: (context) => options.map((option) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${titleFor(option)}  (${valueFor(option)})',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: ink2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          items: options.map((option) {
            return DropdownMenuItem<T>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titleFor(option),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    valueFor(option),
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: ink3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}

class _PifNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color ink3;

  const _PifNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.ink3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: ink3)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: const InputDecoration(isDense: true),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ReadOnlyFactorField extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color surface3, cardBorder, ink3;

  const _ReadOnlyFactorField({
    required this.label,
    required this.value,
    required this.caption,
    required this.surface3,
    required this.cardBorder,
    required this.ink3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: ink3)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surface3,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  caption,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: ink3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: ink3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigMetric extends StatelessWidget {
  final String label, value;
  final String? badge, sub;
  final bool badgeOk, isOk;
  final Color cardBg, cardBorder, ink1, ink3, ink4;

  const _BigMetric({
    required this.label,
    required this.value,
    this.badge,
    this.sub,
    required this.badgeOk,
    required this.isOk,
    required this.cardBg,
    required this.cardBorder,
    required this.ink1,
    required this.ink3,
    required this.ink4,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOk
        ? ContainmentTabState._ok
        : ContainmentTabState._danger;
    final statusWash = isOk
        ? ContainmentTabState._okWash
        : ContainmentTabState._dangerWash;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOk ? cardBg : statusWash,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOk ? cardBorder : statusColor,
          width: isOk ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 11, color: ink4)),
              ),
              if (!isOk) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'FAIL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (!isOk && badge != null) ...[
            const SizedBox(height: 10),
            Text(
              badge!.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: statusColor,
                letterSpacing: 0.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isOk ? 24 : 30,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: isOk ? ink1 : statusColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (badge != null && isOk)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOk
                        ? statusWash
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: isOk ? 11 : 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              if (badge != null && isOk) const SizedBox(width: 8),
              if (sub != null)
                Expanded(
                  child: Text(
                    sub!,
                    style: TextStyle(
                      fontSize: isOk ? 11 : 12,
                      fontWeight: isOk ? FontWeight.w400 : FontWeight.w700,
                      color: isOk ? ink4 : statusColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color, wash, ink;

  const _ResultNotice({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.wash,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label, value;
  final Color ink1, ink3;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.ink1,
    required this.ink3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: ink3)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: ink1,
            ),
          ),
        ],
      ),
    );
  }
}
