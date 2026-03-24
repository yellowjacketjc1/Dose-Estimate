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

  const UnifiedConfinementType(this.name, this.pifC, this.defaultFa, this.minFa, this.maxFa);
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
  UnifiedConfinementType('Glovebox, hot cell', 0.01, 0.00000001, 0.00000001, 0.000001),
  UnifiedConfinementType('Enhanced fume hood (enclosed)', 0.1, 0.001, 0.001, 0.01),
  UnifiedConfinementType('Fume hood, bagged material', 1.0, 0.001, 0.001, 0.01),
  UnifiedConfinementType('Bagged/wrapped material, greenhouses', 10.0, 1.0, 1.0, 1.0),
  UnifiedConfinementType('Open benchtop or surface contamination', 100.0, 1.0, 1.0, 1.0),
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
  const ContainmentTab({super.key});

  @override
  State<ContainmentTab> createState() => ContainmentTabState();
}

class ContainmentTabState extends State<ContainmentTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  // Controllers
  final TextEditingController totalActivityController = TextEditingController();
  final TextEditingController volumeController = TextEditingController(text: '2.0E8');
  final TextEditingController mixingController = TextEditingController(text: '0.6');
  final TextEditingController faController = TextEditingController();
  final TextEditingController frController = TextEditingController();
  final TextEditingController uncertaintyController = TextEditingController(text: '1');
  
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
    for (var e in sourceTerm) {
      e.dispose();
    }
    super.dispose();
  }

  void addNuclideRow() {
    setState(() {
      // Start with empty name so placeholder shows
      sourceTerm.add(NuclideMixEntry(
        name: '', 
        fraction: 0.0, 
        dac: 0.0
      ));
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
    final area = double.tryParse(areaController.text) ?? 0.0;
    
    if (contam > 0 && area > 0) {
      final totalDpm = contam * (area / 100.0);
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

    if (activity == null || volume == null || mixing == null || 
        fa == null || fr == null || sourceTerm.isEmpty ||
        selectedConfinement == null || selectedForm == null ||
        selectedPifRelease == null ||
        selectedOccupancy == null || selectedDispersibility == null || selectedSpecialForm == null) {
      setState(() {
        calculatedResult = null;
        isSufficient = null;
        pifResult = null;
        bioassayRequired = null;
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
    
    // --- PIF Calculation ---
    // PIF = R * C * D * O * S * U * 1e-6
    final R = selectedPifRelease!.value;
    final C = selectedConfinement!.pifC; // Use master selection
    final D = selectedDispersibility!.value;
    final O = selectedOccupancy!.value;
    final S = selectedSpecialForm!.value;
    final U = uncertainty;
    
    final pif = R * C * D * O * S * U * 1e-6;
    
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
    if (sumRisk > 0 && pif > 0) {
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

  Future<void> printContainmentReport() async {
    try {
      final pdf = pw.Document();
      final timestamp = DateTime.now().toIso8601String();
      
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
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated: ${DateTime.now().toString().substring(0, 19)}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Section 1: Confinement Selection
                pw.Text(
                  '1. Confinement Type',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple50,
                    border: pw.Border.all(color: PdfColors.purple200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
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
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Total Activity: ${totalActivityController.text} µCi', style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 8),
                
                // Nuclide Mixture Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Nuclide', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Fraction', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('DAC (µCi/mL)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    // Data rows
                    ...sourceTerm.map((entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(entry.name.isEmpty ? 'Not specified' : entry.name, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(entry.fraction.toStringAsFixed(4), style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(entry.dac.toStringAsExponential(2), style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Section 3: Containment Assessment
                pw.Text(
                  '3. Containment Assessment',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue200, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Physical Form: ${selectedForm?.name ?? "Not selected"}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Release Fraction (fr): ${frController.text}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Escape Fraction (fa): ${faController.text}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Room Volume: ${volumeController.text} cm³', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Mixing Factor: ${mixingController.text}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Uncertainty: ${uncertaintyController.text}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                
                // Containment Result
                if (calculatedResult != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: isSufficient! ? PdfColors.green50 : PdfColors.red50,
                      border: pw.Border.all(
                        color: isSufficient! ? PdfColors.green : PdfColors.red,
                        width: 2,
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isSufficient! ? 'CONTAINMENT SUFFICIENT ✓' : 'CONTAINMENT NOT SUFFICIENT ✗',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: isSufficient! ? PdfColors.green900 : PdfColors.red900,
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
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.purple800),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Release Factor (R): ${selectedPifRelease?.name ?? "Not selected"} (${selectedPifRelease?.value ?? 0})', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Confinement Factor (C): ${selectedConfinement?.pifC ?? 0}', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Dispersibility (D): ${selectedDispersibility?.name ?? "Not selected"} (${selectedDispersibility?.value ?? 0})', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Occupancy (O): ${selectedOccupancy?.name ?? "Not selected"} (${selectedOccupancy?.value ?? 0})', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Special Form (S): ${selectedSpecialForm?.name ?? "Not selected"} (${selectedSpecialForm?.value ?? 0})', style: const pw.TextStyle(fontSize: 10)),
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
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PIF: ${pifResult!.toStringAsExponential(3)}', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text('Bioassay Threshold: ${bioassayThreshold!.toStringAsExponential(3)} µCi', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          bioassayRequired! ? 'BIOASSAY REQUIRED ✓' : 'BIOASSAY NOT REQUIRED',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: bioassayRequired! ? PdfColors.orange900 : PdfColors.green900,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const accent    = Color(0xFF0A84FF);
    const accentAlt = Color(0xFF30D158);
    const warning   = Color(0xFFFF9F0A);
    const danger    = Color(0xFFFF453A);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    Widget card({required String title, required Widget child}) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          const SizedBox(height: 14),
          child,
        ]),
      );
    }

    double totalFraction = sourceTerm.fold(0.0, (sum, e) => sum + e.fraction);
    bool fractionError = (totalFraction - 1.0).abs() > 0.001;
    final currentFa = double.tryParse(faController.text) ?? 0.0;
    final faError = selectedConfinement != null && (currentFa < selectedConfinement!.minFa || currentFa > selectedConfinement!.maxFa);
    final currentFr = double.tryParse(frController.text) ?? 0.0;
    final frError = selectedForm != null && (currentFr < selectedForm!.minFr || currentFr > selectedForm!.maxFr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // 1. Confinement Type
        card(
          title: '1. Confinement Type',
          child: DropdownButtonFormField<UnifiedConfinementType>(
            value: selectedConfinement,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Select confinement type'),
            items: confinementTypes.map((e) => DropdownMenuItem(value: e, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: onConfinementChanged,
          ),
        ),

        // 2. Source Term
        card(
          title: '2. Source Term & Activity',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Toggle
            Row(children: [
              const Text('Input:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: [!useContaminationInput, useContaminationInput],
                onPressed: (i) => setState(() { useContaminationInput = i == 1; }),
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 110),
                selectedColor: Colors.white,
                fillColor: accent,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                borderColor: borderColor,
                selectedBorderColor: accent,
                children: const [Text('Direct Activity', style: TextStyle(fontSize: 12)), Text('Contamination', style: TextStyle(fontSize: 12))],
              ),
            ]),
            const SizedBox(height: 14),
            if (useContaminationInput) ...[
              Row(children: [
                Expanded(child: TextField(controller: contaminationController, decoration: const InputDecoration(labelText: 'Contamination (dpm/100cm²)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => calculateContamination())),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Area (cm²)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => calculateContamination())),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: accent.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 14, color: accent.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text('Calculated Activity: ${totalActivityController.text} µCi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                ]),
              ),
            ] else
              TextField(controller: totalActivityController, decoration: const InputDecoration(labelText: 'Total Activity (µCi)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => calculate()),
            const SizedBox(height: 16),

            // Nuclide table header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Nuclide Mixture', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: addNuclideRow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: accentAlt, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Add Nuclide', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FixedColumnWidth(40)},
              border: TableBorder.all(color: borderColor, borderRadius: BorderRadius.circular(8)),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Nuclide', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('Fraction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('DAC (µCi/mL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                    const SizedBox(),
                  ],
                ),
                ...sourceTerm.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return TableRow(key: item.key, children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: LayoutBuilder(builder: (ctx, constraints) => RawAutocomplete<String>(
                        textEditingController: item.nameController,
                        focusNode: FocusNode(),
                        optionsBuilder: (tv) {
                          if (NuclideData.dacValues.containsKey(tv.text) && item.name != tv.text) {
                            WidgetsBinding.instance.addPostFrameCallback((_) => updateNuclide(idx, tv.text));
                          }
                          return tv.text.isEmpty ? NuclideData.dacValues.keys : NuclideData.dacValues.keys.where((o) => o.toLowerCase().contains(tv.text.toLowerCase()));
                        },
                        onSelected: (s) => updateNuclide(idx, s),
                        fieldViewBuilder: (ctx, ctrl, fn, onSub) => TextFormField(
                          controller: ctrl,
                          focusNode: fn,
                          decoration: const InputDecoration(hintText: 'Search radionuclide'),
                          onFieldSubmitted: (_) => onSub(),
                        ),
                        optionsViewBuilder: (ctx, onSel, options) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: 200,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (_, i) {
                                  final opt = options.elementAt(i);
                                  return ListTile(dense: true, title: Text(opt), subtitle: Text('DAC: ${(NuclideData.dacValues[opt] ?? 0.0).toStringAsExponential(2)}'), onTap: () => onSel(opt));
                                },
                              ),
                            ),
                          ),
                        ),
                      )),
                    ),
                    Padding(padding: const EdgeInsets.all(6), child: TextFormField(
                      initialValue: item.fraction.toString(),
                      decoration: const InputDecoration(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => updateFraction(idx, v),
                    )),
                    Padding(padding: const EdgeInsets.all(10), child: Text(item.dac.toStringAsExponential(2), style: const TextStyle(fontSize: 12))),
                    IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: danger), onPressed: () => removeNuclideRow(idx)),
                  ]);
                }).toList(),
              ],
            ),
            if (fractionError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: warning, size: 14),
                  const SizedBox(width: 6),
                  Text('Fractions sum to ${totalFraction.toStringAsFixed(3)} (should be 1.0)', style: const TextStyle(fontSize: 12, color: warning, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ),

        // 3. Containment Assessment
        card(
          title: '3. Containment Assessment',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: DropdownButtonFormField<PhysicalFormType>(
                value: selectedForm,
                decoration: const InputDecoration(labelText: 'Physical Form'),
                items: physicalFormTypes.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                onChanged: onPhysicalFormChanged,
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: frController,
                  decoration: InputDecoration(labelText: 'Release Frac (fr)', errorText: frError ? 'Out of range' : null),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => calculate(),
                ),
                if (selectedForm != null)
                  Padding(padding: const EdgeInsets.only(top: 3, left: 2), child: Text('Range: ${selectedForm!.minFr} – ${selectedForm!.maxFr}', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600))),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: faController,
                  decoration: InputDecoration(labelText: 'Escape Frac (fa)', errorText: faError ? 'Out of range' : null),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => calculate(),
                ),
                if (selectedConfinement != null)
                  Padding(padding: const EdgeInsets.only(top: 3, left: 2), child: Text('Range: ${selectedConfinement!.minFa} – ${selectedConfinement!.maxFa}', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600))),
              ])),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: volumeController, decoration: const InputDecoration(labelText: 'Room Volume (cm³)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: mixingController, decoration: const InputDecoration(labelText: 'Mixing Factor (λv)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => calculate())),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: uncertaintyController, decoration: const InputDecoration(labelText: 'Uncertainty'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => calculate())),
            ]),
            if (calculatedResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isSufficient! ? accentAlt : danger).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (isSufficient! ? accentAlt : danger).withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(isSufficient! ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: isSufficient! ? accentAlt : danger, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isSufficient! ? 'Containment Sufficient' : 'Containment NOT Sufficient', style: TextStyle(fontWeight: FontWeight.w700, color: isSufficient! ? accentAlt : danger)),
                    Text('Value: ${calculatedResult!.toStringAsExponential(3)} (limit: 0.02)', style: TextStyle(fontSize: 12, color: isSufficient! ? accentAlt : danger)),
                  ])),
                ]),
              ),
            ],
          ]),
        ),

        // 4. Bioassay Assessment
        card(
          title: '4. Bioassay Assessment',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              initialValue: selectedConfinement?.pifC.toString() ?? '',
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Confinement Factor (C) — from selection above'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PifReleaseType>(
              value: selectedPifRelease,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Release Factor (R)'),
              items: pifReleaseTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) { setState(() => selectedPifRelease = v); calculate(); },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DropdownButtonFormField<OccupancyType>(
                value: selectedOccupancy,
                decoration: const InputDecoration(labelText: 'Occupancy (O)'),
                items: occupancyTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { setState(() => selectedOccupancy = v); calculate(); },
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<DispersibilityType>(
                value: selectedDispersibility,
                decoration: const InputDecoration(labelText: 'Dispersibility (D)'),
                items: dispersibilityTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { setState(() => selectedDispersibility = v); calculate(); },
              )),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<SpecialFormType>(
              value: selectedSpecialForm,
              decoration: const InputDecoration(labelText: 'Special Form (S)'),
              items: specialFormTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})'))).toList(),
              onChanged: (v) { setState(() => selectedSpecialForm = v); calculate(); },
            ),
            if (bioassayRequired != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (!bioassayRequired! ? accentAlt : warning).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (!bioassayRequired! ? accentAlt : warning).withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(!bioassayRequired! ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: !bioassayRequired! ? accentAlt : warning, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(bioassayRequired! ? 'Routine Bioassay Required' : 'Routine Bioassay Not Required', style: TextStyle(fontWeight: FontWeight.w700, color: !bioassayRequired! ? accentAlt : warning)),
                    Text('Threshold: ${bioassayThreshold!.toStringAsExponential(3)} µCi', style: TextStyle(fontSize: 12, color: !bioassayRequired! ? accentAlt : warning)),
                  ])),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
