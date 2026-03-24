import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'containment.dart';
import 'nuclides.dart';

void main() {
  runApp(const DoseEstimateApp());
}

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kAccent    = Color(0xFF0A84FF); // iOS-style blue
const _kAccentAlt = Color(0xFF30D158); // green for positive/pass
const _kWarning   = Color(0xFFFF9F0A); // amber for warnings
const _kDanger    = Color(0xFFFF453A); // red for triggered alerts

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: _kAccent,
    brightness: brightness,
  ).copyWith(
    primary: _kAccent,
    secondary: _kAccentAlt,
    error: _kDanger,
    surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    // ignore: deprecated_member_use
    background: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: -0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kAccent, width: 1.5),
      ),
      labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      isDense: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _kAccent),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
      space: 1,
      thickness: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _kAccent : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _kAccent : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)),
    ),
  );
}

class DoseEstimateApp extends StatefulWidget {
  const DoseEstimateApp({super.key});

  @override
  State<DoseEstimateApp> createState() => _DoseEstimateAppState();
}

class _DoseEstimateAppState extends State<DoseEstimateApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPP-742 Dose Estimate',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: MainScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const MainScreen({super.key, required this.onToggleTheme, required this.themeMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<DoseEstimateScreenState> _doseEstimateKey = GlobalKey();
  final GlobalKey<ContainmentTabState> _containmentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { setState(() {}); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RPP-742 Dose Assessment'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Column(
            children: [
              Divider(height: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _SegmentedTabBar(
                  controller: _tabController,
                  labels: const ['Dose Estimate', 'Containment Analysis'],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_tabController.index == 0) ...[
            IconButton(
              tooltip: 'Save',
              onPressed: () => _doseEstimateKey.currentState?.saveToFile(),
              icon: const Icon(Icons.save_outlined),
            ),
            IconButton(
              tooltip: 'Load',
              onPressed: () => _doseEstimateKey.currentState?.loadFromFile(),
              icon: const Icon(Icons.folder_open_outlined),
            ),
            IconButton(
              tooltip: 'Print report',
              onPressed: () => _doseEstimateKey.currentState?.printSummaryReport(),
              icon: const Icon(Icons.print_outlined),
            ),
            IconButton(
              tooltip: 'Debug info',
              onPressed: () => _doseEstimateKey.currentState?.showDebugInfo(),
              icon: const Icon(Icons.bug_report_outlined),
            ),
          ],
          if (_tabController.index == 1)
            IconButton(
              tooltip: 'Print containment report',
              onPressed: () => _containmentKey.currentState?.printContainmentReport(),
              icon: const Icon(Icons.print_outlined),
            ),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DoseEstimateScreen(key: _doseEstimateKey),
          ContainmentTab(key: _containmentKey),
        ],
      ),
    );
  }
}

// ─── Shared helper widgets ────────────────────────────────────────────────────

/// Flat card with subtle background
class _InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _InfoCard({required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
      ),
      child: child,
    );
  }
}

/// Small statistic cell used inside cards
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color color;
  const _MiniStat({required this.label, required this.value, this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        if (unit != null)
          Text(unit!, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
      ]),
    );
  }
}

/// Bold section header
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2));
  }
}

/// Status badge for ALARA / Air Sampling / CAMs
class _StatusBadge extends StatelessWidget {
  final String label;
  final bool triggered;
  const _StatusBadge({required this.label, required this.triggered});

  @override
  Widget build(BuildContext context) {
    final color = triggered ? _kDanger : _kAccentAlt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 4),
        Text(triggered ? 'Required' : 'Clear', style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
      ]),
    );
  }
}

/// Info note (replaces old blue info boxes)
class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 15, color: _kAccent.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65), fontStyle: FontStyle.italic))),
      ]),
    );
  }
}

/// Collapsible section card
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;
  const _CollapsibleSection({required this.title, required this.initiallyExpanded, required this.onExpansionChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [child],
        ),
      ),
    );
  }
}

/// A single trigger checkbox row
class _TriggerRow extends StatelessWidget {
  final String triggerKey;
  final String label;
  final bool active;
  final String? reason;
  final String? justification;
  final ValueChanged<bool?> onChanged;
  const _TriggerRow({
    required this.triggerKey, required this.label, required this.active,
    this.reason, this.justification, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CheckboxListTile(
        value: active,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: TextStyle(fontSize: 13, color: active ? _kDanger : Theme.of(context).colorScheme.onSurface)),
        activeColor: _kDanger,
      ),
      if (reason != null)
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: 4),
          child: Text(reason!, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
        ),
      if (justification != null)
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: 6),
          child: Text('Override: $justification', style: const TextStyle(fontSize: 11, color: _kWarning, fontStyle: FontStyle.italic)),
        ),
      Divider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
    ]);
  }
}

