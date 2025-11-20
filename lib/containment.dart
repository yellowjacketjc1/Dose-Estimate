import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  State<ContainmentTab> createState() => _ContainmentTabState();
}

class _ContainmentTabState extends State<ContainmentTab> with AutomaticKeepAliveClientMixin {
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    double totalFraction = sourceTerm.fold(0.0, (sum, e) => sum + e.fraction);
    bool fractionError = (totalFraction - 1.0).abs() > 0.001;
    
    final currentFa = double.tryParse(faController.text) ?? 0.0;
    final faError = selectedConfinement != null && (currentFa < selectedConfinement!.minFa || currentFa > selectedConfinement!.maxFa);
    
    final currentFr = double.tryParse(frController.text) ?? 0.0;
    final frError = selectedForm != null && (currentFr < selectedForm!.minFr || currentFr > selectedForm!.maxFr);

    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary);
    final subTitleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Master Confinement Selection ---
          Card(
            elevation: 2,
            color: Colors.purple.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.purple.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Select Confinement Type', style: titleStyle?.copyWith(color: Colors.purple.shade800)),
                  const SizedBox(height: 8),
                  Text('This selection determines the parameters for both Containment and Bioassay calculations.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.purple.shade900)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UnifiedConfinementType>(
                    value: selectedConfinement,
                    decoration: InputDecoration(
                      labelText: 'Confinement Type', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                      filled: true, 
                      fillColor: Colors.white
                    ),
                    isExpanded: true,
                    items: confinementTypes.map((e) => DropdownMenuItem(value: e, child: Text(e.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: onConfinementChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- Source Term & Activity ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2. Source Term & Activity', style: titleStyle),
                  const SizedBox(height: 20),
                  
                  // Activity Input
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Input Method:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            ToggleButtons(
                              isSelected: [!useContaminationInput, useContaminationInput],
                              onPressed: (index) {
                                setState(() {
                                  useContaminationInput = index == 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
                              children: const [
                                Text('Direct Activity'),
                                Text('Contamination'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (useContaminationInput) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: contaminationController,
                                  decoration: const InputDecoration(labelText: 'Contamination (dpm/100cm²)', border: OutlineInputBorder()),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => calculateContamination(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: areaController,
                                  decoration: const InputDecoration(labelText: 'Area (cm²)', border: OutlineInputBorder()),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => calculateContamination(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text('Calculated Total Activity: ${totalActivityController.text} µCi', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: totalActivityController,
                            decoration: const InputDecoration(labelText: 'Total Activity (µCi)', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => calculate(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Source Term Table Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nuclide Mixture', style: subTitleStyle),
                      FilledButton.icon(
                        onPressed: addNuclideRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Nuclide'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FixedColumnWidth(48),
                    },
                    border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: const [
                          Padding(padding: EdgeInsets.all(12.0), child: Text('Nuclide', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(12.0), child: Text('Fraction (0-1)', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(12.0), child: Text('DAC (µCi/mL)', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(),
                        ],
                      ),
                      ...sourceTerm.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return TableRow(
                          key: item.key,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return RawAutocomplete<String>(
                                    textEditingController: item.nameController,
                                    focusNode: FocusNode(),
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (NuclideData.dacValues.containsKey(textEditingValue.text)) {
                                        if (item.name != textEditingValue.text) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            updateNuclide(index, textEditingValue.text);
                                          });
                                        }
                                      }
                                      if (textEditingValue.text == '') {
                                        return NuclideData.dacValues.keys;
                                      }
                                      return NuclideData.dacValues.keys.where((String option) {
                                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                      });
                                    },
                                    onSelected: (String selection) {
                                      updateNuclide(index, selection);
                                    },
                                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                      return TextFormField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), 
                                          border: OutlineInputBorder(),
                                          hintText: 'Search for radionuclide'
                                        ),
                                        onFieldSubmitted: (_) => onFieldSubmitted(),
                                      );
                                    },
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0,
                                          borderRadius: BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            height: 200,
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              itemCount: options.length,
                                              itemBuilder: (context, index) {
                                                final option = options.elementAt(index);
                                                final dac = NuclideData.dacValues[option] ?? 0.0;
                                                return ListTile(
                                                  title: Text(option),
                                                  subtitle: Text('DAC: ${dac.toStringAsExponential(2)}'),
                                                  onTap: () => onSelected(option),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                initialValue: item.fraction.toString(),
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder()),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (v) => updateFraction(index, v),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(item.dac.toStringAsExponential(2), style: const TextStyle(fontSize: 13)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => removeNuclideRow(index),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  if (fractionError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Warning: Fractions sum to ${totalFraction.toStringAsFixed(3)} (should be 1.0)',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- Containment Assessment ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.blue.shade200, width: 2), borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3. Containment Assessment', style: titleStyle?.copyWith(color: Colors.blue.shade800)),
                  const SizedBox(height: 20),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<PhysicalFormType>(
                          value: selectedForm,
                          decoration: const InputDecoration(labelText: 'Physical Form', border: OutlineInputBorder()),
                          items: physicalFormTypes.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                          onChanged: onPhysicalFormChanged,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: frController,
                              decoration: InputDecoration(
                                labelText: 'Release Frac (fr)', 
                                border: const OutlineInputBorder(),
                                errorText: frError ? 'Invalid Range' : null,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => calculate(),
                            ),
                            if (selectedForm != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                                child: Text(
                                  'Range: ${selectedForm!.minFr} - ${selectedForm!.maxFr}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: faController,
                          decoration: InputDecoration(
                            labelText: 'Escape Frac (fa)', 
                            border: const OutlineInputBorder(),
                            errorText: faError ? 'Invalid Range' : null,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => calculate(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: volumeController,
                          decoration: const InputDecoration(labelText: 'Room Volume (cm³)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => calculate(),
                        ),
                      ),
                    ],
                  ),
                  if (selectedConfinement != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                      child: Text(
                        'Allowed fa Range: ${selectedConfinement!.minFa} - ${selectedConfinement!.maxFa} (Based on Confinement Type)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mixingController,
                          decoration: const InputDecoration(labelText: 'Mixing Factor (λv)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => calculate(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: uncertaintyController,
                          decoration: const InputDecoration(labelText: 'Uncertainty', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => calculate(),
                        ),
                      ),
                    ],
                  ),
                  
                  if (calculatedResult != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSufficient! ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSufficient! ? Colors.green : Colors.red),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isSufficient! ? Icons.check_circle : Icons.warning, color: isSufficient! ? Colors.green : Colors.red, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                isSufficient! ? 'Containment SUFFICIENT' : 'Containment NOT SUFFICIENT',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSufficient! ? Colors.green.shade800 : Colors.red.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Value: ${calculatedResult!.toStringAsExponential(3)} (Limit: 0.02)', style: TextStyle(color: isSufficient! ? Colors.green.shade800 : Colors.red.shade800, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- Bioassay Assessment ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.purple.shade200, width: 2), borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('4. Bioassay Assessment', style: titleStyle?.copyWith(color: Colors.purple.shade800)),
                  const SizedBox(height: 20),
                  
                  // Read-only Confinement Factor
                  TextFormField(
                    initialValue: selectedConfinement?.pifC.toString() ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Confinement Factor (C) - From Selection', 
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF3E5F5), // Light purple tint
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<PifReleaseType>(
                    value: selectedPifRelease,
                    decoration: const InputDecoration(labelText: 'Release Factor (R)', border: OutlineInputBorder()),
                    isExpanded: true,
                    items: pifReleaseTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() => selectedPifRelease = v);
                      calculate();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<OccupancyType>(
                          value: selectedOccupancy,
                          decoration: const InputDecoration(labelText: 'Occupancy (O)', border: OutlineInputBorder()),
                          items: occupancyTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})', overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) {
                            setState(() => selectedOccupancy = v);
                            calculate();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<DispersibilityType>(
                          value: selectedDispersibility,
                          decoration: const InputDecoration(labelText: 'Dispersibility (D)', border: OutlineInputBorder()),
                          items: dispersibilityTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})', overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) {
                            setState(() => selectedDispersibility = v);
                            calculate();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<SpecialFormType>(
                    value: selectedSpecialForm,
                    decoration: const InputDecoration(labelText: 'Special Form (S)', border: OutlineInputBorder()),
                    items: specialFormTypes.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.value})'))).toList(),
                    onChanged: (v) {
                      setState(() => selectedSpecialForm = v);
                      calculate();
                    },
                  ),
                  
                  if (bioassayRequired != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: !bioassayRequired! ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !bioassayRequired! ? Colors.green : Colors.orange),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(!bioassayRequired! ? Icons.check_circle : Icons.warning_amber, color: !bioassayRequired! ? Colors.green : Colors.orange, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                bioassayRequired! ? 'Routine Bioassay REQUIRED' : 'Routine Bioassay NOT Required',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: !bioassayRequired! ? Colors.green.shade800 : Colors.orange.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Threshold: ${bioassayThreshold!.toStringAsExponential(3)} µCi', style: TextStyle(color: Colors.grey.shade800, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
