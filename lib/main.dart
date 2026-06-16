import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'containment.dart';
import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    as file_download;
import 'qa_loader_stub.dart'
    if (dart.library.html) 'qa_loader_web.dart'
    as qa_loader;
import 'nuclides.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic>? initialState;
  final initialTab = Uri.base.queryParameters['tab'] == 'containment' ? 1 : 0;

  if (kIsWeb) {
    final fileName = Uri.base.queryParameters['loadQa'];
    if (fileName != null && fileName.isNotEmpty) {
      try {
        final fileContent = await qa_loader.loadQaFile(fileName);
        initialState = jsonDecode(fileContent) as Map<String, dynamic>;
      } catch (_) {
        initialState = null;
      }
    }
  }

  runApp(DoseEstimateApp(initialState: initialState, initialTab: initialTab));
}

// ─── Design tokens ────────────────────────────────────────────────────────────
// Light palette (warm gray — from design handoff)
const _kBg = Color(0xFFF7F6F3);
const _kSurface = Color(0xFFFFFFFF);
const _kSurface2 = Color(0xFFFAF9F7);
const _kSurface3 = Color(0xFFF2F1EC);
const _kHairline = Color(0xFFE7E5DE);
const _kHairline2 = Color(0xFFEFEDE7);
const _kInk1 = Color(0xFF1A1A18);
const _kInk2 = Color(0xFF3D3C38);
const _kInk3 = Color(0xFF6B6A63);
const _kInk4 = Color(0xFF9A9892);
const _kAccent = Color(0xFF2B4B7A); // deep navy-blue
const _kAccentInk = Color(0xFF203A60);
const _kAccentWash = Color(0xFFEAF0F9);
const _kOk = Color(0xFF2E7D4F);
const _kOkWash = Color(0xFFE8F2EB);
const _kWarn = Color(0xFFB5711F);
const _kWarnWash = Color(0xFFFBF0DC);
const _kDanger = Color(0xFFB23434);
const _kDangerWash = Color(0xFFF8E4E2);

// Dark palette equivalents
const _kDarkBg = Color(0xFF131311);
const _kDarkSurface = Color(0xFF1C1C1A);
const _kDarkSurface2 = Color(0xFF201F1D);
const _kDarkHairline = Color(0xFF2E2D28);
const _kDarkInk1 = Color(0xFFEEEDEA);
const _kDarkInk2 = Color(0xFFB8B7B0);
const _kDarkInk3 = Color(0xFF7A7972);
const _kDarkInk4 = Color(0xFF5A5950);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? _kDarkBg : _kBg;
  final surface = isDark ? _kDarkSurface : _kSurface;
  final hairline = isDark ? _kDarkHairline : _kHairline;
  final ink1 = isDark ? _kDarkInk1 : _kInk1;
  final ink3 = isDark ? _kDarkInk3 : _kInk3;

  final cs = ColorScheme(
    brightness: brightness,
    primary: _kAccent,
    onPrimary: Colors.white,
    secondary: _kOk,
    onSecondary: Colors.white,
    error: _kDanger,
    onError: Colors.white,
    surface: surface,
    onSurface: ink1,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Inter',
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: hairline),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: surface,
      foregroundColor: ink1,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: ink1,
        letterSpacing: -0.2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? _kDarkSurface2 : _kSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kAccent, width: 1.5),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: ink3,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(fontSize: 13, color: _kInk4),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      isDense: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ink1,
        foregroundColor: bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _kAccent),
    ),
    dividerTheme: DividerThemeData(color: hairline, space: 1, thickness: 1),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? _kDanger : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: hairline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _kDarkSurface2 : _kSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hairline),
        ),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? _kAccent : ink3,
      ),
    ),
  );
}

class DoseEstimateApp extends StatefulWidget {
  final Map<String, dynamic>? initialState;
  final int initialTab;
  const DoseEstimateApp({super.key, this.initialState, this.initialTab = 0});

  @override
  State<DoseEstimateApp> createState() => _DoseEstimateAppState();
}