/// iOS-style segmented control tab bar
class _SegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  const _SegmentedTabBar({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: List.generate(labels.length, (i) {
              final selected = controller.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class DoseEstimateScreen extends StatefulWidget {
  const DoseEstimateScreen({super.key});

  @override
  State<DoseEstimateScreen> createState() => DoseEstimateScreenState();
}

class TaskData {

  String title;
  String location;
  int workers;
  double hours;
  double mpifR;
  double mpifC;
  double mpifD;
  double mpifS;
  double mpifU;
  double doseRate;
  double pfr;
  double pfe;
  List<NuclideEntry> nuclides;
  List<ExtremityEntry> extremities;

  // Track expansion state for each section
  Map<String, bool> sectionExpansionStates;

  // Persistent controllers so cursor/selection behavior remains stable
  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController workersController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController mpifDController = TextEditingController();
  final TextEditingController mpifSController = TextEditingController();
  final TextEditingController mpifUController = TextEditingController();
  final TextEditingController doseRateController = TextEditingController();

  TaskData({
    this.title = '',
    this.location = '',
    this.workers = 1,
    this.hours = 1.0,
    // Use 0.0 to indicate 'not selected' for all mPIF inputs. UI will require selection before computing mPIF.
    this.mpifR = 0.0,
    this.mpifC = 0.0,
    this.mpifD = 0.0,
    this.mpifS = 0.0,
    this.mpifU = 0.0,
    this.doseRate = 0.0,
    this.pfr = 1.0,
    this.pfe = 1.0,
    List<NuclideEntry>? nuclides,
    List<ExtremityEntry>? extremities,
    Map<String, bool>? sectionExpansionStates,
  })  : nuclides = nuclides ?? [NuclideEntry()],
        extremities = extremities ?? [],
        sectionExpansionStates = sectionExpansionStates ?? {
          'timeEstimation': true,
          'mpifCalculation': false,
          'externalDose': false,
          'extremityDose': false,
          'protectionFactors': false,
          'internalDose': false,
        } {
  titleController.text = title;
  locationController.text = location;
  workersController.text = workers.toString();
  hoursController.text = hours.toString();
  // Leave mPIF field controllers empty when value is 0.0 (not selected)
  mpifDController.text = mpifD > 0.0 ? mpifD.toString() : '';
  mpifSController.text = mpifS > 0.0 ? mpifS.toString() : '';
  mpifUController.text = mpifU > 0.0 ? mpifU.toString() : '';
  doseRateController.text = doseRate.toString();

    // keep model fields in sync with controllers
    titleController.addListener(() {
      title = titleController.text;
    });
    locationController.addListener(() {
      location = locationController.text;
    });
    workersController.addListener(() {
      workers = int.tryParse(workersController.text) ?? 1;
    });
    hoursController.addListener(() {
      hours = double.tryParse(hoursController.text) ?? 0.0;
    });
    mpifDController.addListener(() {
      mpifD = double.tryParse(mpifDController.text) ?? 0.0;
    });
    mpifSController.addListener(() {
      mpifS = double.tryParse(mpifSController.text) ?? 0.0;
    });
    mpifUController.addListener(() {
      mpifU = double.tryParse(mpifUController.text) ?? 0.0;
    });
    doseRateController.addListener(() {
      doseRate = double.tryParse(doseRateController.text) ?? 0.0;
    });
  }

  void disposeControllers() {
    titleController.dispose();
    titleFocusNode.dispose();
    locationController.dispose();
    workersController.dispose();
    hoursController.dispose();
    mpifDController.dispose();
    mpifSController.dispose();
    mpifUController.dispose();
    doseRateController.dispose();
    for (final n in nuclides) {
      n.disposeControllers();
    }
    for (final e in extremities) {
      e.disposeControllers();
    }
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'location': location,
        'workers': workers,
        'hours': hours,
        'mpifR': mpifR,
        'mpifC': mpifC,
        'mpifD': mpifD,
        'mpifS': mpifS,
        'mpifU': mpifU,
        'doseRate': doseRate,
        'pfr': pfr,
        'pfe': pfe,
        'nuclides': nuclides.map((n) => n.toJson()).toList(),
        'extremities': extremities.map((e) => e.toJson()).toList(),
        'sectionExpansionStates': sectionExpansionStates,
      };

  static TaskData fromJson(Map<String, dynamic> j) {
    final rawNuclides = (j['nuclides'] as List?)?.map((e) => NuclideEntry.fromJson(e)).toList();
    final rawExtremities = (j['extremities'] as List?)?.map((e) => ExtremityEntry.fromJson(e)).toList();
    return TaskData(
      title: j['title'] ?? '',
      location: j['location'] ?? '',
      workers: j['workers'] ?? 1,
      hours: (j['hours'] ?? 1).toDouble(),
      // Use 0.0 when values are missing so mPIF remains "not set" until user selects factors.
      mpifR: (j['mpifR'] ?? 0).toDouble(),
      mpifC: (j['mpifC'] ?? 0).toDouble(),
      mpifD: (j['mpifD'] ?? 0).toDouble(),
      mpifS: (j['mpifS'] ?? 0).toDouble(),
      mpifU: (j['mpifU'] ?? 0).toDouble(),
      doseRate: (j['doseRate'] ?? 0).toDouble(),
      pfr: (j['pfr'] ?? 1).toDouble(),
      pfe: (j['pfe'] ?? 1).toDouble(),
      nuclides: (rawNuclides == null || rawNuclides.isEmpty) ? null : rawNuclides,
      extremities: rawExtremities ?? const <ExtremityEntry>[],
      sectionExpansionStates: j['sectionExpansionStates'] != null
        ? Map<String, bool>.from(j['sectionExpansionStates'])
        : null,
    );
  }
}

class NuclideEntry {
  String? name;
  double contam; // dpm/100cm2
  double? customDAC; // µCi/mL - only used when name is "Other"
  final TextEditingController contamController = TextEditingController();
  final TextEditingController dacController = TextEditingController();

  NuclideEntry({this.name, this.contam = 0.0, this.customDAC}) {
    contamController.text = contam.toString();
    contamController.addListener(() {
      final parsed = double.tryParse(contamController.text);
      if (parsed != null) {
        contam = parsed;
      }
    });

    // Initialize DAC controller for "Other" nuclides
    if (name == 'Other' && customDAC != null) {
      dacController.text = customDAC!.toStringAsExponential(2);
    }
    dacController.addListener(() {
      if (name == 'Other') {
        final parsed = double.tryParse(dacController.text);
        if (parsed != null && parsed > 0) {
          customDAC = parsed;
        }
      }
    });
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'contam': contam,
    if (name == 'Other' && customDAC != null) 'customDAC': customDAC
  };

  static NuclideEntry fromJson(Map<String, dynamic> j) => NuclideEntry(
    name: j['name'],
    contam: (j['contam'] ?? 0).toDouble(),
    customDAC: j['customDAC']?.toDouble()
  );

  void disposeControllers() {
    contamController.dispose();
    dacController.dispose();
  }
}


class ExtremityEntry {
  String? nuclide;
  double doseRate;
  double time;
  double contam;
  final TextEditingController doseRateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController contamController = TextEditingController();

  ExtremityEntry({this.nuclide, this.doseRate = 0.0, this.time = 0.0, this.contam = 0.0}) {
    // Initialize controllers with the current values
    doseRateController.text = doseRate.toString();
    timeController.text = time.toString();
    contamController.text = contam.toString();

    // Keep model fields in sync with controllers
    doseRateController.addListener(() {
      doseRate = double.tryParse(doseRateController.text) ?? 0.0;
    });
    timeController.addListener(() {
      time = double.tryParse(timeController.text) ?? 0.0;
    });
    contamController.addListener(() {
      contam = double.tryParse(contamController.text) ?? 0.0;
    });
  }

  Map<String, dynamic> toJson() => {'nuclide': nuclide, 'doseRate': doseRate, 'time': time, 'contam': contam};
  static ExtremityEntry fromJson(Map<String, dynamic> j) => ExtremityEntry(
    nuclide: j['nuclide'], 
    doseRate: (j['doseRate'] ?? 0).toDouble(), 
    time: (j['time'] ?? 0).toDouble(),
    contam: (j['contam'] ?? 0).toDouble()
  );

  void disposeControllers() {
    doseRateController.dispose();
    timeController.dispose();
    contamController.dispose();
  }
}

// Top-level Decoration that paints a rounded gradient 'frosted' indicator for tabs.
class GradientTabIndicator extends Decoration {
  final double radius;
  final Gradient gradient;
  final double blurRadius;
  /// blurRadius is used only for the shadow; the main pill is painted sharply so it stands out.
  const GradientTabIndicator({this.radius = 12.0, required this.gradient, this.blurRadius = 8.0});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GradientPainter(radius: radius, gradient: gradient, blurRadius: blurRadius);
}

class _GradientPainter extends BoxPainter {
  final double radius;
  final Gradient gradient;
  final double blurRadius;

  _GradientPainter({required this.radius, required this.gradient, required this.blurRadius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    if (size.isEmpty) return;
    final rect = offset & size;

    // Make the pill slightly larger than the provided rect so it reads as a 'pill' behind the label.
    const extraHorizontal = 8.0;
    const extraVertical = 6.0;
    final paddedRect = Rect.fromLTRB(rect.left - extraHorizontal, rect.top - extraVertical, rect.right + extraHorizontal, rect.bottom + extraVertical);
    final rrect = RRect.fromRectAndRadius(paddedRect, Radius.circular(radius));

    // Draw a subtle shadow first (use sigma ~= blurRadius / 2)
    final shadowSigma = (blurRadius / 2.0).clamp(0.0, 30.0);
    final shadowPaint = Paint()
  ..color = Color.fromRGBO(0, 0, 0, 0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowSigma);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

    // Fill the pill with the provided gradient (sharp edges so it stands out).
    final fillPaint = Paint()..shader = gradient.createShader(paddedRect);
    canvas.drawRRect(rrect, fillPaint);
  }
}
/// Pill-style inner tab bar for Summary / Task tabs
class _InnerTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  const _InnerTabBar({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            final selected = controller.index == i;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? _kAccent
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddTaskButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _kAccentAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text('Add Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class DoseEstimateScreenState extends State<DoseEstimateScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  // dacValues moved to NuclideData class in nuclides.dart

  final Map<String, double> releaseFactors = const {
    'Gases, volatile liquids (1.0)': 1.0,
    'Nonvolatile powders, some liquids (0.1)': 0.1,
    'Liquids, large area contamination (0.01)': 0.01,
    'Solids, spotty contamination (0.001)': 0.001,
    'Encapsulated material (0)': 0
  };

  final Map<String, double> confinementFactors = const {
    'None - Open bench (100)': 100,
    'Bagged material (10)': 10,
    'Fume Hood (1.0)': 1.0,
    'Enhanced Fume Hood (0.1)': 0.1,
    'Glovebox, Hot Cell (0.01)': 0.01
  };

  List<TaskData> tasks = [];
  TextEditingController workOrderController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  // user overrides for trigger checkboxes
  Map<String, bool> triggerOverrides = {};
  // justifications for overrides
  Map<String, String> overrideJustifications = {};

  // Track expansion state for summary page sections
  Map<String, bool> summaryExpansionStates = {
    'internalDose': false,
  };

  late TabController tabController;

  @override
  void initState() {
    super.initState();
    // Start with 1 tab: Summary (Containment moved to main tabs)
    tabController = TabController(length: 1, vsync: this);
    tasks = [];
  }

  // A lightweight Decoration for a gradient/frosted tab indicator.
  // It paints a rounded rectangle with a subtle gradient and shadow behind the active tab.
  // (GradientTabIndicator moved to top-level to avoid nested class declaration errors.)

  @override
  void dispose() {
    workOrderController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    for (final t in tasks) {
      t.disposeControllers();
    }
    tabController.dispose();
    super.dispose();
  }

  void addTask([TaskData? data]) {
    setState(() {
      // If no explicit data provided and there are existing tasks, copy nuclides from first task
      if (data == null && tasks.isNotEmpty) {
        // Copy nuclide selections from the first task
        final firstTaskNuclides = tasks.first.nuclides;
        final copiedNuclides = firstTaskNuclides.map((n) {
          return NuclideEntry(
            name: n.name,
            contam: 0.0, // Reset contamination to 0.0 so user must enter new values
            customDAC: n.customDAC, // Preserve custom DAC if "Other" was used
          );
        }).toList();

        data = TaskData(nuclides: copiedNuclides);
      }

      tasks.add(data ?? TaskData());
    // Update tab controller length: Summary + Tasks
    tabController = TabController(length: tasks.length + 1, vsync: this);
    tabController.index = tasks.length; // switch to new task tab
    });
    // Request focus on the new task title after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tasks.isNotEmpty) {
        try {
          tasks.last.titleFocusNode.requestFocus();
        } catch (_) {}
      }
    });
  }

  void removeTask(int index) {
    setState(() {
      // dispose controllers for the task being removed
      tasks[index].disposeControllers();
      tasks.removeAt(index);
      tabController = TabController(length: tasks.length + 1, vsync: this);
      tabController.index = 0;
    });
  }

  double computeMPIF(TaskData t) {
    // require all mPIF factors to be selected (non-zero) before computing
    if (t.mpifR <= 0.0 || t.mpifC <= 0.0 || t.mpifD <= 0.0 || t.mpifS <= 0.0 || t.mpifU <= 0.0) {
      return 0.0; // sentinel meaning 'not set'
    }
    // ensure all multipliers are treated as doubles and avoid integer-only arithmetic
    final mPIF = 1e-6 * (t.mpifR) * (t.mpifC) * (t.mpifD) * 1.0 * (t.mpifS) * (t.mpifU);
    return mPIF;
  }

  // Calculate task totals similar to the JS version
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
    double totalDacFractionWithResp = 0.0; // sum after both eng + resp (used for some triggers)
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
    final respiratorPenalty = t.pfr > 1.0 ? 1.15 : 1.0;

    final collectiveExternal = t.doseRate * personHours * respiratorPenalty;
    final collectiveInternalWithPenalty = totalCollectiveInternal * respiratorPenalty;
    final collectiveEffective = collectiveExternal + collectiveInternalWithPenalty;
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
  final individualExtremity = totalExtremityDose;
  final collectiveExtremity = totalExtremityDose * workers;

  return {
      'personHours': personHours,
      'mPIF': mPIF,
      'totalDacFraction': totalDacFraction, // post-PFE (what the UI previously showed)
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

  // Format numbers for display: use plain formatting for readable ranges,
  // exponential only when very small or very large.
  String formatNumber(double v) {
    final av = v.abs();
    if (av == 0.0) return '0';
    // Use exponential notation for extremes
    if ((av < 0.001 && av > 0) || av >= 1e6) {
      return v.toStringAsExponential(2);
    }

    // For normal-range values, round to three decimal places for cleaner UI.
    // Keep sign and format with fixed 3 decimals.
    return v.toStringAsFixed(3);
  }

  // Get DAC value for a nuclide, using custom DAC for "Other" nuclides
  double getDAC(NuclideEntry n) {
    if (n.name == 'Other' && n.customDAC != null && n.customDAC! > 0) {
      return n.customDAC!;
    }
    return NuclideData.dacValues[n.name] ?? 1e-12;
  }

  // Get Appendix D base contamination level (dpm/100cm²) for removable contamination trigger
  // Returns the base level that gets multiplied by 1000 for the ALARA trigger
  double getAppendixDBaseLevel(NuclideEntry n) {
    final name = n.name?.toUpperCase();
    if (name == null) return 100.0; // Default if no nuclide selected

    // U-nat, U-235, U-238, and associated decay products
    if (name.contains('U-NAT') || name == 'U-235' || name == 'U-238' ||
        name.startsWith('U-') && (name.contains('235') || name.contains('238') || name.contains('NAT'))) {
      return 1000.0;
    }

    // Transuranics: Ra-226, Ra-228, Th-230, Th-228, Pa-231, Ac-227, I-125, I-129
    if (name == 'RA-226' || name == 'RA-228' || name == 'TH-230' || name == 'TH-228' ||
        name == 'PA-231' || name == 'AC-227' || name == 'I-125' || name == 'I-129' ||
        name.startsWith('PU-') || name.startsWith('AM-') || name.startsWith('CM-') ||
        name.startsWith('NP-') || name.startsWith('BK-') || name.startsWith('CF-')) {
      return 20.0;
    }

    // Th-nat, Th-232, Sr-90, Ra-223, Ra-224, U-232, I-126, I-131, I-133
    if (name.contains('TH-NAT') || name == 'TH-232' || name == 'SR-90' ||
        name == 'RA-223' || name == 'RA-224' || name == 'U-232' ||
        name == 'I-126' || name == 'I-131' || name == 'I-133' ||
        name.startsWith('TH-') && (name.contains('232') || name.contains('NAT'))) {
      return 200.0;
    }

    // Tritium and STCs (Special Tritium Compounds)
    if (name == 'H-3' || name == 'TRITIUM' || name.contains('TRITIUM')) {
      return 10000.0;
    }

    // Beta-gamma emitters (default category for most nuclides)
    // This includes all nuclides with decay modes other than alpha emission or spontaneous fission
    // except Sr-90 and others noted above
    return 1000.0;
  }

  // Compute per-nuclide dose components in one place to keep UI and totals consistent.
  Map<String, double> computeNuclideDose(NuclideEntry n, TaskData t) {
    final dac = getDAC(n);
    final safeDac = (dac == 0.0) ? 1e-12 : dac;
    final mPIF = computeMPIF(t);
    final airConc = (n.contam / 100) * mPIF * (1 / 100) * (1 / 2.22e6);
    final dacFractionRaw = (airConc / safeDac);
    final dacFractionEngOnly = dacFractionRaw / (t.pfe == 0.0 ? 1.0 : t.pfe);
    final dacFractionWithBoth = dacFractionRaw / ((t.pfe == 0.0 ? 1.0 : t.pfe) * (t.pfr == 0.0 ? 1.0 : t.pfr));

    final workers = t.workers;
    final personHours = workers * t.hours;

    // Unprotected collective dose
    final unprotected = dacFractionRaw * (personHours / 2000) * 5000;
    final afterPFE = dacFractionEngOnly * (personHours / 2000) * 5000;
    final collective = dacFractionEngOnly * (personHours / 2000) * 5000 / (t.pfr == 0.0 ? 1.0 : t.pfr);

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

  /// Compute global ALARA and air-sampling triggers across all tasks.
  Map<String, dynamic> computeGlobalTriggers() {
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
      final individualExternal = workers > 0 ? (totals['collectiveExternal']! / workers) : 0.0;
      final individualInternal = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
      totalIndividualEffectiveDose += individualExternal + individualInternal;
      totalIndividualExtremityDose += totals['individualExtremity']!;
      totalCollectiveDose += totals['collectiveEffective']!;

      maxDoseRate = maxDoseRate > t.doseRate ? maxDoseRate : t.doseRate;

      double taskDacWithResp = 0.0;
      double taskDacEngOnly = 0.0;

      for (final n in t.nuclides) {
        final contam = n.contam;
        final dac = getDAC(n);
        final mPIF = computeMPIF(t);
        final airConc = (contam / 100) * mPIF * (1 / 100) * (1 / 2.22e6);
        // Guard against divide-by-zero even if invalid values slip in via import.
        final safeDac = (dac == 0.0) ? 1e-12 : dac;
        final safePfe = (t.pfe <= 0.0) ? 1.0 : t.pfe;
        final safePfr = (t.pfr <= 0.0) ? 1.0 : t.pfr;
        final dacFractionWithBoth = (airConc / safeDac) / (safePfe * safePfr);
        final dacFractionEngOnly = (airConc / safeDac) / safePfe;

        taskDacWithResp += dacFractionWithBoth;
        taskDacEngOnly += dacFractionEngOnly;

        // Calculate contamination ratio using radionuclide-specific Appendix D base level
        final appendixDBase = getAppendixDBaseLevel(n);
        final contamRatio = contam / (appendixDBase * 1000);
        maxContamination = maxContamination > contamRatio ? maxContamination : contamRatio;
        maxDacSpikeEngOnly = maxDacSpikeEngOnly > taskDacEngOnly ? maxDacSpikeEngOnly : taskDacEngOnly;
      }

      final dacHrsWithResp = taskDacWithResp * t.hours;
      maxDacHrsWithResp = maxDacHrsWithResp > dacHrsWithResp ? maxDacHrsWithResp : dacHrsWithResp;

      final dacHrsEngOnly = taskDacEngOnly * t.hours;
      maxDacHrsEngOnly = maxDacHrsEngOnly > dacHrsEngOnly ? maxDacHrsEngOnly : dacHrsEngOnly;
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
      final individualInternal = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
      totalInternalDoseOnly += individualInternal;
    }
    final alara7 = totalInternalDoseOnly > 100;

  // Do not auto-check 'Non-routine or complex work' — user should decide this.
  final alara1 = false;

    final sampling1 = maxDacHrsWithResp > 40;
    final sampling2 = tasks.any((t) => t.pfr > 1);
    final sampling3 = false; // subjective, left for user to check
    final sampling4 = tasks.any((t) {
      final totals = calculateTaskTotals(t);
      final workers = t.workers;
      final individualInternal = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
      return individualInternal > 500;
    });
    final condition1 = (maxDacHrsEngOnly / 40) > 0.3;
    final condition2 = maxDacSpikeEngOnly > 1.0;
    final sampling5 = condition1 || condition2;
    final sampling7 = sampling5;
    final sampling6 = false; // subjective job-based triggers left unchecked automatically

    final camsRequired = maxDacHrsWithResp > 40;

    // Aggregate some higher-level flags used by the UI
    final alaraReview = alara1 || alara2 || alara3 || alara4 || alara5 || alara6 || alara7 || alara8;
    final airSampling = sampling1 || sampling2 || sampling3 || sampling4 || sampling5 || sampling6 || sampling7;

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
    };
  }

  // Get final trigger states considering both computed triggers and manual overrides
  Map<String, bool> getFinalTriggerStates() {
    final computedTriggersMap = computeGlobalTriggers();
    final finalStates = <String, bool>{};

    // Individual triggers
    for (final key in ['sampling1', 'sampling2', 'sampling3', 'sampling4', 'sampling5', 'camsRequired',
                       'alara1', 'alara2', 'alara3', 'alara4', 'alara5', 'alara6', 'alara7', 'alara8']) {
      if (computedTriggers.contains(key)) {
        // For computed triggers, use override if present, otherwise use computed value
        finalStates[key] = triggerOverrides.containsKey(key)
            ? triggerOverrides[key]!
            : (computedTriggersMap[key] ?? false);
      } else {
        // For manual triggers, use override value (defaulting to false if not set)
        finalStates[key] = triggerOverrides[key] ?? false;
      }
    }

    // Aggregate triggers based on final individual trigger states
    finalStates['airSampling'] = finalStates['sampling1']! || finalStates['sampling2']! ||
                                 finalStates['sampling3']! || finalStates['sampling4']! || finalStates['sampling5']!;
    finalStates['alaraReview'] = finalStates['alara1']! || finalStates['alara2']! || finalStates['alara3']! ||
                                finalStates['alara4']! || finalStates['alara5']! || finalStates['alara6']! ||
                                finalStates['alara7']! || finalStates['alara8']!;

    return finalStates;
  }

  // Define which triggers are computed automatically vs manual
  static const Set<String> computedTriggers = {
    'sampling1',    // Worker likely to exceed 40 DAC-hours per year (calculated)
    'sampling2',    // Respiratory protection prescribed (calculated)
    'sampling4',    // Estimated intake > 10% ALI or 500 mrem (calculated)
    'sampling5',    // Airborne concentration > 0.3 DAC (calculated)
    'camsRequired', // CAMs required (calculated)
    'alara2',       // Individual total effective dose > 500 mrem (calculated)
    'alara3',       // Individual extremity/skin dose > 5000 mrem (calculated)
    'alara4',       // Collective dose > 750 person-mrem (calculated)
    'alara5',       // Airborne >200 DAC averaged over 1 hr (calculated)
    'alara6',       // Removable contamination > 1000x Appendix D (calculated)
    'alara7',       // Worker likely to receive internal dose >100 mrem (calculated)
    'alara8',       // Entry into areas with dose rates > 10 rem/hr at 30 cm (calculated)
  };

  // Manual triggers that don't require justification:
  // 'sampling3' - Air sample needed to estimate internal dose (subjective)
  // 'alara1' - Non-routine or complex work (subjective)

  // Handle trigger override with justification requirement
  void handleTriggerOverride(String triggerKey, bool? newValue) async {
    if (newValue == null) return;

    // For manual triggers, just set the value directly without justification
    if (!computedTriggers.contains(triggerKey)) {
      setState(() {
        if (newValue) {
          triggerOverrides[triggerKey] = newValue;
        } else {
          triggerOverrides.remove(triggerKey);
        }
      });
      return;
    }

    final computedTriggersMap = computeGlobalTriggers();
    final computedValue = computedTriggersMap[triggerKey] ?? false;

    // If user is trying to override a computed trigger, require justification
    if (computedValue != newValue) {
      final justification = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Override Justification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are overriding an automatically calculated trigger.'),
              SizedBox(height: 8),
              Text('Computed value: ${computedValue ? "Required" : "Not Required"}'),
              Text('Override value: ${newValue ? "Required" : "Not Required"}'),
              SizedBox(height: 16),
              Text('Please provide justification for this override:'),
              SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter justification...',
                ),
                onChanged: (text) => _tempJustification = text,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _tempJustification),
              child: Text('Override'),
            ),
          ],
        ),
      );

      if (justification != null && justification.isNotEmpty) {
        setState(() {
          triggerOverrides[triggerKey] = newValue;
          overrideJustifications[triggerKey] = justification;
        });
      }
    } else {
      // If setting back to computed value, remove override
      setState(() {
        triggerOverrides.remove(triggerKey);
        overrideJustifications.remove(triggerKey);
      });
    }
  }

  String _tempJustification = '';

  // Return short textual reasons for why each trigger was set (task numbers and brief reason)
  Map<String, String> computeTriggerReasons() {
    final reasons = <String, String>{};
    if (tasks.isEmpty) return reasons;

    // Check for sampling1/cams (DAC-hrs > 40 with resp protection taken into account)
    for (var i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final totals = calculateTaskTotals(t);
      final workers = t.workers;
      // compute per-nuclide DAC fraction with both protections
      double taskDacWithResp = 0.0;
      double taskDacEngOnly = 0.0;
      for (final n in t.nuclides) {
        final contam = n.contam;
        final dac = getDAC(n);
        final mPIF = computeMPIF(t);
        final airConc = (contam / 100) * mPIF * (1 / 100) * (1 / 2.22e6);
        final safeDac = (dac == 0.0) ? 1e-12 : dac;
        final safePfe = (t.pfe <= 0.0) ? 1.0 : t.pfe;
        final safePfr = (t.pfr <= 0.0) ? 1.0 : t.pfr;
        final dacWithBoth = (airConc / safeDac) / (safePfe * safePfr);
        final dacEngOnly = (airConc / safeDac) / safePfe;
        taskDacWithResp += dacWithBoth;
        taskDacEngOnly += dacEngOnly;
      }
      final dacHrsWithResp = taskDacWithResp * t.hours;
      final dacHrsEngOnly = taskDacEngOnly * t.hours;

      if (dacHrsWithResp > 40) {
        reasons['sampling1'] = 'Task ${i + 1} (> ${dacHrsWithResp.toStringAsFixed(2)} DAC-hrs)';
        reasons['camsRequired'] = 'Task ${i + 1} (> ${dacHrsWithResp.toStringAsFixed(2)} DAC-hrs)';
      }
      if (dacHrsEngOnly / 40 > 0.3) {
        reasons['sampling5'] = 'Task ${i + 1} (avg ${ (dacHrsEngOnly/40).toStringAsFixed(2)} DAC)';
      }
      if (taskDacEngOnly > 1.0) {
        reasons['sampling5'] = (reasons['sampling5'] ?? '') + ' spike by Task ${i + 1}';
      }

      // alara triggers
      if ((totals['individualEffective'] ?? 0) > 500) reasons['alara2'] = 'Task ${i + 1} individual effective > 500 mrem';
      if (t.workers > 0 && (totals['totalExtremityDose'] ?? 0) / t.workers > 5000) reasons['alara3'] = 'Task ${i + 1} extremity > 5000 mrem';
      if ((totals['collectiveEffective'] ?? 0) > 750) reasons['alara4'] = 'Task ${i + 1} collective > 750 mrem';
      if (taskDacEngOnly * t.hours > 200) reasons['alara5'] = 'Task ${i + 1} DAC-hrs eng-only > 200';
      if (t.nuclides.any((n) => n.contam / (getAppendixDBaseLevel(n) * 1000) > 1)) reasons['alara6'] = 'Task ${i + 1} contamination > 1000x Appendix D';
      if (t.workers > 0 && (totals['collectiveInternal'] ?? 0) / t.workers > 100) reasons['alara7'] = 'Task ${i + 1} internal > 100 mrem';
      if (t.doseRate > 10000) reasons['alara8'] = 'Task ${i + 1} dose rate > 10 rem/hr';
    }

    return reasons;
  }

  static final Set<double> _allowedPfrValues = {1.0, 50.0, 1000.0};
  static final Set<double> _allowedPfeValues = {1.0, 1000.0, 100000.0};
  static final Set<double> _allowedMpifRValues = {0.0, 1.0, 0.1, 0.01, 0.001};
  static final Set<double> _allowedMpifCValues = {0.0, 100.0, 10.0, 1.0, 0.1, 0.01};
  static final Set<double> _allowedMpifSValues = {0.0, 0.1, 1.0};

  bool _isAllowedDouble(double value, Set<double> allowed) {
    const eps = 1e-9;
    return allowed.any((v) => (value - v).abs() <= eps);
  }

  bool _isAllowedIntDouble(double value, {required int min, required int max, bool allowZero = true}) {
    const eps = 1e-9;
    if (allowZero && value.abs() <= eps) return true;
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() > eps) return false;
    final asInt = rounded.toInt();
    return asInt >= min && asInt <= max;
  }

  String? _validateTaskForImport(TaskData t) {
    if (t.workers < 0) return 'Workers must be ≥ 0 (got ${t.workers}).';
    if (t.hours < 0) return 'Hours must be ≥ 0 (got ${t.hours}).';
    if (t.doseRate < 0) return 'Dose rate must be ≥ 0 (got ${t.doseRate}).';

    if (!_isAllowedDouble(t.pfr, _allowedPfrValues)) {
      return 'PFR must be one of ${_allowedPfrValues.toList()..sort()} (got ${t.pfr}).';
    }
    if (!_isAllowedDouble(t.pfe, _allowedPfeValues)) {
      return 'PFE must be one of ${_allowedPfeValues.toList()..sort()} (got ${t.pfe}).';
    }

    if (!_isAllowedDouble(t.mpifR, _allowedMpifRValues)) {
      return 'mPIF Release Factor (R) must be one of ${_allowedMpifRValues.toList()..sort()} (got ${t.mpifR}).';
    }
    if (!_isAllowedDouble(t.mpifC, _allowedMpifCValues)) {
      return 'mPIF Confinement Factor (C) must be one of ${_allowedMpifCValues.toList()..sort()} (got ${t.mpifC}).';
    }
    if (!_isAllowedIntDouble(t.mpifD, min: 1, max: 10, allowZero: true)) {
      return 'mPIF Dispersibility (D) must be an integer 1–10 (or 0 for not set) (got ${t.mpifD}).';
    }
    if (!_isAllowedIntDouble(t.mpifU, min: 1, max: 10, allowZero: true)) {
      return 'mPIF Uncertainty (U) must be an integer 1–10 (or 0 for not set) (got ${t.mpifU}).';
    }
    if (!_isAllowedDouble(t.mpifS, _allowedMpifSValues)) {
      return 'mPIF Special Form (S) must be one of ${_allowedMpifSValues.toList()..sort()} (got ${t.mpifS}).';
    }

    for (final n in t.nuclides) {
      if (n.contam < 0) return 'Contamination must be ≥ 0 (got ${n.contam}).';
      if (n.name != null && !NuclideData.dacValues.containsKey(n.name)) {
        return 'Nuclide "${n.name}" is not a supported selection.';
      }
      if (n.name == 'Other' && n.customDAC != null && n.customDAC! <= 0) {
        return 'Custom DAC for "Other" must be > 0 when provided (got ${n.customDAC}).';
      }
    }

    for (final e in t.extremities) {
      if (e.doseRate < 0) return 'Extremity dose rate must be ≥ 0 (got ${e.doseRate}).';
      if (e.time < 0) return 'Extremity time must be ≥ 0 (got ${e.time}).';
      if (e.contam < 0) return 'Extremity contamination must be ≥ 0 (got ${e.contam}).';
      if (e.nuclide != null && !NuclideData.extremityNuclides.contains(e.nuclide)) {
        return 'Extremity nuclide "${e.nuclide}" is not a supported selection.';
      }
    }

    return null;
  }

  void saveToFile() async {
    if (kIsWeb) {
      // For web, trigger file download
      final state = {
        'projectInfo': {
          'workOrder': workOrderController.text,
          'date': dateController.text,
          'description': descriptionController.text,
        },
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'triggerOverrides': triggerOverrides,
        'overrideJustifications': overrideJustifications,
      };
      final jsonStr = jsonEncode(state);
      final bytes = utf8.encode(jsonStr);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'dose_assessment_${DateTime.now().millisecondsSinceEpoch}.json';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File downloaded successfully.')));
      return;
    }

    try {
      final state = {
        'projectInfo': {
          'workOrder': workOrderController.text,
          'date': dateController.text,
          'description': descriptionController.text,
        },
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'triggerOverrides': triggerOverrides,
        'overrideJustifications': overrideJustifications,
      };
      final jsonStr = jsonEncode(state);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save dose assessment',
        fileName: 'dose_assessment.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonStr);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File saved successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save file: $e')));
    }
  }


  void loadFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String fileContent;
        if (kIsWeb) {
          // For web, read from bytes
          final bytes = result.files.single.bytes!;
          fileContent = utf8.decode(bytes);
        } else {
          // For desktop/mobile, read from file path
          final file = File(result.files.single.path!);
          fileContent = await file.readAsString();
        }

        final Map<String, dynamic> state = jsonDecode(fileContent);

        final parsedTasks = (state['tasks'] as List? ?? []).map((t) => TaskData.fromJson(t)).toList();
        for (var i = 0; i < parsedTasks.length; i++) {
          final err = _validateTaskForImport(parsedTasks[i]);
          if (err != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Import rejected (Task ${i + 1}): $err')),
              );
            }
            return;
          }
        }

        setState(() {
          workOrderController.text = state['projectInfo']?['workOrder'] ?? '';
          dateController.text = state['projectInfo']?['date'] ?? '';
          descriptionController.text = state['projectInfo']?['description'] ?? '';
          // dispose existing task controllers first
          for (final tt in tasks) {
            tt.disposeControllers();
          }
          tasks = parsedTasks;
          // load trigger overrides if present
        triggerOverrides = Map<String, bool>.from(state['triggerOverrides'] ?? {});
        overrideJustifications = Map<String, String>.from(state['overrideJustifications'] ?? {});
        // Update tab controller length: Summary + Tasks
        tabController = TabController(length: tasks.length + 1, vsync: this);
      });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File loaded successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
    }
  }

  Future<void> printSummaryReport() async {
    try {
      final pdf = pw.Document();

      // Calculate all summary data
      final computedTriggers = computeGlobalTriggers();
      final finalTriggers = getFinalTriggerStates();

      double totalIndividualEffective = 0.0;
      double totalIndividualExtremity = 0.0;
      double totalCollectiveExternal = 0.0;
      double totalCollectiveInternal = 0.0;

      final List<Map<String, dynamic>> taskSummaries = [];

      for (final t in tasks) {
        final totals = calculateTaskTotals(t);
        final workers = t.workers;
        final individualExternal = workers > 0 ? (totals['collectiveExternal']! / workers) : 0.0;
        final individualInternal = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
        final individualExtremity = totals['individualExtremity']!;
        final individualTotal = individualExternal + individualInternal;

        totalCollectiveExternal += totals['collectiveExternal']!;
        totalCollectiveInternal += totals['collectiveInternal']!;
        totalIndividualEffective += individualTotal;
        totalIndividualExtremity += individualExtremity;

        taskSummaries.add({
          'task': t,
          'totals': totals,
          'individualExternal': individualExternal,
          'individualInternal': individualInternal,
          'individualExtremity': individualExtremity,
          'individualTotal': individualTotal,
        });
      }

      final totalCollective = totalCollectiveExternal + totalCollectiveInternal;

      // Page 1: Quick Overview Summary
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
                        'RPP-742 Task-Based Dose Assessment',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Work Order: ${workOrderController.text}', style: const pw.TextStyle(fontSize: 12)),
                      if (descriptionController.text.isNotEmpty)
                        pw.Text('Description: ${descriptionController.text}', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Trigger Indicators
                pw.Text('Trigger Indicators', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 15,
                            height: 15,
                            decoration: pw.BoxDecoration(
                              color: finalTriggers['alaraReview'] == true
                                  ? PdfColors.red
                                  : PdfColors.green,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text('ALARA Review', style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 15,
                            height: 15,
                            decoration: pw.BoxDecoration(
                              color: finalTriggers['airSampling'] == true
                                  ? PdfColors.red
                                  : PdfColors.green,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text('Air Sampling', style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 15,
                            height: 15,
                            decoration: pw.BoxDecoration(
                              color: finalTriggers['camsRequired'] == true
                                  ? PdfColors.red
                                  : PdfColors.green,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text('CAMs', style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Overall Dose Summary
                pw.Text('Overall Dose Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Collective Dose: ${totalCollective.toStringAsFixed(2)} person-mrem',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('  External: ${totalCollectiveExternal.toStringAsFixed(2)} person-mrem',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('  Internal: ${formatNumber(totalCollectiveInternal)} person-mrem',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 8),
                      pw.Text('Total Extremity Dose: ${(totalIndividualExtremity * (tasks.isNotEmpty ? tasks.first.workers : 1)).toStringAsFixed(2)} mrem',
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Task Summary Table
                pw.Text('Task Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Task', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Location', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Ind. Ext.\n(mrem)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Ind. Int.\n(mrem)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total Ind.\n(mrem)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...taskSummaries.map((summary) {
                      final t = summary['task'] as TaskData;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(t.title, style: const pw.TextStyle(fontSize: 9), softWrap: true),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(t.location, style: const pw.TextStyle(fontSize: 9), softWrap: true),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(summary['individualExternal'].toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(formatNumber(summary['individualInternal']),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(summary['individualTotal'].toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                // Signature lines
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Signatures', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 16),

                      // Preparer signature line (always shown)
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Preparer:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 8),
                                pw.Container(
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                                  ),
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Date:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 8),
                                pw.Container(
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                                  ),
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Peer check signature line (only if ALARA review required)
                      if (finalTriggers['alaraReview'] == true) ...[
                        pw.SizedBox(height: 20),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 2,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Peer Check (ALARA Review):', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 8),
                                  pw.Container(
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                                    ),
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Date:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 8),
                                  pw.Container(
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                                    ),
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Page 2+: Detailed Task Data
      for (var i = 0; i < taskSummaries.length; i++) {
        final summary = taskSummaries[i];
        final t = summary['task'] as TaskData;
        final totals = summary['totals'] as Map<String, double>;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Task Header
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 2)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Task ${i + 1}: ${t.title}',
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Page ${i + 2}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Task Details
                  pw.Text('Task Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Expanded(child: pw.Text('Location: ${t.location}', style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(child: pw.Text('Workers: ${t.workers}', style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(child: pw.Text('Hours: ${t.hours}', style: const pw.TextStyle(fontSize: 10))),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Expanded(child: pw.Text('External Dose Rate: ${t.doseRate} mrem/hr', style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(child: pw.Text('PFR: ${t.pfr}', style: const pw.TextStyle(fontSize: 10))),
                            pw.Expanded(child: pw.Text('PFE: ${t.pfe}', style: const pw.TextStyle(fontSize: 10))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Material Protection Factors
                  pw.Text('Material Protection Factors', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'R: ${t.mpifR}  C: ${t.mpifC}  D: ${t.mpifD}  S: ${t.mpifS}  U: ${t.mpifU}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Nuclide Information
                  if (t.nuclides.isNotEmpty) ...[
                    pw.Text('Nuclide Contamination', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Nuclide', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Contamination\n(dpm/100cm²)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('DAC Fraction', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                        ...t.nuclides.map((n) {
                          final res = computeNuclideDose(n, t);
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(n.name ?? 'Not selected', style: const pw.TextStyle(fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(formatNumber(n.contam), style: const pw.TextStyle(fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(formatNumber(res['dacFractionEngOnly']!), style: const pw.TextStyle(fontSize: 9)),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // Extremity Information
                  if (t.extremities.isNotEmpty) ...[
                    pw.Text('Extremity Exposure', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Nuclide', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Dose Rate\n(mrem/hr)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Time\n(hours)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Total\n(mrem)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                        ...t.extremities.map((e) {
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(e.nuclide ?? '', style: const pw.TextStyle(fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(e.doseRate.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(e.time.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text((e.doseRate * e.time).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // Dose Summary for this Task
                  pw.Text('Dose Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
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
                        pw.Text('Individual Doses:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('  External: ${summary['individualExternal'].toStringAsFixed(2)} mrem', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  Internal: ${formatNumber(summary['individualInternal'])} mrem', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  Extremity: ${summary['individualExtremity'].toStringAsFixed(2)} mrem', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  Total Effective: ${summary['individualTotal'].toStringAsFixed(2)} mrem',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Collective Doses:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('  External: ${totals['collectiveExternal']!.toStringAsFixed(2)} person-mrem', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  Internal: ${formatNumber(totals['collectiveInternal']!)} person-mrem', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  Total Effective: ${totals['collectiveEffective']!.toStringAsFixed(2)} person-mrem',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        if (totals['respiratorPenalty']! > 1.0) ...[
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.amber50,
                              border: pw.Border.all(color: PdfColors.amber300),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'Note: Doses include 15% respirator penalty (×1.15)',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print dialog opened')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    }
  }


  Widget buildSummary() {
    final finalTriggers = getFinalTriggerStates();

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.playlist_add_check_rounded, size: 56, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No tasks yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text('Use "Add Task" above to begin.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ]),
        ),
      );
    }

    double totalCollectiveExternal = 0.0;
    double totalCollectiveInternal = 0.0;

    for (final t in tasks) {
      final totals = calculateTaskTotals(t);
      totalCollectiveExternal += totals['collectiveExternal']!;
      totalCollectiveInternal += totals['collectiveInternal']!;
    }
    final totalCollective = totalCollectiveExternal + totalCollectiveInternal;
    final totalIndivExtremity = tasks.fold<double>(0, (s, t) => s + calculateTaskTotals(t)['individualExtremity']!);
    final totalCollExtremity  = tasks.fold<double>(0, (s, t) => s + calculateTaskTotals(t)['collectiveExtremity']!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status badges row ──────────────────────────────────────────────
        Row(children: [
          _StatusBadge(label: 'ALARA Review',  triggered: finalTriggers['alaraReview'] == true),
          const SizedBox(width: 8),
          _StatusBadge(label: 'Air Sampling',  triggered: finalTriggers['airSampling'] == true),
          const SizedBox(width: 8),
          _StatusBadge(label: 'CAMs',          triggered: finalTriggers['camsRequired'] == true),
        ]),
        const SizedBox(height: 20),

        // ── Dose overview ─────────────────────────────────────────────────
        _SectionHeader(title: 'Overall Dose'),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Collective dose card
          Expanded(
            flex: 3,
            child: _InfoCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Collective Dose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                const SizedBox(height: 6),
                Text(totalCollective.toStringAsFixed(2),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, height: 1)),
                Text('person-mrem', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _MiniStat(label: 'External', value: totalCollectiveExternal.toStringAsFixed(2), color: _kAccentAlt)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'Internal', value: formatNumber(totalCollectiveInternal), color: _kAccent)),
                ]),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          // Extremity dose card
          Expanded(
            flex: 2,
            child: _InfoCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Extremity Dose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                const SizedBox(height: 14),
                _MiniStat(label: 'Individual', value: totalIndivExtremity.toStringAsFixed(2), unit: 'mrem/person', color: _kWarning),
                const SizedBox(height: 8),
                _MiniStat(label: 'Collective', value: totalCollExtremity.toStringAsFixed(2), unit: 'person-mrem', color: _kWarning),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // ── Per-task summary ──────────────────────────────────────────────
        _SectionHeader(title: 'Task Breakdown'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tasks.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final totals = calculateTaskTotals(t);
              final workers = t.workers;
              final indExt  = workers > 0 ? (totals['collectiveExternal']! / workers) : 0.0;
              final indInt  = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
              final indExtr = totals['individualExtremity']!;
              final indTot  = indExt + indInt;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 240,
                  child: _InfoCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${i + 1}. ${t.title.isEmpty ? "Task ${i + 1}" : t.title}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (t.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(t.location, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 12),
                      _MiniStat(label: 'Individual Effective', value: indTot.toStringAsFixed(2), unit: 'mrem', color: _kAccent),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _MiniStat(label: 'External', value: indExt.toStringAsFixed(2), color: _kAccentAlt)),
                        const SizedBox(width: 6),
                        Expanded(child: _MiniStat(label: 'Internal', value: formatNumber(indInt), color: _kAccent)),
                      ]),
                      const SizedBox(height: 6),
                      _MiniStat(label: 'Extremity', value: indExtr.toStringAsFixed(2), unit: 'mrem', color: _kWarning),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // ── Triggers detail ───────────────────────────────────────────────
        buildTriggers(),
      ],
    );
  }

  void showDebugInfo() {
    // Diagnostic dialog: show per-nuclide computed fields for the first task (or a sample)
    final t = tasks.isNotEmpty ? tasks.first : TaskData(title: 'Sample', location: 'Lab', workers: 1, hours: 15.0, mpifR: 1.0, mpifC: 100.0, mpifD: 1.0, mpifS: 1.0, mpifU: 1.0, doseRate: 0.0, pfr: 1.0, pfe: 1.0, nuclides: [NuclideEntry(name: 'Sr-90', contam: 100000.0)]);
    final List<Widget> rows = [];
    rows.add(Text('Task: ${t.title}  Location: ${t.location}'));
    rows.add(const SizedBox(height: 8));
    for (final n in t.nuclides) {
      final res = computeNuclideDose(n, t);
      final dac = res['dac'] ?? 0.0;
      final airConc = res['airConc'] ?? 0.0;
      final raw = res['dacFractionRaw'] ?? 0.0;
      final eng = res['dacFractionEngOnly'] ?? 0.0;
      final collective = res['collective'] ?? 0.0;
      final individual = res['individual'] ?? 0.0;
      rows.add(Text('Nuclide: ${n.name}  Contam: ${n.contam} dpm/100cm²'));
      rows.add(Text('  DAC: ${formatNumber(dac)}'));
      rows.add(Text('  Air conc: ${airConc.toStringAsExponential(6)}'));
      rows.add(Text('  DAC fraction (raw): ${raw.toStringAsExponential(6)}'));
      rows.add(Text('  DAC fraction (after PFE): ${eng.toStringAsExponential(6)}'));
      rows.add(Text('  Collective internal dose: ${collective.toStringAsExponential(6)}'));
      rows.add(Text('  Individual internal dose: ${individual.toStringAsExponential(6)}'));
      rows.add(const SizedBox(height: 6));
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Per-nuclide Diagnostics'), content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: rows)), actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); }, child: const Text('Close'))]));
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabLabels = <String>['Summary'];
    tabLabels.addAll(List.generate(tasks.length, (i) {
      final td = tasks[i];
      return td.title.trim().isEmpty ? 'Task ${i + 1}' : '${i + 1}. ${td.title}';
    }));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Project info header ──────────────────────────────────────────────
        Material(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: workOrderController,
                  decoration: const InputDecoration(labelText: 'RWP Number'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Work Description'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),

        // ── Task tab bar ─────────────────────────────────────────────────────
        Material(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _InnerTabBar(
                    controller: tabController,
                    labels: tabLabels,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _AddTaskButton(onPressed: () {
                addTask();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try { tabController.animateTo(tasks.length); } catch (_) {}
                });
              }),
            ]),
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),

        // ── Tab content ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: buildSummary(),
              ),
              ...List.generate(tasks.length, (i) => buildTaskTab(i)),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTriggers() {
    final finalTriggers = getFinalTriggerStates();
    final reasons = computeTriggerReasons();

    Widget triggerRow(String key, String label) {
      final active = finalTriggers[key] ?? false;
      final reason = reasons[key];
      final justification = overrideJustifications[key];
      return _TriggerRow(
        triggerKey: key,
        label: label,
        active: active,
        reason: reason,
        justification: justification,
        onChanged: (v) => handleTriggerOverride(key, v),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader(title: 'Air Sampling Triggers'),
      const SizedBox(height: 10),
      _InfoCard(
        child: Column(children: [
          triggerRow('sampling1', 'Worker likely to exceed 40 DAC-hours per year'),
          triggerRow('sampling2', 'Respiratory protection prescribed'),
          triggerRow('sampling3', 'Air sample needed to estimate internal dose'),
          triggerRow('sampling4', 'Estimated intake > 10% ALI or 500 mrem'),
          triggerRow('sampling5', 'Airborne concentration > 0.3 DAC avg or >1 DAC spike'),
          triggerRow('camsRequired', 'CAMs required (worker > 40 DAC-hrs/week)'),
        ]),
      ),
      const SizedBox(height: 16),
      _SectionHeader(title: 'ALARA Review Triggers'),
      const SizedBox(height: 10),
      _InfoCard(
        child: Column(children: [
          triggerRow('alara1', 'Non-routine or complex work'),
          triggerRow('alara2', 'Individual total effective dose > 500 mrem'),
          triggerRow('alara3', 'Individual extremity/skin dose > 5,000 mrem'),
          triggerRow('alara4', 'Collective dose > 750 person-mrem'),
          triggerRow('alara5', 'Airborne >200 DAC avg over 1 hr or spike >1,000 DAC'),
          triggerRow('alara6', 'Removable contamination > 1,000× Appendix D levels'),
          triggerRow('alara7', 'Worker likely to receive internal dose > 100 mrem'),
          triggerRow('alara8', 'Dose rates > 10 rem/hr at 30 cm'),
        ]),
      ),
    ]);
  }

  Widget buildTaskTab(int index) {
    final t = tasks[index];
    final totals = calculateTaskTotals(t);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget section({
      required String title,
      required String stateKey,
      bool defaultExpanded = false,
      required Widget child,
    }) {
      return _CollapsibleSection(
        title: title,
        initiallyExpanded: t.sectionExpansionStates[stateKey] ?? defaultExpanded,
        onExpansionChanged: (v) => setState(() => t.sectionExpansionStates[stateKey] = v),
        child: child,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Task header ────────────────────────────────────────────────────
        _InfoCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: t.titleController,
                  focusNode: t.titleFocusNode,
                  autofocus: t.titleController.text.isEmpty,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => removeTask(index),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kDanger,
                  side: const BorderSide(color: _kDanger),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: t.locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              onChanged: (_) => setState(() {}),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Time estimation ────────────────────────────────────────────────
        section(
          title: 'Time Estimation',
          stateKey: 'timeEstimation',
          defaultExpanded: true,
          child: Row(children: [
            Expanded(child: TextField(
              controller: t.workersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '# Workers'),
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: t.hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Hours Each'),
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(
              label: 'Person-Hours',
              value: totals['personHours']!.toStringAsFixed(2),
              color: _kAccent,
            )),
          ]),
        ),
        const SizedBox(height: 8),

        // ── mPIF ───────────────────────────────────────────────────────────
        section(
          title: 'mPIF Calculation',
          stateKey: 'mpifCalculation',
          child: Column(children: [
            Row(children: [
              Expanded(child: DropdownButtonFormField<double>(
                value: t.mpifR > 0.0 ? t.mpifR : null,
                decoration: const InputDecoration(labelText: 'Release Factor (R)', hintText: 'Select R'),
                items: releaseFactors.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
                onChanged: (v) { t.mpifR = v ?? 0.0; setState(() {}); },
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<double>(
                value: t.mpifC > 0.0 ? t.mpifC : null,
                decoration: const InputDecoration(labelText: 'Confinement Factor (C)', hintText: 'Select C'),
                items: confinementFactors.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
                onChanged: (v) { t.mpifC = v ?? 0.0; setState(() {}); },
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<int>(
                value: t.mpifD > 0 ? t.mpifD.toInt() : null,
                decoration: const InputDecoration(labelText: 'Dispersibility (D)', hintText: 'Select D'),
                items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                onChanged: (v) { if (v != null) { t.mpifD = v.toDouble(); t.mpifDController.text = v.toString(); setState(() {}); } },
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<int>(
                value: t.mpifU > 0 ? t.mpifU.toInt() : null,
                decoration: const InputDecoration(labelText: 'Uncertainty (U)', hintText: 'Select U'),
                items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                onChanged: (v) { if (v != null) { t.mpifU = v.toDouble(); t.mpifUController.text = v.toString(); setState(() {}); } },
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<double>(
                value: t.mpifS > 0 ? t.mpifS : null,
                decoration: const InputDecoration(labelText: 'Special Form (S)', hintText: 'Select S'),
                items: [0.1, 1.0].map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
                onChanged: (v) { if (v != null) { t.mpifS = v; t.mpifSController.text = v.toString(); setState(() {}); } },
              )),
              const SizedBox(width: 12),
              Expanded(child: Tooltip(
                message: 'mPIF = 1e-6 × R × C × D × S × U',
                child: _MiniStat(
                  label: 'mPIF Result',
                  value: totals['mPIF']! > 0 ? totals['mPIF']!.toStringAsExponential(2) : '—',
                  color: _kAccent,
                ),
              )),
            ]),
            const SizedBox(height: 10),
            _InfoNote(text: 'Refer to Attachment A of HPP 9.1 for mPIF factor details.'),
          ]),
        ),
        const SizedBox(height: 8),

        // ── External dose ──────────────────────────────────────────────────
        section(
          title: 'External Dose Estimate',
          stateKey: 'externalDose',
          child: Column(children: [
            TextField(
              controller: t.doseRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Dose Rate (mrem/hr)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _MiniStat(label: 'Person-Hours', value: totals['personHours']!.toStringAsFixed(2), color: _kAccentAlt)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Collective External', value: totals['collectiveExternal']!.toStringAsFixed(2), unit: 'mrem', color: _kAccent)),
            ]),
          ]),
        ),
        const SizedBox(height: 8),

        // ── Extremity dose ─────────────────────────────────────────────────
        section(
          title: 'Extremity / Skin Dose',
          stateKey: 'extremityDose',
          child: Column(children: [
            ...List.generate(t.extremities.length, (ei) {
              final e = t.extremities[ei];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Autocomplete<String>(
                    optionsBuilder: (v) {
                      final all = ['Other', 'Various', ...NuclideData.dacValues.keys];
                      return v.text.isEmpty ? all : all.where((k) => k.toLowerCase().contains(v.text.toLowerCase()));
                    },
                    optionsViewBuilder: (ctx, onSelected, options) => Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (_, i) => ListTile(dense: true, title: Text(options.elementAt(i)), onTap: () => onSelected(options.elementAt(i))),
                        ),
                      ),
                    ),
                    onSelected: (s) { e.nuclide = s; setState(() {}); },
                    fieldViewBuilder: (ctx, ctrl, fn, _) {
                      ctrl.text = e.nuclide ?? '';
                      return TextField(controller: ctrl, focusNode: fn, decoration: const InputDecoration(hintText: 'Nuclide'));
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: e.doseRateController,
                    decoration: const InputDecoration(labelText: 'Dose Rate (mrem/hr)'),
                    onChanged: (v) => setState(() { e.doseRate = double.tryParse(v) ?? 0.0; }),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: e.timeController,
                    decoration: const InputDecoration(labelText: 'Time (hr)'),
                    onChanged: (v) => setState(() { e.time = double.tryParse(v) ?? 0.0; }),
                  )),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => setState(() { e.disposeControllers(); t.extremities.removeAt(ei); }),
                    icon: const Icon(Icons.remove_circle_outline, color: _kDanger, size: 20),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() { t.extremities.add(ExtremityEntry()); }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Extremity Dose'),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _MiniStat(label: 'Individual Extremity', value: totals['individualExtremity']!.toStringAsFixed(2), unit: 'mrem/person', color: _kWarning)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Collective Extremity', value: totals['collectiveExtremity']!.toStringAsFixed(2), unit: 'mrem', color: _kWarning)),
            ]),
          ]),
        ),
        const SizedBox(height: 8),

        // ── Protection factors ─────────────────────────────────────────────
        section(
          title: 'Protection Factors',
          stateKey: 'protectionFactors',
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Respiratory (PFR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              RadioListTile<double>(value: 1.0,      groupValue: t.pfr, title: const Text('None (PFR=1)',    style: TextStyle(fontSize: 13)), dense: true, onChanged: (v) { t.pfr = v!; setState(() {}); }),
              RadioListTile<double>(value: 50.0,     groupValue: t.pfr, title: const Text('APR (PFR=50)',    style: TextStyle(fontSize: 13)), dense: true, onChanged: (v) { t.pfr = v!; setState(() {}); }),
              RadioListTile<double>(value: 1000.0,   groupValue: t.pfr, title: const Text('PAPR (PFR=1000)', style: TextStyle(fontSize: 13)), dense: true, onChanged: (v) { t.pfr = v!; setState(() {}); }),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Engineering (PFE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              RadioListTile<double>(value: 1.0,      groupValue: t.pfe, title: const Text('No Controls (PFE=1)',    style: TextStyle(fontSize: 13)), dense: true, onChanged: (v) { t.pfe = v!; setState(() {}); }),
              RadioListTile<double>(value: 1000.0,   groupValue: t.pfe, title: const Text('Type I (PFE=1,000)',     style: TextStyle(fontSize: 13)), dense: true, onChanged: (v) { t.pfe = v!; setState(() {}); }),
              RadioListTile<double>(value: 100000.0, groupValue: t.pfe, title: const Text('Type II (PFE=100,000)',  style: TextStyle(fontSize: 13)), dense: true, onChanged: (v) { t.pfe = v!; setState(() {}); }),
            ])),
          ]),
        ),
        const SizedBox(height: 8),

        // ── Internal dose ──────────────────────────────────────────────────
        section(
          title: 'Internal Dose Calculation',
          stateKey: 'internalDose',
          child: Column(children: [
            ...List.generate(t.nuclides.length, (ni) {
              final n = t.nuclides[ni];
              final res = computeNuclideDose(n, t);
              final dac = res['dac'] ?? 1e-12;
              final airConc = res['airConc'] ?? 0.0;
              final dacFrEng = res['dacFractionEngOnly'] ?? 0.0;
              final nuclideCollective = res['collective'] ?? 0.0;
              final nuclideIndiv = res['individual'] ?? 0.0;

              return Column(children: [
                Row(children: [
                  Expanded(child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: n.name ?? ''),
                    optionsBuilder: (v) => v.text.isEmpty ? NuclideData.dacValues.keys : NuclideData.dacValues.keys.where((k) => k.toLowerCase().contains(v.text.toLowerCase())),
                    optionsViewBuilder: (ctx, onSelected, options) => Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (_, i) {
                            final opt = options.elementAt(i);
                            final d = NuclideData.dacValues[opt] ?? 1e-12;
                            return ListTile(dense: true, title: Text(opt), subtitle: opt == 'Other' ? const Text('Custom DAC') : Text('DAC: ${formatNumber(d)}'), onTap: () => onSelected(opt));
                          },
                        ),
                      ),
                    ),
                    onSelected: (s) {
                      n.name = s;
                      if (s != 'Other') { n.customDAC = null; n.dacController.clear(); }
                      setState(() {});
                    },
                    fieldViewBuilder: (ctx, ctrl, fn, _) {
                      ctrl.text = n.name ?? '';
                      return TextField(controller: ctrl, focusNode: fn, decoration: const InputDecoration(labelText: 'Nuclide', hintText: 'Select radionuclide'));
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: n.name == 'Other' ? n.dacController : TextEditingController(text: n.name != null ? formatNumber(dac) : ''),
                    readOnly: n.name != 'Other',
                    enabled: n.name == 'Other',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-\.]'))],
                    decoration: InputDecoration(
                      labelText: 'DAC (µCi/mL)',
                      hintText: n.name == 'Other' ? 'Enter custom DAC' : (n.name == null ? 'Select nuclide' : ''),
                    ),
                    onChanged: (_) => setState(() {}),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: n.contamController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-\.]'))],
                    decoration: const InputDecoration(labelText: 'Contam. (dpm/100cm²)'),
                    onChanged: (_) => setState(() {}),
                  )),
                  IconButton(
                    onPressed: () => setState(() { n.disposeControllers(); t.nuclides.removeAt(ni); }),
                    icon: const Icon(Icons.remove_circle_outline, color: _kDanger, size: 20),
                  ),
                ]),
                const SizedBox(height: 6),
                _InfoCard(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Expanded(child: _MiniStat(label: 'Air Conc.', value: airConc.isFinite ? airConc.toStringAsExponential(3) : '0', color: _kAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniStat(label: 'DAC Frac. (post-PFE)', value: dacFrEng.isFinite ? formatNumber(dacFrEng) : '0', color: _kAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniStat(label: 'Ind. Internal', value: formatNumber(nuclideIndiv), unit: 'mrem', color: _kAccentAlt)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniStat(label: 'Coll. Internal', value: formatNumber(nuclideCollective), unit: 'mrem', color: _kAccentAlt)),
                  ]),
                ),
                const SizedBox(height: 8),
                Divider(color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
                const SizedBox(height: 8),
              ]);
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() { t.nuclides.add(NuclideEntry()); }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Nuclide'),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Task totals ────────────────────────────────────────────────────
        _SectionHeader(title: 'Task Results'),
        const SizedBox(height: 10),
        _InfoCard(
          child: Column(children: [
            Row(children: [
              Expanded(child: _MiniStat(label: 'DAC Frac (post-PFE)', value: formatNumber(totals['totalDacFraction'] ?? 0.0), color: _kAccent)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'DAC-hours (post-PFE)', value: formatNumber((totals['totalDacFraction'] ?? 0.0) * t.hours), color: _kAccent)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _MiniStat(label: 'Collective Effective', value: totals['collectiveEffective']!.toStringAsFixed(2), unit: 'mrem', color: _kAccent)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Individual Effective', value: totals['individualEffective']!.toStringAsFixed(2), unit: 'mrem/person', color: _kAccentAlt)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Individual Extremity', value: totals['individualExtremity']!.toStringAsFixed(2), unit: 'mrem/person', color: _kWarning)),
            ]),
            if (totals['respiratorPenalty']! > 1.0) ...[
              const SizedBox(height: 10),
              _InfoNote(text: 'Doses include 15% respirator penalty (×1.15).'),
            ],
          ]),
        ),
      ]),
    );
  }
}