class _DoseEstimateAppState extends State<DoseEstimateApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPP-742 Dose Estimate',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: MainScreen(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
        initialState: widget.initialState,
        initialTab: widget.initialTab,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final Map<String, dynamic>? initialState;
  final int initialTab;
  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    this.initialState,
    this.initialTab = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0; // 0 = dose, 1 = containment
  final GlobalKey<DoseEstimateScreenState> _doseEstimateKey = GlobalKey();
  final GlobalKey<ContainmentTabState> _containmentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _kDarkSurface : _kSurface;
    final hairline = isDark ? _kDarkHairline : _kHairline;
    final ink1 = isDark ? _kDarkInk1 : _kInk1;
    final ink3 = isDark ? _kDarkInk3 : _kInk3;
    final ink4 = isDark ? _kDarkInk4 : _kInk4;
    final bg = isDark ? _kDarkBg : _kBg;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Topbar ────────────────────────────────────────────────────────
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: hairline)),
            ),
            child: Row(
              children: [
                // Brand mark
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: ink1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'R742',
                            style: TextStyle(
                              color: bg,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Dose Assessment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ink1,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab buttons
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      _TopbarTab(
                        label: 'Dose Estimate',
                        icon: Icons.show_chart,
                        active: _tab == 0,
                        count: _doseEstimateKey.currentState?.tasks.length,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 4),
                      _TopbarTab(
                        label: 'Containment Analysis',
                        icon: Icons.shield_outlined,
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action buttons
                if (_tab == 0) ...[
                  _TopbarAction(
                    label: 'Load',
                    icon: Icons.folder_outlined,
                    onTap: () => _doseEstimateKey.currentState?.loadFromFile(),
                  ),
                  _TopbarAction(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    onTap: () => _doseEstimateKey.currentState?.saveToFile(),
                  ),
                  _TopbarAction(
                    label: 'Print',
                    icon: Icons.print_outlined,
                    onTap: () =>
                        _doseEstimateKey.currentState?.printSummaryReport(),
                  ),
                ],
                if (_tab == 1) ...[
                  _TopbarAction(
                    label: 'Load',
                    icon: Icons.folder_outlined,
                    onTap: () => _doseEstimateKey.currentState?.loadFromFile(),
                  ),
                  _TopbarAction(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    onTap: () => _doseEstimateKey.currentState?.saveToFile(),
                  ),
                  _TopbarAction(
                    label: 'Print',
                    icon: Icons.print_outlined,
                    onTap: () =>
                        _containmentKey.currentState?.printContainmentReport(),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 16,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: ink3,
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: widget.onToggleTheme,
                  tooltip: isDark ? 'Light mode' : 'Dark mode',
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                DoseEstimateScreen(
                  key: _doseEstimateKey,
                  onTaskCountChanged: () => setState(() {}),
                  containmentKey: _containmentKey,
                  initialState: widget.initialState,
                ),
                ContainmentTab(
                  key: _containmentKey,
                  onLoad: () => _doseEstimateKey.currentState?.loadFromFile(),
                  onSave: () => _doseEstimateKey.currentState?.saveToFile(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopbarTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int? count;
  final VoidCallback onTap;

  const _TopbarTab({
    required this.label,
    required this.icon,
    required this.active,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kDarkBg : _kBg;
    final ink1 = isDark ? _kDarkInk1 : _kInk1;
    final ink3 = isDark ? _kDarkInk3 : _kInk3;
    final surf3 = isDark ? const Color(0xFF2A2A27) : _kSurface3;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ink1 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: active ? bg : ink3),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? bg : ink3,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.14) : surf3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? bg : ink3,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopbarAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TopbarAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink3 = isDark ? _kDarkInk3 : _kInk3;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: ink3,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ─── Shared helper widgets ────────────────────────────────────────────────────

/// Flat card with subtle background
class _InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _InfoCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
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
  const _MiniStat({
    required this.label,
    required this.value,
    this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }
}

/// Bold section header
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Status badge for ALARA / Air Sampling / CAMs
class _StatusBadge extends StatelessWidget {
  final String label;
  final bool triggered;
  const _StatusBadge({required this.label, required this.triggered});

  @override
  Widget build(BuildContext context) {
    final color = triggered ? _kDanger : _kOk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            triggered ? 'Required' : 'Clear',
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
        ],
      ),
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
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: _kAccent.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.65),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible section card
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;
  const _CollapsibleSection({
    required this.title,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
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
    required this.triggerKey,
    required this.label,
    required this.active,
    this.reason,
    this.justification,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: active,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: active
                  ? _kDanger
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          activeColor: _kDanger,
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 4),
            child: Text(
              reason!,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ),
        if (justification != null)
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 6),
            child: Text(
              'Override: $justification',
              style: const TextStyle(
                fontSize: 11,
                color: _kWarn,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
      ],
    );
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
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
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
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
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

class _WorkField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _WorkField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              color: _kInk4,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 2),
          IntrinsicWidth(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? _kDarkInk1 : _kInk1,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkFieldRaw extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _WorkFieldRaw({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            color: _kInk4,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? _kDarkInk1 : _kInk1,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _WorkDivider extends StatelessWidget {
  final Color color;
  const _WorkDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}

// Blocks typing a leading minus sign; paste of negative values is caught at the
// widget level by comparing the parsed result against zero.
class _NonNegativeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty / in-progress entry (e.g. "1e-", "1.") but block a bare "-"
    if (newValue.text.startsWith('-')) return oldValue;
    return newValue;
  }
}

// Returns an InputDecoration with error styling when [isNegative] is true.
InputDecoration _numericDecoration(InputDecoration base, bool isNegative) {
  if (!isNegative) return base;
  return base.copyWith(
    errorText: 'Must be ≥ 0',
    errorStyle: const TextStyle(fontSize: 11),
  );
}

class DoseEstimateScreen extends StatefulWidget {
  final VoidCallback? onTaskCountChanged;
  final GlobalKey<ContainmentTabState>? containmentKey;
  final Map<String, dynamic>? initialState;
  const DoseEstimateScreen({
    super.key,
    this.onTaskCountChanged,
    this.containmentKey,
    this.initialState,
  });

  @override
  State<DoseEstimateScreen> createState() => DoseEstimateScreenState();
}

class TaskData {
  String title;
  String location;
  int workers;
  double hours;
  double? mpifR; // null = not yet selected; 0.0 = encapsulated (R=0 is a valid selection)
  double mpifC;
  double mpifD;
  double mpifO;
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
    // null = not yet selected; 0.0 = encapsulated (R=0 explicitly chosen). UI requires selection before computing mPIF.
    this.mpifR,
    this.mpifC = 0.0,
    this.mpifD = 0.0,
    this.mpifO = 1.0,
    this.mpifS = 0.0,
    this.mpifU = 0.0,
    this.doseRate = 0.0,
    this.pfr = 1.0,
    this.pfe = 1.0,
    List<NuclideEntry>? nuclides,
    List<ExtremityEntry>? extremities,
    Map<String, bool>? sectionExpansionStates,
  }) : nuclides = nuclides ?? [NuclideEntry()],
       extremities = extremities ?? [],
       sectionExpansionStates =
           sectionExpansionStates ??
           {
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
    'mpifO': mpifO,
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
    final rawNuclides = (j['nuclides'] as List?)
        ?.map((e) => NuclideEntry.fromJson(e))
        .toList();
    final rawExtremities = (j['extremities'] as List?)
        ?.map((e) => ExtremityEntry.fromJson(e))
        .toList();
    return TaskData(
      title: j['title'] ?? '',
      location: j['location'] ?? '',
      workers: j['workers'] ?? 1,
      hours: (j['hours'] ?? 1).toDouble(),
      // Use 0.0 when values are missing so mPIF remains "not set" until user selects factors.
      mpifR: j['mpifR'] != null ? (j['mpifR'] as num).toDouble() : null,
      mpifC: (j['mpifC'] ?? 0).toDouble(),
      mpifD: (j['mpifD'] ?? 0).toDouble(),
      mpifO: 1.0, // fixed — occupancy is always 1 for dose estimate tasks
      mpifS: (j['mpifS'] ?? 0).toDouble(),
      mpifU: (j['mpifU'] ?? 0).toDouble(),
      doseRate: (j['doseRate'] ?? 0).toDouble(),
      pfr: (j['pfr'] ?? 1).toDouble(),
      pfe: (j['pfe'] ?? 1).toDouble(),
      nuclides: (rawNuclides == null || rawNuclides.isEmpty)
          ? null
          : rawNuclides,
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
    if (name == 'Other' && customDAC != null) 'customDAC': customDAC,
  };

  static NuclideEntry fromJson(Map<String, dynamic> j) => NuclideEntry(
    name: j['name'],
    contam: (j['contam'] ?? 0).toDouble(),
    customDAC: j['customDAC']?.toDouble(),
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

  ExtremityEntry({
    this.nuclide,
    this.doseRate = 0.0,
    this.time = 0.0,
    this.contam = 0.0,
  }) {
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

  Map<String, dynamic> toJson() => {
    'nuclide': nuclide,
    'doseRate': doseRate,
    'time': time,
    'contam': contam,
  };
  static ExtremityEntry fromJson(Map<String, dynamic> j) => ExtremityEntry(
    nuclide: j['nuclide'],
    doseRate: (j['doseRate'] ?? 0).toDouble(),
    time: (j['time'] ?? 0).toDouble(),
    contam: (j['contam'] ?? 0).toDouble(),
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
  const GradientTabIndicator({
    this.radius = 12.0,
    required this.gradient,
    this.blurRadius = 8.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GradientPainter(
    radius: radius,
    gradient: gradient,
    blurRadius: blurRadius,
  );
}

class _GradientPainter extends BoxPainter {
  final double radius;
  final Gradient gradient;
  final double blurRadius;

  _GradientPainter({
    required this.radius,
    required this.gradient,
    required this.blurRadius,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    if (size.isEmpty) return;
    final rect = offset & size;

    // Make the pill slightly larger than the provided rect so it reads as a 'pill' behind the label.
    const extraHorizontal = 8.0;
    const extraVertical = 6.0;
    final paddedRect = Rect.fromLTRB(
      rect.left - extraHorizontal,
      rect.top - extraVertical,
      rect.right + extraHorizontal,
      rect.bottom + extraVertical,
    );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _kAccent
                        : (isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
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
          color: _kOk,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Add Task',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoseEstimateScreenState extends State<DoseEstimateScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // dacValues moved to NuclideData class in nuclides.dart

  final Map<String, double> releaseFactors = const {
    'Gases, volatile liquids (1.0)': 1.0,
    'Nonvolatile powders, some liquids (0.1)': 0.1,
    'Liquids, large area contamination (0.01)': 0.01,
    'Solids, spotty contamination (0.001)': 0.001,
    'Encapsulated material (0)': 0,
  };

  final Map<String, double> confinementFactors = const {
    'None - Open bench (100)': 100,
    'Bagged material (10)': 10,
    'Fume Hood (1.0)': 1.0,
    'Enhanced Fume Hood (0.1)': 0.1,
    'Glovebox, Hot Cell (0.01)': 0.01,
  };

  // occupancyFactors removed — O is fixed at 1.0 for all dose estimate tasks.

  List<TaskData> tasks = [];
  TextEditingController workOrderController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  // user overrides for trigger checkboxes
  Map<String, bool> triggerOverrides = {};
  // justifications for overrides
  Map<String, String> overrideJustifications = {};

  // Track expansion state for summary page sections
  Map<String, bool> summaryExpansionStates = {'internalDose': false};

  @override
  void initState() {
    super.initState();
    tasks = [];
    if (widget.initialState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyImportedState(widget.initialState!);
      });
    }
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
    super.dispose();
  }

  void addTask([TaskData? data]) {
    setState(() {
      if (data == null && tasks.isNotEmpty) {
        final firstTaskNuclides = tasks.first.nuclides;
        final copiedNuclides = firstTaskNuclides.map((n) {
          return NuclideEntry(
            name: n.name,
            contam: 0.0,
            customDAC: n.customDAC,
          );
        }).toList();
        data = TaskData(nuclides: copiedNuclides);
      }
      tasks.add(data ?? TaskData());
      _activeIdx = tasks.length - 1;
    });
    widget.onTaskCountChanged?.call();
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
      tasks[index].disposeControllers();
      tasks.removeAt(index);
      _activeIdx = -1;
    });
    widget.onTaskCountChanged?.call();
  }

  double computeMPIF(TaskData t) {
    // require all mPIF factors to be selected (non-zero) before computing
    if (t.mpifR == null ||
        t.mpifC <= 0.0 ||
        t.mpifD <= 0.0 ||
        t.mpifS <= 0.0 ||
        t.mpifU <= 0.0) {
      return 0.0; // sentinel meaning 'not set'
    }
    // ensure all multipliers are treated as doubles and avoid integer-only arithmetic
    final mPIF =
        1e-6 *
        (t.mpifR!) *
        (t.mpifC) *
        (t.mpifD) *
        (t.mpifO) *
        (t.mpifS) *
        (t.mpifU);
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
    final respiratorPenalty = t.pfr > 1.0 ? 1.15 : 1.0;

    final collectiveExternal = t.doseRate * personHours * respiratorPenalty;
    final collectiveInternalWithPenalty =
        totalCollectiveInternal * respiratorPenalty;
    final collectiveEffective =
        collectiveExternal + collectiveInternalWithPenalty;
    final individualEffective = workers > 0
        ? collectiveEffective / workers
        : 0.0;

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
        name.startsWith('CF-')) {
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
    final dacFractionWithBoth =
        dacFractionRaw /
        ((t.pfe == 0.0 ? 1.0 : t.pfe) * (t.pfr == 0.0 ? 1.0 : t.pfr));

    final workers = t.workers;
    final personHours = workers * t.hours;

    // Unprotected collective dose
    final unprotected = dacFractionRaw * (personHours / 2000) * 5000;
    final afterPFE = dacFractionEngOnly * (personHours / 2000) * 5000;
    final collective =
        dacFractionEngOnly *
        (personHours / 2000) *
        5000 /
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
    final alara1 = false;

    final sampling1 = maxDacHrsWithResp > 40;
    final sampling2 = tasks.any((t) => t.pfr > 1);
    final sampling3 = false; // subjective, left for user to check
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
    final sampling6 =
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
    };
  }

  // Get final trigger states considering both computed triggers and manual overrides
  Map<String, bool> getFinalTriggerStates() {
    final computedTriggersMap = computeGlobalTriggers();
    final finalStates = <String, bool>{};

    // Individual triggers
    for (final key in [
      'sampling1',
      'sampling2',
      'sampling3',
      'sampling4',
      'sampling5',
      'camsRequired',
      'alara1',
      'alara2',
      'alara3',
      'alara4',
      'alara5',
      'alara6',
      'alara7',
      'alara8',
    ]) {
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
    finalStates['airSampling'] =
        finalStates['sampling1']! ||
        finalStates['sampling2']! ||
        finalStates['sampling3']! ||
        finalStates['sampling4']! ||
        finalStates['sampling5']!;
    finalStates['alaraReview'] =
        finalStates['alara1']! ||
        finalStates['alara2']! ||
        finalStates['alara3']! ||
        finalStates['alara4']! ||
        finalStates['alara5']! ||
        finalStates['alara6']! ||
        finalStates['alara7']! ||
        finalStates['alara8']!;

    return finalStates;
  }

  // Define which triggers are computed automatically vs manual
  static const Set<String> computedTriggers = {
    'sampling1', // Worker likely to exceed 40 DAC-hours per year (calculated)
    'sampling2', // Respiratory protection prescribed (calculated)
    'sampling4', // Estimated intake > 10% ALI or 500 mrem (calculated)
    'sampling5', // Airborne concentration > 0.3 DAC (calculated)
    'camsRequired', // CAMs required (calculated)
    'alara2', // Individual total effective dose > 500 mrem (calculated)
    'alara3', // Individual extremity/skin dose > 5000 mrem (calculated)
    'alara4', // Collective dose > 750 person-mrem (calculated)
    'alara5', // Airborne >200 DAC averaged over 1 hr (calculated)
    'alara6', // Removable contamination > 1000x Appendix D (calculated)
    'alara7', // Worker likely to receive internal dose >100 mrem (calculated)
    'alara8', // Entry into areas with dose rates > 10 rem/hr at 30 cm (calculated)
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
              Text(
                'Computed value: ${computedValue ? "Required" : "Not Required"}',
              ),
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
            (reasons['sampling5'] ?? '') + ' spike by Task ${i + 1}';
      }

      // alara triggers
      if ((totals['individualEffective'] ?? 0) > 500)
        reasons['alara2'] = 'Task ${i + 1} individual effective > 500 mrem';
      if (t.workers > 0 &&
          (totals['totalExtremityDose'] ?? 0) / t.workers > 5000)
        reasons['alara3'] = 'Task ${i + 1} extremity > 5000 mrem';
      if ((totals['collectiveEffective'] ?? 0) > 750)
        reasons['alara4'] = 'Task ${i + 1} collective > 750 mrem';
      if (taskDacEngOnly * t.hours > 200)
        reasons['alara5'] = 'Task ${i + 1} DAC-hrs eng-only > 200';
      if (t.nuclides.any(
        (n) => n.contam / (getAppendixDBaseLevel(n) * 1000) > 1,
      ))
        reasons['alara6'] = 'Task ${i + 1} contamination > 1000x Appendix D';
      if (t.workers > 0 &&
          (totals['collectiveInternal'] ?? 0) / t.workers > 100)
        reasons['alara7'] = 'Task ${i + 1} internal > 100 mrem';
      if (t.doseRate > 10000)
        reasons['alara8'] = 'Task ${i + 1} dose rate > 10 rem/hr';
    }

    return reasons;
  }

  static final Set<double> _allowedPfrValues = {1.0, 50.0, 1000.0};
  static final Set<double> _allowedPfeValues = {1.0, 1000.0, 100000.0};
  static final Set<double> _allowedMpifRValues = {0.0, 1.0, 0.1, 0.01, 0.001};
  static final Set<double> _allowedMpifCValues = {
    0.0,
    100.0,
    10.0,
    1.0,
    0.1,
    0.01,
  };
  static final Set<double> _allowedMpifDValues = {0.0, 1.0, 10.0};
  // _allowedMpifOValues removed — O is fixed at 1.0.
  static final Set<double> _allowedMpifSValues = {0.0, 0.1, 1.0};

  bool _isAllowedDouble(double value, Set<double> allowed) {
    const eps = 1e-9;
    return allowed.any((v) => (value - v).abs() <= eps);
  }

  bool _isAllowedIntDouble(
    double value, {
    required int min,
    required int max,
    bool allowZero = true,
  }) {
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

    if (t.mpifR != null && !_isAllowedDouble(t.mpifR!, _allowedMpifRValues)) {
      return 'mPIF Release Factor (R) must be one of ${_allowedMpifRValues.toList()..sort()} (got ${t.mpifR}).';
    }
    if (!_isAllowedDouble(t.mpifC, _allowedMpifCValues)) {
      return 'mPIF Confinement Factor (C) must be one of ${_allowedMpifCValues.toList()..sort()} (got ${t.mpifC}).';
    }
    if (!_isAllowedDouble(t.mpifD, _allowedMpifDValues)) {
      return 'mPIF Dispersibility (D) must be one of ${_allowedMpifDValues.toList()..sort()} (got ${t.mpifD}).';
    }
    // mpifO validation removed — O is fixed at 1.0.
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
      if (e.doseRate < 0)
        return 'Extremity dose rate must be ≥ 0 (got ${e.doseRate}).';
      if (e.time < 0) return 'Extremity time must be ≥ 0 (got ${e.time}).';
      if (e.contam < 0)
        return 'Extremity contamination must be ≥ 0 (got ${e.contam}).';
      if (e.nuclide != null &&
          e.nuclide!.isNotEmpty &&
          !NuclideData.extremityNuclides.contains(e.nuclide)) {
        return 'Extremity nuclide "${e.nuclide}" is not a supported selection.';
      }
    }

    return null;
  }

  void saveToFile() async {
    final containmentState = widget.containmentKey?.currentState?.exportState();

    if (kIsWeb) {
      // For web, trigger file download
      final state = {
        'projectInfo': {
          'workOrder': workOrderController.text,
          'date': dateController.text,
          'description': descriptionController.text,
        },
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'ui': {'activeIdx': _activeIdx},
        'triggerOverrides': triggerOverrides,
        'overrideJustifications': overrideJustifications,
        if (containmentState != null) 'containment': containmentState,
      };
      final jsonStr = jsonEncode(state);
      await file_download.downloadJson(
        jsonStr,
        'dose_assessment_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File downloaded successfully.')),
        );
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
        'ui': {'activeIdx': _activeIdx},
        'triggerOverrides': triggerOverrides,
        'overrideJustifications': overrideJustifications,
        if (containmentState != null) 'containment': containmentState,
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File saved successfully')),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save file: $e')));
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
        final applied = _applyImportedState(state, showErrors: true);
        if (!applied) return;
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File loaded successfully')),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
    }
  }

  bool _applyImportedState(
    Map<String, dynamic> state, {
    bool showErrors = false,
  }) {
    final parsedTasks = (state['tasks'] as List? ?? [])
        .map((t) => TaskData.fromJson(t))
        .toList();
    for (var i = 0; i < parsedTasks.length; i++) {
      final err = _validateTaskForImport(parsedTasks[i]);
      if (err != null) {
        if (showErrors && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import rejected (Task ${i + 1}): $err')),
          );
        }
        return false;
      }
    }

    setState(() {
      workOrderController.text = state['projectInfo']?['workOrder'] ?? '';
      dateController.text = state['projectInfo']?['date'] ?? '';
      descriptionController.text = state['projectInfo']?['description'] ?? '';
      for (final tt in tasks) {
        tt.disposeControllers();
      }
      tasks = parsedTasks;
      triggerOverrides = Map<String, bool>.from(
        state['triggerOverrides'] ?? {},
      );
      overrideJustifications = Map<String, String>.from(
        state['overrideJustifications'] ?? {},
      );
      final savedActiveIdx = (state['ui'] is Map)
          ? (state['ui']['activeIdx'] as int?)
          : null;
      if (tasks.isEmpty) {
        _activeIdx = -1;
      } else if (savedActiveIdx == null) {
        _activeIdx = 0;
      } else {
        _activeIdx = savedActiveIdx.clamp(-1, tasks.length - 1);
      }
    });

    if (state['containment'] is Map) {
      widget.containmentKey?.currentState?.importState(
        Map<String, dynamic>.from(state['containment']),
      );
    }

    return true;
  }

  // ─── PDF color palette ─────────────────────────────────────────────────────
  // ─── PDF geometry ──────────────────────────────────────────────────────────
  // Letter: 612 × 792 pt.  Horizontal margin: 50 pt each side → CW = 512 pt.
  static const double _pdfPW = 612.0;
  static const double _pdfM = 50.0;
  static const double _pdfCW = 512.0; // content width
  static const double _pdfCrdW = 250.0; // dose card width  ((512-12)/2)

  // ─── PDF color palette ─────────────────────────────────────────────────────
  static final PdfColor _pdfNavy = PdfColor.fromHex('#1A2D4E');
  static final PdfColor _pdfOk = PdfColor.fromHex('#2E7D4F');
  static final PdfColor _pdfOkWash = PdfColor.fromHex('#E8F2EB');
  static final PdfColor _pdfDanger = PdfColor.fromHex('#B23434');
  static final PdfColor _pdfDangerWash = PdfColor.fromHex('#F8E4E2');
  static final PdfColor _pdfHair = PdfColor.fromHex('#E7E5DE');
  static final PdfColor _pdfHair2 = PdfColor.fromHex('#F2F1EC');
  static final PdfColor _pdfSurf2 = PdfColor.fromHex('#FAF9F7');
  static final PdfColor _pdfInk1 = PdfColor.fromHex('#1A1A18');
  static final PdfColor _pdfInk2 = PdfColor.fromHex('#3D3C38');
  static final PdfColor _pdfInk3 = PdfColor.fromHex('#6B6A63');
  static final PdfColor _pdfInk4 = PdfColor.fromHex('#9A9892');
  static final PdfColor _pdfNavyLight = PdfColor.fromHex('#668099');
  static final PdfColor _pdfNavyMid = PdfColor.fromHex('#99BBCC');

  // ─── PDF helper widgets ────────────────────────────────────────────────────

  /// Key-value row used in detail boxes.
  pw.Widget _pdfKV(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 130,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _pdfInk3,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );

  /// Header cell for PDF tables.
  pw.Widget _pdfTH(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _pdfInk4,
          ),
        ),
      );

  /// Data cell for PDF tables.
  pw.Widget _pdfTD(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: bold ? _pdfInk1 : _pdfInk2,
      ),
    ),
  );

  /// Uppercase section label.
  pw.Widget _pdfSectionLabel(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: _pdfInk4,
      ),
    ),
  );

  /// Section heading with underline — task detail pages.
  pw.Widget _pdfSection(String title) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 3),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _pdfHair, width: 0.8)),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _pdfInk1,
          ),
        ),
      ),
      pw.SizedBox(height: 6),
    ],
  );

  /// Horizontal progress bar (0–100%). Uses pw.Table to avoid Row/Expanded issues.
  pw.Widget _pdfBar(double pct, {bool bad = false, double width = 206}) {
    final p = pct.clamp(0.0, 100.0);
    final filled = (p / 100 * width).clamp(1.0, width - 1.0);
    final empty = width - filled;
    return pw.Table(
      columnWidths: {
        0: pw.FixedColumnWidth(filled),
        1: pw.FixedColumnWidth(empty),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(height: 5, color: bad ? _pdfDanger : _pdfOk),
            pw.Container(height: 5, color: _pdfHair),
          ],
        ),
      ],
    );
  }

  /// "Required" badge (red) shown only when triggered.
  pw.Widget _pdfRequiredBadge() => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: pw.BoxDecoration(
      color: _pdfDangerWash,
      border: pw.Border.all(color: _pdfDanger, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Text(
      'Required',
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _pdfDanger,
      ),
    ),
  );

  // ─── Main PDF report ───────────────────────────────────────────────────────

  Future<void> printSummaryReport() async {
    try {
      final pdf = pw.Document();

      // ── Aggregate data ──────────────────────────────────────────────────────
      final computedTriggers = computeGlobalTriggers();
      final finalTriggers = getFinalTriggerStates();
      final alaraTriggered = finalTriggers['alaraReview'] == true;
      final airTriggered = finalTriggers['airSampling'] == true;
      final camsTriggered = finalTriggers['camsRequired'] == true;
      final anyTriggered = alaraTriggered || airTriggered || camsTriggered;

      final maxDacHrsWithResp =
          (computedTriggers['maxDacHrsWithResp'] as double?) ?? 0.0;
      final maxDacHrsEngOnly =
          (computedTriggers['maxDacHrsEngOnly'] as double?) ?? 0.0;

      double maxIndEff = 0.0;
      double totalCollExt = 0.0;
      double totalCollInt = 0.0;
      int totalWorkers = 0;
      double totalPersonHrs = 0.0;

      final List<Map<String, dynamic>> taskSummaries = [];

      for (final t in tasks) {
        final totals = calculateTaskTotals(t);
        final w = t.workers;
        final iExt = w > 0 ? (totals['collectiveExternal']! / w) : 0.0;
        final iInt = w > 0 ? (totals['collectiveInternal']! / w) : 0.0;
        final iExtrm = totals['individualExtremity']!;
        final iTotal = iExt + iInt;
        final cExt = totals['collectiveExternal']!;
        final cInt = totals['collectiveInternal']!;

        totalCollExt += cExt;
        totalCollInt += cInt;
        if (iTotal > maxIndEff) maxIndEff = iTotal;
        totalWorkers += w;
        totalPersonHrs += w * t.hours;

        taskSummaries.add({
          'task': t,
          'totals': totals,
          'iExt': iExt,
          'iInt': iInt,
          'iExtrm': iExtrm,
          'iTotal': iTotal,
          'cExt': cExt,
          'cInt': cInt,
        });
      }

      final totalColl = totalCollExt + totalCollInt;
      final indPct = (maxIndEff / 500 * 100).clamp(0.0, 100.0);
      final colPct = (totalColl / 750 * 100).clamp(0.0, 100.0);
      final indBad = maxIndEff > 500;
      final colBad = totalColl > 750;

      final now = DateTime.now();
      final genStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final wo = workOrderController.text.isNotEmpty
          ? workOrderController.text
          : '-';
      final dateStr = dateController.text.isNotEmpty
          ? dateController.text
          : '-';
      final descStr = descriptionController.text;
      final nTasks = tasks.length;

      // ════════════════════════════════════════════════════════════════════
      // PAGE 1 — Executive Summary
      // ════════════════════════════════════════════════════════════════════
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            // ── Navy header (full width) ──────────────────────────────────────
            final headerBar = pw.Container(
              width: _pdfPW,
              color: _pdfNavy,
              padding: const pw.EdgeInsets.only(
                left: _pdfM,
                top: 36,
                right: _pdfM,
                bottom: 13,
              ),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.6),
                  1: pw.FlexColumnWidth(1.0),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RWP Dose Assessment',
                            style: pw.TextStyle(
                              fontSize: 17,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '$wo  |  $dateStr'
                            '${descStr.isNotEmpty ? "  |  $descStr" : ""}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: _pdfNavyLight,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Generated $genStr',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _pdfNavyLight,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '$nTasks ${nTasks == 1 ? "task" : "tasks"}'
                            '  |  $totalWorkers workers'
                            '  |  ${totalPersonHrs.toStringAsFixed(0)} person-hrs',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: _pdfNavyMid,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );

            // ── Dose summary cards ────────────────────────────────────────────
            // Inner card width = _pdfCrdW (250) - 28 (14 padding each side) = 222
            const cardInner = 222.0;
            const col1 = 148.0; // number column
            const col2 = 74.0; // badge / right column

            pw.Widget doseCard({
              required String heading,
              required String mainVal,
              required String unit,
              required String pctLabel,
              required double pct,
              required bool bad,
              required List<Map<String, String>> breakdown,
            }) {
              final bwash = bad ? _pdfDangerWash : _pdfOkWash;
              final bink = bad ? _pdfDanger : _pdfOk;

              return pw.Container(
                width: _pdfCrdW,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _pdfHair, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // heading + badge row
                    pw.Table(
                      columnWidths: const {
                        0: pw.FixedColumnWidth(col1),
                        1: pw.FixedColumnWidth(col2),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text(
                              heading,
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: _pdfInk3,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: bwash,
                                  borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(9),
                                  ),
                                ),
                                child: pw.Text(
                                  pctLabel,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: bink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    // big number
                    pw.Text(
                      mainVal,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfInk1,
                      ),
                    ),
                    pw.Text(
                      unit,
                      style: pw.TextStyle(fontSize: 9, color: _pdfInk4),
                    ),
                    pw.SizedBox(height: 5),
                    // progress bar
                    _pdfBar(pct, bad: bad, width: cardInner),
                    pw.SizedBox(height: 8),
                    // breakdown
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: _pdfHair2, width: 0.5),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(top: 7),
                      child: pw.Table(
                        columnWidths: const {
                          0: pw.FixedColumnWidth(74),
                          1: pw.FixedColumnWidth(74),
                          2: pw.FixedColumnWidth(74),
                        },
                        children: [
                          pw.TableRow(
                            children: breakdown
                                .map(
                                  (m) => pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        m['l']!,
                                        style: pw.TextStyle(
                                          fontSize: 7,
                                          color: _pdfInk4,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        m['v']!,
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                          color: _pdfInk2,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final maxIExt = taskSummaries.isEmpty
                ? 0.0
                : taskSummaries
                      .map((s) => s['iExt'] as double)
                      .reduce((a, b) => a > b ? a : b);
            final maxIInt = taskSummaries.isEmpty
                ? 0.0
                : taskSummaries
                      .map((s) => s['iInt'] as double)
                      .reduce((a, b) => a > b ? a : b);

            final doseCards = pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(_pdfCrdW),
                1: pw.FixedColumnWidth(12),
                2: pw.FixedColumnWidth(_pdfCrdW),
              },
              children: [
                pw.TableRow(
                  children: [
                    doseCard(
                      heading: 'Maximum Individual Effective Dose',
                      mainVal: maxIndEff.toStringAsFixed(2),
                      unit: 'mrem',
                      pctLabel: '${indPct.round()}% of limit',
                      pct: indPct,
                      bad: indBad,
                      breakdown: [
                        {
                          'l': 'External',
                          'v': '${maxIExt.toStringAsFixed(2)} mrem',
                        },
                        {'l': 'Internal', 'v': '${formatNumber(maxIInt)} mrem'},
                        {'l': 'Limit', 'v': '500 mrem/yr'},
                      ],
                    ),
                    pw.SizedBox(),
                    doseCard(
                      heading: 'Collective Effective Dose',
                      mainVal: totalColl.toStringAsFixed(2),
                      unit: 'person-mrem',
                      pctLabel: '${colPct.round()}% of limit',
                      pct: colPct,
                      bad: colBad,
                      breakdown: [
                        {
                          'l': 'External',
                          'v': '${totalCollExt.toStringAsFixed(2)} p-mrem',
                        },
                        {
                          'l': 'Internal',
                          'v': '${formatNumber(totalCollInt)} p-mrem',
                        },
                        {'l': 'Limit', 'v': '750 p-mrem/yr'},
                      ],
                    ),
                  ],
                ),
              ],
            );

            // ── Trigger status pills (always shown) ───────────────────────────
            pw.Widget pill(String label, bool on) => pw.Container(
              margin: const pw.EdgeInsets.only(right: 8),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(
                color: on ? _pdfDangerWash : _pdfSurf2,
                border: pw.Border.all(
                  color: on ? _pdfDanger : _pdfHair,
                  width: 0.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Text(
                '$label: ${on ? "Required" : "Not required"}',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: on ? _pdfDanger : _pdfInk4,
                ),
              ),
            );

            final pillRow = pw.Row(
              children: [
                pill('ALARA Review', alaraTriggered),
                pill('Air Sampling', airTriggered),
                pill('CAMs', camsTriggered),
              ],
            );

            // ── Trigger detail table — only when triggers fire ────────────────
            pw.Widget? triggerDetail;
            if (anyTriggered) {
              pw.TableRow groupRow(String label) => pw.TableRow(
                decoration: pw.BoxDecoration(color: _pdfSurf2),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfInk1,
                      ),
                    ),
                  ),
                  pw.SizedBox(),
                  pw.SizedBox(),
                  pw.SizedBox(),
                ],
              );

              pw.TableRow dataRow(
                String criterion,
                String threshold,
                String computed,
              ) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(
                      left: 16,
                      right: 5,
                      top: 5,
                      bottom: 5,
                    ),
                    child: pw.Text(
                      criterion,
                      style: pw.TextStyle(fontSize: 8.5, color: _pdfInk2),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      threshold,
                      style: pw.TextStyle(fontSize: 8, color: _pdfInk4),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    child: pw.Text(
                      computed,
                      style: pw.TextStyle(fontSize: 8, color: _pdfInk2),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: _pdfRequiredBadge(),
                  ),
                ],
              );

              final rows = <pw.TableRow>[
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _pdfHair2),
                  children: [
                    _pdfTH('Criterion'),
                    _pdfTH('Threshold'),
                    _pdfTH('Computed Value'),
                    _pdfTH('Status', align: pw.TextAlign.center),
                  ],
                ),
              ];

              if (alaraTriggered) {
                rows.add(groupRow('ALARA Review'));
                if (maxIndEff > 500)
                  rows.add(
                    dataRow(
                      'Individual total effective dose',
                      '500 mrem',
                      '${maxIndEff.toStringAsFixed(2)} mrem',
                    ),
                  );
                if (maxDacHrsEngOnly > 200)
                  rows.add(
                    dataRow(
                      'Airborne DAC-hours (engineering controls)',
                      '200 DAC-hrs',
                      '${maxDacHrsEngOnly.toStringAsFixed(2)} DAC-hrs',
                    ),
                  );
                if (totalColl > 750)
                  rows.add(
                    dataRow(
                      'Collective effective dose',
                      '750 person-mrem',
                      '${totalColl.toStringAsFixed(2)} person-mrem',
                    ),
                  );
              }
              if (airTriggered) {
                rows.add(groupRow('Air Sampling Required'));
                if (maxDacHrsWithResp > 40)
                  rows.add(
                    dataRow(
                      'Worker DAC-hours (with resp. protection)',
                      '40 DAC-hrs',
                      '${maxDacHrsWithResp.toStringAsFixed(2)} DAC-hrs',
                    ),
                  );
                if (tasks.any((t) => t.pfr > 1))
                  rows.add(
                    dataRow('Respiratory protection prescribed', 'Any', 'Yes'),
                  );
              }
              if (camsTriggered) {
                rows.add(groupRow('Continuous Air Monitors (CAMs) Required'));
                rows.add(
                  dataRow(
                    'DAC-hours with respiratory protection',
                    '40 DAC-hrs',
                    '${maxDacHrsWithResp.toStringAsFixed(2)} DAC-hrs',
                  ),
                );
              }

              triggerDetail = pw.Table(
                border: pw.TableBorder.all(color: _pdfHair, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(2.0),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(1.3),
                },
                children: rows,
              );
            }

            // ── Task summary table ────────────────────────────────────────────
            // Columns: Task | W | Hrs | Ind.Ext | Ind.Int | Ind.Total | Coll.Ext | Coll.Int | Coll.Total
            const tCols = {
              0: pw.FixedColumnWidth(150.0), // Task
              1: pw.FixedColumnWidth(26.0), // W
              2: pw.FixedColumnWidth(30.0), // Hrs
              3: pw.FixedColumnWidth(52.0), // Ind.Ext
              4: pw.FixedColumnWidth(52.0), // Ind.Int
              5: pw.FixedColumnWidth(56.0), // Ind.Total
              6: pw.FixedColumnWidth(52.0), // Coll.Ext
              7: pw.FixedColumnWidth(52.0), // Coll.Int
              8: pw.FixedColumnWidth(42.0), // Coll.Tot
            };
            // total = 150+26+30+52+52+56+52+52+42 = 512 ✓

            final taskTable = pw.Table(
              border: pw.TableBorder.all(color: _pdfHair, width: 0.5),
              columnWidths: tCols,
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _pdfHair2),
                  children: [
                    _pdfTH('Task'),
                    _pdfTH('W', align: pw.TextAlign.center),
                    _pdfTH('Hrs', align: pw.TextAlign.center),
                    _pdfTH('Ind.Ext\n(mrem)', align: pw.TextAlign.right),
                    _pdfTH('Ind.Int\n(mrem)', align: pw.TextAlign.right),
                    _pdfTH('Ind.Total\n(mrem)', align: pw.TextAlign.right),
                    _pdfTH('Coll.Ext\n(p-mrem)', align: pw.TextAlign.right),
                    _pdfTH('Coll.Int\n(p-mrem)', align: pw.TextAlign.right),
                    _pdfTH('Coll.Tot\n(p-mrem)', align: pw.TextAlign.right),
                  ],
                ),
                ...taskSummaries.map((s) {
                  final t = s['task'] as TaskData;
                  return pw.TableRow(
                    children: [
                      _pdfTD(t.title),
                      _pdfTD(t.workers.toString(), align: pw.TextAlign.center),
                      _pdfTD(
                        t.hours.toStringAsFixed(1),
                        align: pw.TextAlign.center,
                      ),
                      _pdfTD(
                        (s['iExt'] as double).toStringAsFixed(2),
                        align: pw.TextAlign.right,
                      ),
                      _pdfTD(
                        formatNumber(s['iInt'] as double),
                        align: pw.TextAlign.right,
                      ),
                      _pdfTD(
                        (s['iTotal'] as double).toStringAsFixed(2),
                        bold: true,
                        align: pw.TextAlign.right,
                      ),
                      _pdfTD(
                        (s['cExt'] as double).toStringAsFixed(2),
                        align: pw.TextAlign.right,
                      ),
                      _pdfTD(
                        formatNumber(s['cInt'] as double),
                        align: pw.TextAlign.right,
                      ),
                      _pdfTD(
                        ((s['cExt'] as double) + (s['cInt'] as double))
                            .toStringAsFixed(2),
                        bold: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }),
              ],
            );

            // ── Signatures ────────────────────────────────────────────────────
            final signatures = pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: _pdfHair, width: 0.8),
                ),
              ),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FixedColumnWidth(20),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FixedColumnWidth(28),
                  4: pw.FlexColumnWidth(3),
                  5: pw.FixedColumnWidth(20),
                  6: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'PREPARER / RCT',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: _pdfInk4,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(),
                      pw.Text(
                        'DATE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: _pdfInk4,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(),
                      alaraTriggered
                          ? pw.Text(
                              'PEER CHECK / ALARA REVIEW',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: _pdfInk4,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            )
                          : pw.SizedBox(),
                      pw.SizedBox(),
                      alaraTriggered
                          ? pw.Text(
                              'DATE',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: _pdfInk4,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            )
                          : pw.SizedBox(),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.SizedBox(height: 22),
                      pw.SizedBox(),
                      pw.SizedBox(),
                      pw.SizedBox(),
                      pw.SizedBox(),
                      pw.SizedBox(),
                      pw.SizedBox(),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(height: 0.8, color: _pdfInk1),
                      pw.SizedBox(),
                      pw.Container(height: 0.8, color: _pdfInk1),
                      pw.SizedBox(),
                      alaraTriggered
                          ? pw.Container(height: 0.8, color: _pdfInk1)
                          : pw.SizedBox(),
                      pw.SizedBox(),
                      alaraTriggered
                          ? pw.Container(height: 0.8, color: _pdfInk1)
                          : pw.SizedBox(),
                    ],
                  ),
                ],
              ),
            );

            return pw.Padding(
              padding: const pw.EdgeInsets.only(top: 0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  headerBar,
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: _pdfM,
                        vertical: 18,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfSectionLabel('Dose Summary'),
                          doseCards,
                          pw.SizedBox(height: 15),
                          _pdfSectionLabel('Requirement Triggers'),
                          pillRow,
                          if (triggerDetail != null) ...[
                            pw.SizedBox(height: 6),
                            triggerDetail!,
                          ],
                          pw.SizedBox(height: 15),
                          _pdfSectionLabel('Task Summary'),
                          taskTable,
                          pw.Flexible(child: pw.SizedBox()),
                          signatures,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // ════════════════════════════════════════════════════════════════════
      // PAGES 2+: Per-task detail
      // ════════════════════════════════════════════════════════════════════
      for (var i = 0; i < taskSummaries.length; i++) {
        final summary = taskSummaries[i];
        final t = summary['task'] as TaskData;
        final totals = summary['totals'] as Map<String, double>;
        final mPIF = computeMPIF(t);
        final cExt = summary['cExt'] as double;
        final cInt = summary['cInt'] as double;
        final iExt = summary['iExt'] as double;
        final iInt = summary['iInt'] as double;
        final iExtrm = summary['iExtrm'] as double;
        final iTotal = summary['iTotal'] as double;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context ctx) {
              // Task sub-header
              final taskHeader = pw.Container(
                width: _pdfPW,
                color: _pdfNavy,
                padding: const pw.EdgeInsets.only(
                  left: _pdfM,
                  top: 34,
                  right: _pdfM,
                  bottom: 10,
                ),
                child: pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.8),
                    1: pw.FlexColumnWidth(1.0),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Task ${i + 1} of ${taskSummaries.length} - ${t.title}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            '$wo  |  $dateStr',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: _pdfNavyLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              // Task info strip (5-column grid)
              const fColW = _pdfCW / 5; // 102.4 each
              final infoStrip = pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: _pdfM,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _pdfHair, width: 0.7),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${t.title}  |  ${t.location}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfInk1,
                      ),
                    ),
                    pw.SizedBox(height: 9),
                    pw.Table(
                      columnWidths: const {
                        0: pw.FixedColumnWidth(fColW),
                        1: pw.FixedColumnWidth(fColW),
                        2: pw.FixedColumnWidth(fColW),
                        3: pw.FixedColumnWidth(fColW),
                        4: pw.FixedColumnWidth(fColW),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            for (final e in [
                              {'l': 'WORKERS', 'v': '${t.workers} persons'},
                              {
                                'l': 'DURATION',
                                'v': '${t.hours.toStringAsFixed(1)} hr',
                              },
                              {
                                'l': 'PERSON-HOURS',
                                'v':
                                    '${(t.workers * t.hours).toStringAsFixed(1)} p-hrs',
                              },
                              {'l': 'DOSE RATE', 'v': '${t.doseRate} mrem/hr'},
                              {
                                'l': 'PROTECTION',
                                'v':
                                    'PFE ${t.pfe == 1.0 ? "1" : t.pfe.toStringAsFixed(0)}  PFR ${t.pfr == 1.0
                                        ? "1"
                                        : t.pfr == 50.0
                                        ? "50 (APR)"
                                        : "1000 (PAPR)"}',
                              },
                            ])
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    e['l']!,
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      color: _pdfInk4,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 3),
                                  pw.Text(
                                    e['v']!,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _pdfInk1,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  taskHeader,
                  infoStrip,
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: _pdfM,
                        vertical: 14,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // ── mPIF ──────────────────────────────────────────
                          _pdfSectionLabel(
                            'mPIF - Material Potential Intake Fraction',
                          ),
                          pw.Container(
                            width: _pdfCW,
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: _pdfSurf2,
                              border: pw.Border.all(
                                color: _pdfHair,
                                width: 0.5,
                              ),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(5),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Table(
                                  columnWidths: const {
                                    0: pw.FixedColumnWidth(85),
                                    1: pw.FixedColumnWidth(85),
                                    2: pw.FixedColumnWidth(85),
                                    3: pw.FixedColumnWidth(85),
                                    4: pw.FixedColumnWidth(85),
                                    5: pw.FixedColumnWidth(75),
                                  },
                                  children: [
                                    pw.TableRow(
                                      children: [
                                        for (final e in [
                                          {
                                            'l': 'R (release)',
                                            'v': t.mpifR?.toString() ?? '-',
                                          },
                                          {
                                            'l': 'C (confinement)',
                                            'v': t.mpifC.toString(),
                                          },
                                          {
                                            'l': 'D (dispersibility)',
                                            'v': t.mpifD.toString(),
                                          },
                                          {
                                            'l': 'S (suspension)',
                                            'v': t.mpifS.toString(),
                                          },
                                          {
                                            'l': 'U (uncontrolled)',
                                            'v': t.mpifU.toString(),
                                          },
                                        ])
                                          pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Text(
                                                e['l']!,
                                                style: pw.TextStyle(
                                                  fontSize: 7.5,
                                                  color: _pdfInk4,
                                                ),
                                              ),
                                              pw.Text(
                                                e['v']!,
                                                style: pw.TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: _pdfInk1,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  'Computed mPIF = 1x10^-6 x R x C x D x O x S x U = ${formatNumber(mPIF)}',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _pdfInk2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          pw.SizedBox(height: 12),

                          // ── External dose ──────────────────────────────────
                          _pdfSectionLabel('External Dose'),
                          pw.Container(
                            width: _pdfCW,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: pw.BoxDecoration(
                              color: _pdfSurf2,
                              border: pw.Border.all(
                                color: _pdfHair,
                                width: 0.5,
                              ),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(5),
                              ),
                            ),
                            child: pw.Table(
                              columnWidths: const {
                                0: pw.FlexColumnWidth(1.0),
                                1: pw.FixedColumnWidth(90),
                                2: pw.FixedColumnWidth(110),
                              },
                              children: [
                                pw.TableRow(
                                  children: [
                                    pw.Text(
                                      '${t.doseRate} mrem/hr x ${t.hours.toStringAsFixed(1)} hr'
                                      '${t.pfr > 1 ? " x 1.15 (resp. penalty)" : ""}'
                                      ' = ${iExt.toStringAsFixed(2)} mrem/person'
                                      '  x  ${t.workers} workers = ${cExt.toStringAsFixed(2)} person-mrem',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: _pdfInk2,
                                      ),
                                    ),
                                    pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.end,
                                      children: [
                                        pw.Text(
                                          'INDIVIDUAL',
                                          style: pw.TextStyle(
                                            fontSize: 7,
                                            color: _pdfInk4,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Text(
                                          iExt.toStringAsFixed(2),
                                          style: pw.TextStyle(
                                            fontSize: 17,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _pdfInk1,
                                          ),
                                        ),
                                        pw.Text(
                                          'mrem',
                                          style: pw.TextStyle(
                                            fontSize: 7.5,
                                            color: _pdfInk4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.end,
                                      children: [
                                        pw.Text(
                                          'COLLECTIVE',
                                          style: pw.TextStyle(
                                            fontSize: 7,
                                            color: _pdfInk4,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.Text(
                                          cExt.toStringAsFixed(2),
                                          style: pw.TextStyle(
                                            fontSize: 17,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _pdfInk1,
                                          ),
                                        ),
                                        pw.Text(
                                          'person-mrem',
                                          style: pw.TextStyle(
                                            fontSize: 7.5,
                                            color: _pdfInk4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Internal / Nuclide Dose ────────────────────────
                          if (t.nuclides.isNotEmpty) ...[
                            pw.SizedBox(height: 12),
                            _pdfSectionLabel(
                              'Internal Dose - Radionuclide Contamination',
                            ),
                            pw.Table(
                              border: pw.TableBorder.all(
                                color: _pdfHair,
                                width: 0.5,
                              ),
                              columnWidths: const {
                                0: pw.FixedColumnWidth(68),
                                1: pw.FixedColumnWidth(84),
                                2: pw.FixedColumnWidth(84),
                                3: pw.FixedColumnWidth(76),
                                4: pw.FixedColumnWidth(80),
                                5: pw.FixedColumnWidth(70),
                                6: pw.FixedColumnWidth(50),
                              },
                              children: [
                                pw.TableRow(
                                  decoration: pw.BoxDecoration(
                                    color: _pdfHair2,
                                  ),
                                  children: [
                                    _pdfTH('Nuclide'),
                                    _pdfTH(
                                      'Contam\n(dpm/100cm2)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'Air Conc\n(uCi/mL)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'DAC\n(uCi/mL)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'DAC Fraction\n(post-PFE)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'Coll. Dose\n(p-mrem)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'Ind. Dose\n(mrem)',
                                      align: pw.TextAlign.right,
                                    ),
                                  ],
                                ),
                                ...t.nuclides.map((n) {
                                  final res = computeNuclideDose(n, t);
                                  final nColl = res['collective'] ?? 0.0;
                                  final nInd = t.workers > 0
                                      ? nColl / t.workers
                                      : 0.0;
                                  return pw.TableRow(
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 4,
                                        ),
                                        child: pw.Text(
                                          n.name ?? '-',
                                          style: pw.TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _pdfInk1,
                                          ),
                                        ),
                                      ),
                                      _pdfTD(
                                        formatNumber(n.contam),
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(res['airConc'] ?? 0),
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(res['dac'] ?? 0),
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(
                                          res['dacFractionEngOnly'] ?? 0,
                                        ),
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(nColl),
                                        bold: true,
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(nInd),
                                        align: pw.TextAlign.right,
                                      ),
                                    ],
                                  );
                                }),
                                if (t.nuclides.length > 1)
                                  pw.TableRow(
                                    decoration: pw.BoxDecoration(
                                      color: _pdfHair2,
                                    ),
                                    children: [
                                      _pdfTD('TOTAL', bold: true),
                                      _pdfTD('', align: pw.TextAlign.right),
                                      _pdfTD('', align: pw.TextAlign.right),
                                      _pdfTD('', align: pw.TextAlign.right),
                                      _pdfTD(
                                        formatNumber(
                                          totals['totalDacFractionEngOnly'] ??
                                              0,
                                        ),
                                        bold: true,
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(cInt),
                                        bold: true,
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        formatNumber(iInt),
                                        bold: true,
                                        align: pw.TextAlign.right,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            pw.SizedBox(height: 3),
                            pw.Container(
                              width: _pdfCW,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: _pdfHair2,
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4),
                                ),
                              ),
                              child: pw.Text(
                                'Air conc = (contam/100) x mPIF x (1/100) x (1/2.22x10^6) uCi/mL'
                                '    DAC Fr = air conc / DAC / PFE'
                                '    Coll. dose = DAC Fr(eng) x (p-hrs/2000) x 5000 / PFR'
                                '    mPIF = ${formatNumber(mPIF)}',
                                style: pw.TextStyle(
                                  fontSize: 6.5,
                                  color: _pdfInk3,
                                ),
                              ),
                            ),
                          ],

                          // ── Extremity dose ─────────────────────────────────
                          if (t.extremities.isNotEmpty) ...[
                            pw.SizedBox(height: 12),
                            _pdfSectionLabel('Extremity / Skin Dose'),
                            pw.Table(
                              border: pw.TableBorder.all(
                                color: _pdfHair,
                                width: 0.5,
                              ),
                              columnWidths: const {
                                0: pw.FixedColumnWidth(128),
                                1: pw.FixedColumnWidth(128),
                                2: pw.FixedColumnWidth(128),
                                3: pw.FixedColumnWidth(128),
                              },
                              children: [
                                pw.TableRow(
                                  decoration: pw.BoxDecoration(
                                    color: _pdfHair2,
                                  ),
                                  children: [
                                    _pdfTH('Nuclide'),
                                    _pdfTH(
                                      'Dose Rate (mrem/hr)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'Time (hr)',
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTH(
                                      'Ind. Dose (mrem)',
                                      align: pw.TextAlign.right,
                                    ),
                                  ],
                                ),
                                ...t.extremities.map(
                                  (e) => pw.TableRow(
                                    children: [
                                      _pdfTD(e.nuclide ?? '-'),
                                      _pdfTD(
                                        e.doseRate.toStringAsFixed(2),
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        e.time.toStringAsFixed(2),
                                        align: pw.TextAlign.right,
                                      ),
                                      _pdfTD(
                                        (e.doseRate * e.time).toStringAsFixed(
                                          2,
                                        ),
                                        bold: true,
                                        align: pw.TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

                          pw.SizedBox(height: 12),

                          // ── Task Dose Totals ───────────────────────────────
                          _pdfSectionLabel('Task Dose Totals'),
                          pw.Table(
                            border: pw.TableBorder.all(
                              color: _pdfHair,
                              width: 0.5,
                            ),
                            columnWidths: const {
                              0: pw.FixedColumnWidth(160),
                              1: pw.FixedColumnWidth(88),
                              2: pw.FixedColumnWidth(88),
                              3: pw.FixedColumnWidth(88),
                              4: pw.FixedColumnWidth(88),
                            },
                            children: [
                              pw.TableRow(
                                decoration: pw.BoxDecoration(color: _pdfHair2),
                                children: [
                                  _pdfTH('Dose Component'),
                                  _pdfTH(
                                    'Ind. Ext\n(mrem)',
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTH(
                                    'Ind. Int\n(mrem)',
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTH(
                                    'Coll. Ext\n(p-mrem)',
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTH(
                                    'Coll. Int\n(p-mrem)',
                                    align: pw.TextAlign.right,
                                  ),
                                ],
                              ),
                              pw.TableRow(
                                children: [
                                  _pdfTD('External Effective'),
                                  _pdfTD(
                                    iExt.toStringAsFixed(2),
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTD('-', align: pw.TextAlign.right),
                                  _pdfTD(
                                    cExt.toStringAsFixed(2),
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTD('-', align: pw.TextAlign.right),
                                ],
                              ),
                              pw.TableRow(
                                children: [
                                  _pdfTD('Internal Effective'),
                                  _pdfTD('-', align: pw.TextAlign.right),
                                  _pdfTD(
                                    formatNumber(iInt),
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTD('-', align: pw.TextAlign.right),
                                  _pdfTD(
                                    formatNumber(cInt),
                                    align: pw.TextAlign.right,
                                  ),
                                ],
                              ),
                              pw.TableRow(
                                decoration: pw.BoxDecoration(color: _pdfHair2),
                                children: [
                                  _pdfTD('TOTAL Effective', bold: true),
                                  _pdfTD(
                                    iExt.toStringAsFixed(2),
                                    bold: true,
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTD(
                                    formatNumber(iInt),
                                    bold: true,
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTD(
                                    cExt.toStringAsFixed(2),
                                    bold: true,
                                    align: pw.TextAlign.right,
                                  ),
                                  _pdfTD(
                                    formatNumber(cInt),
                                    bold: true,
                                    align: pw.TextAlign.right,
                                  ),
                                ],
                              ),
                              if (iExtrm > 0)
                                pw.TableRow(
                                  children: [
                                    _pdfTD('Extremity / Skin'),
                                    _pdfTD(
                                      iExtrm.toStringAsFixed(2),
                                      align: pw.TextAlign.right,
                                    ),
                                    _pdfTD('-', align: pw.TextAlign.right),
                                    _pdfTD('-', align: pw.TextAlign.right),
                                    _pdfTD('-', align: pw.TextAlign.right),
                                  ],
                                ),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          // Limits note
                          pw.Text(
                            'Limits: Individual effective 500 mrem/yr  |  Collective effective 750 person-mrem/yr'
                            '${iExtrm > 0 ? "  |  Extremity/skin 5,000 mrem/yr" : ""}',
                            style: pw.TextStyle(fontSize: 7.5, color: _pdfInk4),
                          ),
                          if ((totals['respiratorPenalty'] ?? 1.0) > 1.0) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Note: External dose includes 15% respirator penalty (x1.15).',
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                color: _pdfInk3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Print
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Print dialog opened')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
      }
    }
  }

  Widget buildSummary() {
    final finalTriggers = getFinalTriggerStates();

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.playlist_add_check_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use "Add Task" above to begin.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    double totalCollectiveExternal = 0.0;
    double totalCollectiveInternal = 0.0;

    double totalIndividual = 0.0;
    for (final t in tasks) {
      final totals = calculateTaskTotals(t);
      totalCollectiveExternal += totals['collectiveExternal']!;
      totalCollectiveInternal += totals['collectiveInternal']!;
      totalIndividual += totals['individualEffective']!;
    }
    final totalCollective = totalCollectiveExternal + totalCollectiveInternal;
    final totalIndivExtremity = tasks.fold<double>(
      0,
      (s, t) => s + calculateTaskTotals(t)['individualExtremity']!,
    );
    final totalCollExtremity = tasks.fold<double>(
      0,
      (s, t) => s + calculateTaskTotals(t)['collectiveExtremity']!,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _kDarkSurface : _kSurface;
    final hairline = isDark ? _kDarkHairline : _kHairline;
    final ink1 = isDark ? _kDarkInk1 : _kInk1;
    final ink2 = isDark ? _kDarkInk2 : _kInk2;
    final ink3 = isDark ? _kDarkInk3 : _kInk3;
    final ink4 = isDark ? _kDarkInk4 : _kInk4;

    final indivStatus = totalIndividual > 500
        ? 'danger'
        : totalIndividual > 250
        ? 'warn'
        : 'pass';
    final collStatus = totalCollective > 750
        ? 'danger'
        : totalCollective > 400
        ? 'warn'
        : 'pass';

    Color _summaryColor(String st) => st == 'danger'
        ? _kDanger
        : st == 'warn'
        ? _kWarn
        : _kOk;
    Color _summaryWash(String st) => st == 'danger'
        ? _kDangerWash
        : st == 'warn'
        ? _kWarnWash
        : _kOkWash;

    Widget summaryBig(
      String label,
      String value,
      String unit,
      String status,
      String subLabel,
      double pct,
    ) {
      final col = _summaryColor(status);
      final wash = isDark ? col.withValues(alpha: 0.12) : _summaryWash(status);
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: wash,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.withValues(alpha: isDark ? 0.3 : 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: col.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: col,
                    fontFamily: 'Courier',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: col.withValues(alpha: 0.6),
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 11.5,
                color: col.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: col,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Center content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 28, 36, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUMMARY',
                          style: TextStyle(
                            fontSize: 12,
                            color: ink3,
                            fontFamily: 'Courier',
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dose assessment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: ink1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tasks.length} task${tasks.length != 1 ? "s" : ""} · ${formatNumber(tasks.fold(0.0, (s, t) => s + t.workers * t.hours))} person-hours',
                          style: TextStyle(fontSize: 12, color: ink3),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _StatusBadge(
                          label: 'ALARA Review',
                          triggered: finalTriggers['alaraReview'] == true,
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: 'Air Sampling',
                          triggered: finalTriggers['airSampling'] == true,
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: 'CAMs',
                          triggered: finalTriggers['camsRequired'] == true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Headline numbers (2 big cards)
                Row(
                  children: [
                    Expanded(
                      child: summaryBig(
                        'Max individual effective dose',
                        formatNumber(totalIndividual),
                        'mrem',
                        indivStatus,
                        'Threshold 500 mrem',
                        totalIndividual / 500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: summaryBig(
                        'Collective dose',
                        formatNumber(totalCollective),
                        'person-mrem',
                        collStatus,
                        'Threshold 750 person-mrem',
                        totalCollective / 750,
                      ),
                    ),
                  ],
                ),

                // Extremity dose cards — shown only when any task has extremity dose
                if (totalCollExtremity > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: summaryBig(
                          'Individual extremity dose',
                          formatNumber(totalIndivExtremity),
                          'mrem',
                          totalIndivExtremity > 5000
                              ? 'danger'
                              : totalIndivExtremity > 2500
                              ? 'warn'
                              : 'pass',
                          'Threshold 5,000 mrem (ALARA)',
                          totalIndivExtremity / 5000,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: summaryBig(
                          'Collective extremity dose',
                          formatNumber(totalCollExtremity),
                          'person-mrem',
                          'pass',
                          'Extremity / skin dose',
                          0,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),

                // Tasks table
                Row(
                  children: [
                    Text(
                      'TASKS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ink3,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Click a row to edit',
                      style: TextStyle(fontSize: 11.5, color: ink4),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hairline),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? _kDarkSurface2 : _kSurface2,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          border: Border(bottom: BorderSide(color: hairline)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: ink3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TASK',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: ink3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                'P-HRS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: ink3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                'mPIF',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: ink3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Text(
                                'INDIV DOSE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: ink3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                'DAC-HRS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: ink3,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...tasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final t = entry.value;
                        final tots = calculateTaskTotals(t);
                        final indiv = t.workers > 0
                            ? tots['collectiveEffective']! / t.workers
                            : 0.0;
                        final indivExtrm = tots['individualExtremity'] ?? 0.0;
                        final dacHrs =
                            (tots['totalDacFractionWithResp'] ?? 0.0) * t.hours;
                        final mPIF = tots['mPIF']!;
                        return GestureDetector(
                          onTap: () => setState(() => _activeIdx = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: hairline.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${(i + 1).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ink4,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title.isEmpty ? 'Untitled' : t.title,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: ink1,
                                        ),
                                      ),
                                      if (t.location.isNotEmpty)
                                        Text(
                                          t.location,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ink3,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    formatNumber(tots['personHours']!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ink2,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    mPIF == 0
                                        ? '—'
                                        : mPIF.toStringAsExponential(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ink2,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${formatNumber(indiv)} mrem',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ink2,
                                          fontFamily: 'Courier',
                                        ),
                                      ),
                                      if (indivExtrm > 0)
                                        Text(
                                          '+${formatNumber(indivExtrm)} extrm',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: ink3,
                                            fontFamily: 'Courier',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    formatNumber(dacHrs),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ink2,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Triggers
                buildTriggers(),
              ],
            ),
          ),
        ),

        // Right column (work order info)
        SizedBox(
          width: 380,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              border: Border(left: BorderSide(color: hairline)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: hairline)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'WORK ORDER',
                        style: TextStyle(
                          fontSize: 11,
                          color: ink3,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NUMBER',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: ink4,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workOrderController.text.isEmpty
                                ? '—'
                                : workOrderController.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ink1,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'DESCRIPTION',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: ink4,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            descriptionController.text.isEmpty
                                ? '—'
                                : descriptionController.text,
                            style: TextStyle(fontSize: 13, color: ink1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'DATE',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: ink4,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateController.text.isEmpty
                                ? '—'
                                : dateController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: ink1,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(height: 1, color: hairline),
                          const SizedBox(height: 16),
                          Text(
                            'EXPORT',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: ink4,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: printSummaryReport,
                              icon: const Icon(Icons.print_outlined, size: 14),
                              label: const Text('Print full report (PDF)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ink1,
                                foregroundColor: isDark ? _kDarkBg : _kBg,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: saveToFile,
                              icon: const Icon(Icons.save_outlined, size: 14),
                              label: const Text('Save as JSON'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ink2,
                                side: BorderSide(color: hairline),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void showDebugInfo() {
    // Diagnostic dialog: show per-nuclide computed fields for the first task (or a sample)
    final t = tasks.isNotEmpty
        ? tasks.first
        : TaskData(
            title: 'Sample',
            location: 'Lab',
            workers: 1,
            hours: 15.0,
            mpifR: 1.0,
            mpifC: 100.0,
            mpifD: 1.0,
            mpifO: 1.0,
            mpifS: 1.0,
            mpifU: 1.0,
            doseRate: 0.0,
            pfr: 1.0,
            pfe: 1.0,
            nuclides: [NuclideEntry(name: 'Sr-90', contam: 100000.0)],
          );
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
      rows.add(
        Text('  DAC fraction (after PFE): ${eng.toStringAsExponential(6)}'),
      );
      rows.add(
        Text(
          '  Collective internal dose: ${collective.toStringAsExponential(6)}',
        ),
      );
      rows.add(
        Text(
          '  Individual internal dose: ${individual.toStringAsExponential(6)}',
        ),
      );
      rows.add(const SizedBox(height: 6));
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Per-nuclide Diagnostics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Active view: -1 = summary, 0..n-1 = task index
  int _activeIdx = -1;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _kDarkSurface : _kSurface;
    final surface2 = isDark ? _kDarkSurface2 : _kSurface2;
    final hairline = isDark ? _kDarkHairline : _kHairline;
    final ink1 = isDark ? _kDarkInk1 : _kInk1;
    final ink2 = isDark ? _kDarkInk2 : _kInk2;
    final ink3 = isDark ? _kDarkInk3 : _kInk3;
    final ink4 = isDark ? _kDarkInk4 : _kInk4;
    final bg = isDark ? _kDarkBg : _kBg;

    // Clamp active index if tasks were deleted
    if (_activeIdx >= tasks.length)
      _activeIdx = tasks.isEmpty ? -1 : tasks.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Work order strip ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: surface2,
            border: Border(bottom: BorderSide(color: hairline)),
          ),
          child: Row(
            children: [
              _WorkField(
                label: 'Work Order',
                controller: workOrderController,
                onChanged: () => setState(() {}),
              ),
              _WorkDivider(color: hairline),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _WorkFieldRaw(
                    label: 'Description',
                    controller: descriptionController,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
              _WorkDivider(color: hairline),
              _WorkField(
                label: 'Date',
                controller: dateController,
                onChanged: () => setState(() {}),
              ),
              _WorkDivider(color: hairline),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREPARER',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: ink4,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workOrderController.text.isEmpty ? '—' : 'See work order',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ink1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── 3-column workspace ───────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left rail (260px)
              SizedBox(
                width: 260,
                child: Container(
                  decoration: BoxDecoration(
                    color: surface2,
                    border: Border(right: BorderSide(color: hairline)),
                  ),
                  child: Column(
                    children: [
                      // Summary item
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeIdx = -1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: ink1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Summary',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: bg,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'All tasks · triggers',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: bg.withOpacity(0.7),
                                          fontFamily: 'Courier',
                                          letterSpacing: 0.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: bg.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tasks header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Row(
                          children: [
                            Text(
                              'TASKS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ink3,
                                letterSpacing: 0.08,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A27)
                                    : _kSurface3,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${tasks.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ink3,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Task list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          itemCount: tasks.length,
                          itemBuilder: (ctx, i) {
                            final t = tasks[i];
                            final totals = calculateTaskTotals(t);
                            final indiv = t.workers > 0
                                ? (totals['collectiveEffective']! / t.workers)
                                : 0.0;
                            final triggered = indiv > 500;
                            final active = _activeIdx == i;
                            return GestureDetector(
                              onTap: () => setState(() => _activeIdx = i),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: EdgeInsets.fromLTRB(
                                  triggered ? 10 : 12,
                                  10,
                                  12,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: active ? surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: triggered
                                        ? const BorderSide(
                                            color: _kDanger,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                    right: active
                                        ? BorderSide(color: hairline)
                                        : BorderSide.none,
                                    top: active
                                        ? BorderSide(color: hairline)
                                        : BorderSide.none,
                                    bottom: active
                                        ? BorderSide(color: hairline)
                                        : BorderSide.none,
                                  ),
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t.title.isEmpty
                                                ? 'Untitled task'
                                                : t.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: t.title.isEmpty
                                                  ? ink4
                                                  : ink1,
                                              fontStyle: t.title.isEmpty
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2A2A27)
                                                : _kSurface3,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: Text(
                                            '#${(i + 1).toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: ink4,
                                              fontFamily: 'Courier',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${t.workers}p · ${t.hours}hr',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ink3,
                                          ),
                                        ),
                                        Text(
                                          ' · ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ink4,
                                          ),
                                        ),
                                        Text(
                                          formatNumber(indiv),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ink2,
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          ' mrem',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ink4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Add task button
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: hairline)),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            addTask();
                            widget.onTaskCountChanged?.call();
                            setState(() => _activeIdx = tasks.length - 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hairline,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 13, color: ink3),
                                const SizedBox(width: 6),
                                Text(
                                  'Add task',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center + right panel
              Expanded(
                child: _activeIdx < 0
                    ? buildSummary()
                    : (_activeIdx < tasks.length
                          ? buildTaskTab(_activeIdx)
                          : const SizedBox()),
              ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Air Sampling Triggers'),
        const SizedBox(height: 10),
        _InfoCard(
          child: Column(
            children: [
              triggerRow(
                'sampling1',
                'Worker likely to exceed 40 DAC-hours per year',
              ),
              triggerRow('sampling2', 'Respiratory protection prescribed'),
              triggerRow(
                'sampling3',
                'Air sample needed to estimate internal dose',
              ),
              triggerRow('sampling4', 'Estimated intake > 10% ALI or 500 mrem'),
              triggerRow(
                'sampling5',
                'Airborne concentration > 0.3 DAC avg or >1 DAC spike',
              ),
              triggerRow(
                'camsRequired',
                'CAMs required (worker > 40 DAC-hrs/week)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'ALARA Review Triggers'),
        const SizedBox(height: 10),
        _InfoCard(
          child: Column(
            children: [
              triggerRow('alara1', 'Non-routine or complex work'),
              triggerRow(
                'alara2',
                'Individual total effective dose > 500 mrem',
              ),
              triggerRow(
                'alara3',
                'Individual extremity/skin dose > 5,000 mrem',
              ),
              triggerRow('alara4', 'Collective dose > 750 person-mrem'),
              triggerRow(
                'alara5',
                'Airborne >200 DAC avg over 1 hr or spike >1,000 DAC',
              ),
              triggerRow(
                'alara6',
                'Removable contamination > 1,000× Appendix D levels',
              ),
              triggerRow(
                'alara7',
                'Worker likely to receive internal dose > 100 mrem',
              ),
              triggerRow('alara8', 'Dose rates > 10 rem/hr at 30 cm'),
            ],
          ),
        ),
      ],
    );
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
        initiallyExpanded:
            t.sectionExpansionStates[stateKey] ?? defaultExpanded,
        onExpansionChanged: (v) =>
            setState(() => t.sectionExpansionStates[stateKey] = v),
        child: child,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Center content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 28, 36, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Task header ────────────────────────────────────────────────────
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: t.titleController,
                              focusNode: t.titleFocusNode,
                              autofocus: t.titleController.text.isEmpty,
                              decoration: const InputDecoration(
                                labelText: 'Task Title',
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: t.locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Time estimation ────────────────────────────────────────────────
                section(
                  title: 'Time Estimation',
                  stateKey: 'timeEstimation',
                  defaultExpanded: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: t.workersController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_NonNegativeFormatter()],
                          decoration: _numericDecoration(
                            const InputDecoration(labelText: '# Workers'),
                            (int.tryParse(t.workersController.text) ?? 0) < 0,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: t.hoursController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [_NonNegativeFormatter()],
                          decoration: _numericDecoration(
                            const InputDecoration(labelText: 'Hours Each'),
                            (double.tryParse(t.hoursController.text) ?? 0) < 0,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(
                          label: 'Person-Hours',
                          value: totals['personHours']!.toStringAsFixed(2),
                          color: _kAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── mPIF ───────────────────────────────────────────────────────────
                section(
                  title: 'mPIF Calculation',
                  stateKey: 'mpifCalculation',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: t.mpifR,
                              decoration: const InputDecoration(
                                labelText: 'Release Factor (R)',
                                hintText: 'Select R',
                              ),
                              items: releaseFactors.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.value,
                                      child: Text(e.key),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                t.mpifR = v;
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: t.mpifC > 0.0 ? t.mpifC : null,
                              decoration: const InputDecoration(
                                labelText: 'Confinement Factor (C)',
                                hintText: 'Select C',
                              ),
                              items: confinementFactors.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.value,
                                      child: Text(e.key),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                t.mpifC = v ?? 0.0;
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: t.mpifD > 0 ? t.mpifD : null,
                              decoration: const InputDecoration(
                                labelText: 'Dispersibility (D)',
                                hintText: 'Select D',
                              ),
                              items: const [1.0, 10.0]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        v == 1.0
                                            ? 'No added dispersibility (1)'
                                            : 'Enhanced dispersibility (10)',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  t.mpifD = v;
                                  t.mpifDController.text = v.toString();
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: t.mpifU > 0 ? t.mpifU.toInt() : null,
                              decoration: const InputDecoration(
                                labelText: 'Uncertainty (U)',
                                hintText: 'Select U',
                              ),
                              items: List.generate(10, (i) => i + 1)
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text('$v'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  t.mpifU = v.toDouble();
                                  t.mpifUController.text = v.toString();
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: t.mpifS > 0 ? t.mpifS : null,
                              decoration: const InputDecoration(
                                labelText: 'Special Form (S)',
                                hintText: 'Select S',
                              ),
                              items: [0.1, 1.0]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  t.mpifS = v;
                                  t.mpifSController.text = v.toString();
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Tooltip(
                              message: 'mPIF = 1e-6 × R × C × D × O × S × U',
                              child: _MiniStat(
                                label: 'mPIF Result',
                                value: totals['mPIF']! > 0
                                    ? totals['mPIF']!.toStringAsExponential(2)
                                    : '—',
                                color: _kAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InfoNote(
                        text:
                            'Refer to Attachment A of HPP 9.1 for mPIF factor details.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── External dose ──────────────────────────────────────────────────
                section(
                  title: 'External Dose Estimate',
                  stateKey: 'externalDose',
                  child: Column(
                    children: [
                      TextField(
                        controller: t.doseRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_NonNegativeFormatter()],
                        decoration: _numericDecoration(
                          const InputDecoration(labelText: 'Dose Rate (mrem/hr)'),
                          (double.tryParse(t.doseRateController.text) ?? 0) < 0,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Person-Hours',
                              value: totals['personHours']!.toStringAsFixed(2),
                              color: _kOk,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Individual External',
                              value: (t.workers > 0
                                      ? totals['collectiveExternal']! / t.workers
                                      : 0.0)
                                  .toStringAsFixed(2),
                              unit: 'mrem/person',
                              color: _kAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Collective External',
                              value: totals['collectiveExternal']!
                                  .toStringAsFixed(2),
                              unit: 'mrem',
                              color: _kAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Extremity dose ─────────────────────────────────────────────────
                section(
                  title: 'Extremity / Skin Dose',
                  stateKey: 'extremityDose',
                  child: Column(
                    children: [
                      ...List.generate(t.extremities.length, (ei) {
                        final e = t.extremities[ei];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Autocomplete<String>(
                                  optionsBuilder: (v) {
                                    final all = [
                                      'Other',
                                      'Various',
                                      ...NuclideData.dacValues.keys,
                                    ];
                                    return v.text.isEmpty
                                        ? all
                                        : all.where(
                                            (k) => k.toLowerCase().contains(
                                              v.text.toLowerCase(),
                                            ),
                                          );
                                  },
                                  optionsViewBuilder:
                                      (ctx, onSelected, options) => Material(
                                        elevation: 4,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (_, i) => ListTile(
                                              dense: true,
                                              title: Text(options.elementAt(i)),
                                              onTap: () => onSelected(
                                                options.elementAt(i),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  onSelected: (s) {
                                    e.nuclide = s;
                                    setState(() {});
                                  },
                                  fieldViewBuilder: (ctx, ctrl, fn, onFieldSubmitted) {
                                    ctrl.text = e.nuclide ?? '';
                                    final all = [
                                      'Other',
                                      'Various',
                                      ...NuclideData.dacValues.keys,
                                    ];
                                    void commitTopMatch() {
                                      final query = ctrl.text.trim();
                                      if (query.isEmpty) return;
                                      final matches = all.where(
                                        (k) => k.toLowerCase().contains(query.toLowerCase()),
                                      );
                                      if (matches.isNotEmpty) {
                                        e.nuclide = matches.first;
                                        ctrl.text = matches.first;
                                        onFieldSubmitted();
                                        setState(() {});
                                      }
                                    }
                                    return TextField(
                                      controller: ctrl,
                                      focusNode: fn,
                                      decoration: const InputDecoration(
                                        hintText: 'Nuclide',
                                      ),
                                      onSubmitted: (_) => commitTopMatch(),
                                      onEditingComplete: commitTopMatch,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: e.doseRateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [_NonNegativeFormatter()],
                                  decoration: _numericDecoration(
                                    const InputDecoration(labelText: 'Dose Rate (mrem/hr)'),
                                    (double.tryParse(e.doseRateController.text) ?? 0) < 0,
                                  ),
                                  onChanged: (v) => setState(() {
                                    e.doseRate = double.tryParse(v) ?? 0.0;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: e.timeController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [_NonNegativeFormatter()],
                                  decoration: _numericDecoration(
                                    const InputDecoration(labelText: 'Time (hr)'),
                                    (double.tryParse(e.timeController.text) ?? 0) < 0,
                                  ),
                                  onChanged: (v) => setState(() {
                                    e.time = double.tryParse(v) ?? 0.0;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => setState(() {
                                  e.disposeControllers();
                                  t.extremities.removeAt(ei);
                                }),
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: _kDanger,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            t.extremities.add(ExtremityEntry());
                          }),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Extremity Dose'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Individual Extremity',
                              value: totals['individualExtremity']!
                                  .toStringAsFixed(2),
                              unit: 'mrem/person',
                              color: _kWarn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStat(
                              label: 'Collective Extremity',
                              value: totals['collectiveExtremity']!
                                  .toStringAsFixed(2),
                              unit: 'mrem',
                              color: _kWarn,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Protection factors ─────────────────────────────────────────────
                section(
                  title: 'Protection Factors',
                  stateKey: 'protectionFactors',
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Respiratory (PFR)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            RadioListTile<double>(
                              value: 1.0,
                              groupValue: t.pfr,
                              title: const Text(
                                'None (PFR=1)',
                                style: TextStyle(fontSize: 13),
                              ),
                              dense: true,
                              onChanged: (v) {
                                t.pfr = v!;
                                setState(() {});
                              },
                            ),
                            RadioListTile<double>(
                              value: 50.0,
                              groupValue: t.pfr,
                              title: const Text(
                                'APR (PFR=50)',
                                style: TextStyle(fontSize: 13),
                              ),
                              dense: true,
                              onChanged: (v) {
                                t.pfr = v!;
                                setState(() {});
                              },
                            ),
                            RadioListTile<double>(
                              value: 1000.0,
                              groupValue: t.pfr,
                              title: const Text(
                                'PAPR (PFR=1000)',
                                style: TextStyle(fontSize: 13),
                              ),
                              dense: true,
                              onChanged: (v) {
                                t.pfr = v!;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Engineering (PFE)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            RadioListTile<double>(
                              value: 1.0,
                              groupValue: t.pfe,
                              title: const Text(
                                'No Controls (PFE=1)',
                                style: TextStyle(fontSize: 13),
                              ),
                              dense: true,
                              onChanged: (v) {
                                t.pfe = v!;
                                setState(() {});
                              },
                            ),
                            RadioListTile<double>(
                              value: 1000.0,
                              groupValue: t.pfe,
                              title: const Text(
                                'Type I (PFE=1,000)',
                                style: TextStyle(fontSize: 13),
                              ),
                              dense: true,
                              onChanged: (v) {
                                t.pfe = v!;
                                setState(() {});
                              },
                            ),
                            RadioListTile<double>(
                              value: 100000.0,
                              groupValue: t.pfe,
                              title: const Text(
                                'Type II (PFE=100,000)',
                                style: TextStyle(fontSize: 13),
                              ),
                              dense: true,
                              onChanged: (v) {
                                t.pfe = v!;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Internal dose ──────────────────────────────────────────────────
                section(
                  title: 'Internal Dose Calculation',
                  stateKey: 'internalDose',
                  child: Column(
                    children: [
                      ...List.generate(t.nuclides.length, (ni) {
                        final n = t.nuclides[ni];
                        final res = computeNuclideDose(n, t);
                        final dac = res['dac'] ?? 1e-12;
                        final airConc = res['airConc'] ?? 0.0;
                        final dacFrEng = res['dacFractionEngOnly'] ?? 0.0;
                        final nuclideCollective = res['collective'] ?? 0.0;
                        final nuclideIndiv = res['individual'] ?? 0.0;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Focus(
                                    // When focus leaves the entire autocomplete
                                    // subtree (field + dropdown), revert the
                                    // displayed text to the last confirmed name.
                                    onFocusChange: (hasFocus) {
                                      if (!hasFocus) {
                                        setState(() {});
                                      }
                                    },
                                    child: Autocomplete<String>(
                                      initialValue: TextEditingValue(
                                        text: n.name ?? '',
                                      ),
                                      optionsBuilder: (v) => v.text.isEmpty
                                          ? NuclideData.dacValues.keys
                                          : NuclideData.dacValues.keys.where(
                                              (k) => k.toLowerCase().contains(
                                                v.text.toLowerCase(),
                                              ),
                                            ),
                                      optionsViewBuilder:
                                          (ctx, onSelected, options) => Material(
                                            elevation: 4,
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxHeight: 200,
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: options.length,
                                                itemBuilder: (_, i) {
                                                  final opt = options.elementAt(
                                                    i,
                                                  );
                                                  final d =
                                                      NuclideData
                                                          .dacValues[opt] ??
                                                      1e-12;
                                                  return ListTile(
                                                    dense: true,
                                                    title: Text(opt),
                                                    subtitle: opt == 'Other'
                                                        ? const Text('Custom DAC')
                                                        : Text(
                                                            'DAC: ${formatNumber(d)}',
                                                          ),
                                                    onTap: () => onSelected(opt),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                      onSelected: (s) {
                                        n.name = s;
                                        if (s != 'Other') {
                                          n.customDAC = null;
                                          n.dacController.clear();
                                        }
                                        setState(() {});
                                      },
                                      fieldViewBuilder: (ctx, ctrl, fn, onFieldSubmitted) {
                                        if (!fn.hasFocus) {
                                          ctrl.text = n.name ?? '';
                                        }
                                        void commitTopMatch() {
                                          final query = ctrl.text.trim();
                                          if (query.isEmpty) return;
                                          final matches = NuclideData.dacValues.keys.where(
                                            (k) => k.toLowerCase().contains(query.toLowerCase()),
                                          );
                                          if (matches.isNotEmpty) {
                                            n.name = matches.first;
                                            if (matches.first != 'Other') { n.customDAC = null; n.dacController.clear(); }
                                            ctrl.text = matches.first;
                                            onFieldSubmitted();
                                            setState(() {});
                                          }
                                        }
                                        return TextField(
                                          controller: ctrl,
                                          focusNode: fn,
                                          decoration: const InputDecoration(
                                            labelText: 'Nuclide',
                                            hintText: 'Select radionuclide',
                                          ),
                                          onSubmitted: (_) => commitTopMatch(),
                                          onEditingComplete: commitTopMatch,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    // Key forces rebuild when nuclide changes so
                                    // the read-only display always shows the
                                    // correct DAC for the selected nuclide.
                                    key: ValueKey('dac_${n.name}_$ni'),
                                    controller: n.name == 'Other'
                                        ? n.dacController
                                        : TextEditingController(
                                            text: n.name != null
                                                ? formatNumber(dac)
                                                : '',
                                          ),
                                    readOnly: n.name != 'Other',
                                    enabled: n.name == 'Other',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9eE+\-\.]'),
                                      ),
                                      _NonNegativeFormatter(),
                                    ],
                                    decoration: _numericDecoration(
                                      InputDecoration(
                                        labelText: 'DAC (µCi/mL)',
                                        hintText: n.name == 'Other'
                                            ? 'Enter custom DAC'
                                            : (n.name == null
                                                  ? 'Select nuclide'
                                                  : ''),
                                      ),
                                      n.name == 'Other' &&
                                          (double.tryParse(n.dacController.text) ?? 0) < 0,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: n.contamController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9eE+\-\.]'),
                                      ),
                                      _NonNegativeFormatter(),
                                    ],
                                    decoration: _numericDecoration(
                                      const InputDecoration(
                                        labelText: 'Contam. (dpm/100cm²)',
                                      ),
                                      (double.tryParse(n.contamController.text) ?? 0) < 0,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() {
                                    n.disposeControllers();
                                    t.nuclides.removeAt(ni);
                                  }),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: _kDanger,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _InfoCard(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Air Conc.',
                                      value: airConc.isFinite
                                          ? airConc.toStringAsExponential(3)
                                          : '0',
                                      color: _kAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'DAC Frac. (post-PFE)',
                                      value: dacFrEng.isFinite
                                          ? formatNumber(dacFrEng)
                                          : '0',
                                      color: _kAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Ind. Internal',
                                      value: formatNumber(nuclideIndiv),
                                      unit: 'mrem',
                                      color: _kOk,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Coll. Internal',
                                      value: formatNumber(nuclideCollective),
                                      unit: 'mrem',
                                      color: _kOk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0xFFE5E5EA),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            t.nuclides.add(NuclideEntry());
                          }),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Nuclide'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Right rail (380px) — live results
        SizedBox(
          width: 380,
          child: _TaskRightRail(
            task: t,
            totals: totals,
            formatNumber: formatNumber,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

// ─── Right rail: live task results ────────────────────────────────────────────
class _TaskRightRail extends StatelessWidget {
  final TaskData task;
  final Map<String, double> totals;
  final String Function(double) formatNumber;
  final bool isDark;

  const _TaskRightRail({
    required this.task,
    required this.totals,
    required this.formatNumber,
    required this.isDark,
  });

  Color _statusColor(String level) => level == 'danger'
      ? _kDanger
      : level == 'warn'
      ? _kWarn
      : _kOk;
  Color _statusWash(String level) => level == 'danger'
      ? _kDangerWash
      : level == 'warn'
      ? _kWarnWash
      : _kOkWash;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _kDarkSurface : _kSurface;
    final hairline = isDark ? _kDarkHairline : _kHairline;
    final hairline2 = isDark ? const Color(0xFF252420) : _kHairline2;
    final ink1 = isDark ? _kDarkInk1 : _kInk1;
    final ink2 = isDark ? _kDarkInk2 : _kInk2;
    final ink3 = isDark ? _kDarkInk3 : _kInk3;

    final indivInt = task.workers > 0
        ? (totals['collectiveInternal']! / task.workers)
        : 0.0;
    final indivExt = task.workers > 0
        ? (totals['collectiveExternal']! / task.workers)
        : 0.0;
    final indivTotal = indivInt + indivExt;
    final indivPct = (indivTotal / 500).clamp(0.0, 1.0);
    final indivLevel = indivTotal > 500
        ? 'danger'
        : indivTotal > 250
        ? 'warn'
        : 'ok';

    final collEff = totals['collectiveEffective']!;
    final collPct = (collEff / 750).clamp(0.0, 1.0);
    final collLevel = collEff > 750
        ? 'danger'
        : collEff > 400
        ? 'warn'
        : 'ok';

    final protectedDacFrac = totals['totalDacFractionWithResp']!;
    final dacHrs = protectedDacFrac * task.hours;
    final dacPct = (dacHrs / 40).clamp(0.0, 1.0);
    final dacLevel = dacHrs > 200
        ? 'danger'
        : dacHrs > 40
        ? 'warn'
        : 'ok';

    Widget metric(
      String label,
      String value, {
      String? unit,
      bool big = false,
      String? level,
    }) {
      final valColor = level != null ? _statusColor(level) : ink1;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 12, color: ink2)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: big ? 18 : 13,
                fontWeight: FontWeight.w600,
                color: valColor,
                fontFamily: 'Courier',
                letterSpacing: -0.5,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10.5,
                  color: ink3,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget bigMetricCard(
      String label,
      String value, {
      String? unit,
      required String level,
      String? sub,
    }) {
      final bg = _statusWash(level);
      final col = _statusColor(level);
      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? col.withValues(alpha: 0.12) : bg,
          border: Border.all(color: col.withValues(alpha: isDark ? 0.3 : 0.25)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: col.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: col,
                    fontFamily: 'Courier',
                    letterSpacing: -0.02,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: col.withValues(alpha: 0.6),
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ],
            ),
            if (sub != null) ...[
              const SizedBox(height: 3),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: col.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget progressBar(double pct, String level) {
      return Container(
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A27) : hairline,
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: pct,
          child: Container(
            decoration: BoxDecoration(
              color: _statusColor(level),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    Widget group(String title, List<Widget> children) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: hairline2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                color: ink3,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(left: BorderSide(color: hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: hairline)),
            ),
            child: Row(
              children: [
                Text(
                  'LIVE RESULTS',
                  style: TextStyle(
                    fontSize: 11,
                    color: ink3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _kOk,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TASK',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: ink3,
                        fontFamily: 'Courier',
                        letterSpacing: 0.06,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Individual + collective cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Column(
                      children: [
                        bigMetricCard(
                          'Individual effective dose',
                          formatNumber(indivTotal),
                          unit: 'mrem',
                          level: indivLevel,
                          sub:
                              'External ${formatNumber(indivExt)} · Internal ${formatNumber(indivInt)} · of 500 limit',
                        ),
                        SizedBox(height: 4),
                        progressBar(indivPct, indivLevel),
                        const SizedBox(height: 12),
                        bigMetricCard(
                          'Collective dose',
                          formatNumber(collEff),
                          unit: 'p-mrem',
                          level: collLevel,
                          sub: 'of 750 ALARA threshold',
                        ),
                        SizedBox(height: 4),
                        progressBar(collPct, collLevel),
                      ],
                    ),
                  ),

                  // Intake & airborne
                  group('Intake & Airborne', [
                    metric(
                      'mPIF',
                      totals['mPIF']! == 0
                          ? '—'
                          : totals['mPIF']!.toStringAsExponential(2),
                      big: true,
                    ),
                    metric(
                      'Σ DAC fraction (eng only)',
                      formatNumber(totals['totalDacFractionEngOnly'] ?? 0.0),
                    ),
                    metric(
                      'Internal dose (after resp)',
                      formatNumber(indivInt),
                      unit: 'mrem',
                      level: indivLevel,
                    ),
                    metric(
                      'Protected DAC-hours',
                      formatNumber(dacHrs),
                      unit: 'DAC-hr',
                      level: dacLevel,
                    ),
                    const SizedBox(height: 4),
                    progressBar(dacPct, dacLevel),
                    const SizedBox(height: 4),
                    Text(
                      'Sampling threshold: 40 DAC-hr/yr on protected intake basis',
                      style: TextStyle(fontSize: 11, color: ink3),
                    ),
                  ]),

                  // Extremity
                  group('Extremity', [
                    metric(
                      'Individual',
                      formatNumber(totals['individualExtremity'] ?? 0.0),
                      unit: 'mrem',
                    ),
                    metric(
                      'Collective',
                      formatNumber(totals['collectiveExtremity'] ?? 0.0),
                      unit: 'p-mrem',
                    ),
                  ]),

                  // Breakdown
                  group('Task Breakdown', [
                    metric(
                      'Person-hours',
                      formatNumber(totals['personHours'] ?? 0.0),
                      unit: 'hr',
                    ),
                    metric(
                      'External (collective)',
                      formatNumber(totals['collectiveExternal'] ?? 0.0),
                    ),
                    metric(
                      'Internal (collective)',
                      formatNumber(totals['collectiveInternal'] ?? 0.0),
                    ),
                    if ((totals['respiratorPenalty'] ?? 1.0) > 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Includes 15% respirator penalty (×1.15)',
                          style: TextStyle(
                            fontSize: 11,
                            color: ink3,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
