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

void main() {
  runApp(const DoseEstimateApp());
}

class DoseEstimateApp extends StatelessWidget {
  const DoseEstimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPP-742 Dose Estimate',
      theme: ThemeData(
        // Soft friendly light palette: soft blue primary, gentle teal secondary, warm background
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2), brightness: Brightness.light, secondary: const Color(0xFF2DB7A3), background: const Color(0xFFF7F8FA)),
        brightness: Brightness.light,
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), foregroundColor: Colors.white)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF2DB7A3)),
        chipTheme: ChipThemeData(backgroundColor: const Color(0xFFEEF6FF), labelStyle: const TextStyle(color: Color(0xFF234A6B))),
        // Use an outlined style for TextFields to give more definition
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade400)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: const Color(0xFF4A90E2), width: 2.0)),
          labelStyle: const TextStyle(color: Colors.black87),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        ),
      ),
      home: const DoseHomePage(),
    );
  }
}

class DoseHomePage extends StatefulWidget {
  const DoseHomePage({super.key});

  @override
  State<DoseHomePage> createState() => _DoseHomePageState();
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
    return TaskData(
      title: j['title'] ?? '',
      location: j['location'] ?? '',
      workers: j['workers'] ?? 1,
      hours: (j['hours'] ?? 1).toDouble(),
      mpifR: (j['mpifR'] ?? 1).toDouble(),
      mpifC: (j['mpifC'] ?? 100).toDouble(),
      mpifD: (j['mpifD'] ?? 1).toDouble(),
      mpifS: (j['mpifS'] ?? 1).toDouble(),
      mpifU: (j['mpifU'] ?? 1).toDouble(),
      doseRate: (j['doseRate'] ?? 0).toDouble(),
      pfr: (j['pfr'] ?? 1).toDouble(),
      pfe: (j['pfe'] ?? 1).toDouble(),
      nuclides: (j['nuclides'] as List? ?? []).map((e) => NuclideEntry.fromJson(e)).toList(),
      extremities: (j['extremities'] as List? ?? []).map((e) => ExtremityEntry.fromJson(e)).toList(),
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
  final TextEditingController doseRateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  ExtremityEntry({this.nuclide, this.doseRate = 0.0, this.time = 0.0}) {
    // Initialize controllers with the current values
    doseRateController.text = doseRate.toString();
    timeController.text = time.toString();

    // Keep model fields in sync with controllers
    doseRateController.addListener(() {
      doseRate = double.tryParse(doseRateController.text) ?? 0.0;
    });
    timeController.addListener(() {
      time = double.tryParse(timeController.text) ?? 0.0;
    });
  }

  Map<String, dynamic> toJson() => {'nuclide': nuclide, 'doseRate': doseRate, 'time': time};
  static ExtremityEntry fromJson(Map<String, dynamic> j) => ExtremityEntry(nuclide: j['nuclide'], doseRate: (j['doseRate'] ?? 0).toDouble(), time: (j['time'] ?? 0).toDouble());

  void disposeControllers() {
    doseRateController.dispose();
    timeController.dispose();
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
class _DoseHomePageState extends State<DoseHomePage> with TickerProviderStateMixin {
  final Map<String, double> dacValues = const {
    // A
    "Ac-227": 2e-13, // (BS/BS/St)
    "Ag-108m": 2e-8, // (S)
    "Ag-110m": 7e-8, // (S)
    "Al-26": 4e-8, // (F/M)
    "Am-241": 5e-12,
    "Am-243": 5e-12,
    "As-73": 8e-7,
    "As-74": 3e-7,
    "As-76": 6e-7,
    "As-77": 1e-6,
    "At-211": 5e-9, // (M)
    "Au-195": 4e-7, // (S)
    "Au-198": 5e-7, // (F/S)
    "Au-199": 7e-7, // (S)

    // B
    "Ba-131": 1e-6,
    "Ba-133": 3e-7,
    "Ba-140": 3e-7,
    "Be-7": 1e-5, // (M/S)
    "Be-10": 2e-8, // (S)
    "Bi-206": 2e-7, // (F/M)
    "Bi-207": 1e-7, // (M)
    "Bi-210": 9e-9, // (M)
    "Bi-212": 8e-9, // (M)
    "Bk-249": 1e-9,
    "Br-82": 3e-7, // (F/M)

    // C
    "C-11": 1e-4, // (Vapor)
    "C-14": 9e-7, // (Vapor)
    "Ca-41": 2e-6,
    "Ca-45": 2e-7,
    "Ca-47": 2e-7,
    "Cd-109": 2e-8, // (M)
    "Cd-113m": 1e-9, // (F)
    "Cd-115": 4e-7, // (F/S)
    "Cd-115m": 3e-8, // (F)
    "Ce-139": 4e-7,
    "Ce-141": 1e-7, // (M/S)
    "Ce-143": 5e-7, // (M/S)
    "Ce-144": 1e-8, // (S)
    "Cf-249": 3e-12,
    "Cf-250": 7e-12,
    "Cf-251": 3e-12,
    "Cf-252": 1e-11,
    "Cl-36": 1e-7, // (M)
    "Cl-38": 5e-6, // (M)
    "Cm-242": 1e-10,
    "Cm-243": 7e-12,
    "Cm-244": 9e-12,
    "Cm-245": 5e-12,
    "Cm-246": 5e-12,
    "Cm-247": 5e-12,
    "Cm-248": 1e-12,
    "Co-56": 1e-7, // (M/S)
    "Co-57": 9e-7, // (M)
    "Co-58": 3e-7, // (S)
    "Co-58m": 3e-5, // (M/S)
    "Co-60": 3e-8, // (S)
    "Co-60m": 4e-4, // (M/S)
    "Cr-51": 1e-5, // (F/M/S)
    "Cs-129": 2e-6,
    "Cs-131": 7e-6,
    "Cs-134": 5e-8,
    "Cs-134m": 8e-6,
    "Cs-135": 5e-7,
    "Cs-136": 2e-7,
    "Cs-137": 8e-8,
    "Cu-64": 3e-6, // (M/S)
    "Cu-67": 9e-7, // (S)

    // D
    "Dy-159": 2e-6,
    "Dy-165": 6e-6,
    "Dy-166": 3e-7,

    // E
    "Er-169": 6e-7,
    "Er-171": 1e-6,
    "Eu-152": 2e-8,
    "Eu-152m": 1e-6,
    "Eu-154": 8e-9,
    "Eu-155": 7e-8,

    // F
    "F-18": 3e-6, // (M/S)
    "Fe-52": 5e-7, // (F)
    "Fe-55": 6e-7, // (F)
    "Fe-59": 1e-7, // (F/M)

    // G
    "Ga-67": 2e-6, // (M)
    "Ga-68": 4e-6, // (M)
    "Ga-72": 5e-7, // (F/M)
    "Gd-146": 1e-7, // (F/M)
    "Gd-148": 5e-12, // (F)
    "Gd-149": 7e-7, // (M)
    "Gd-151": 2e-7, // (F)
    "Gd-153": 9e-8, // (F)
    "Gd-159": 1e-6, // (M)
    "Ge-68": 7e-8, // (M)
    "Ge-71": 5e-5, // (F/M)

    // H
    "H-3": 2e-5, // (Water)
    "Hf-172": 6e-9, // (F)
    "Hf-175": 5e-7, // (M)
    "Hf-181": 1e-7, // (F/M)
    "Hg-197": 1e-7, // (Vapor)
    "Hg-197m": 9e-8, // (Vapor)
    "Hg-203": 8e-8, // (Vapor)
    "Ho-166": 6e-7,

    // I
    "I-123": 1e-6, // (Methyl/Vapor)
    "I-124": 2e-8, // (Vapor)
    "I-125": 2e-8, // (Methyl/Vapor)
    "I-126": 1e-8, // (Methyl/Vapor)
    "I-129": 2e-9, // (Vapor)
    "I-131": 1e-8, // (Methyl/Vapor)
    "I-132": 1e-6, // (Methyl/Vapor)
    "I-133": 7e-8, // (Vapor)
    "I-134": 3e-6, // (Vapor/Particulate)
    "I-135": 3e-7, // (Vapor)
    "In-111": 1e-6, // (F/M)
    "In-113m": 1e-5, // (F/M)
    "In-114m": 5e-8, // (M)
    "In-115m": 5e-6, // (F)
    "Ir-190": 2e-7, // (M/S)
    "Ir-192": 1e-7, // (M/S)
    "Ir-194": 7e-7, // (F/S)

    // K
    "K-40": 1e-7,
    "K-42": 2e-6,
    "K-43": 9e-7,

    // L
    "La-137": 4e-8, // (F)
    "La-140": 3e-7, // (M)
    "Lu-172": 3e-7, // (F/M)
    "Lu-173": 2e-7, // (F)
    "Lu-174": 9e-8, // (F)
    "Lu-174m": 2e-7, // (F/M)
    "Lu-177": 5e-7, // (F/M)

    // M
    "Mn-52": 2e-7, // (F/M)
    "Mn-53": 5e-6, // (M)
    "Mn-54": 4e-7, // (F)
    "Mn-56": 2e-6, // (F/M)
    "Mo-93": 2e-7, // (F)
    "Mo-99": 5e-7, // (M)

    // N
    "Na-22": 2e-7,
    "Na-24": 4e-7,
    "Nb-93m": 6e-7, // (M)
    "Nb-94": 2e-8, // (M)
    "Nb-95": 4e-7, // (W/Y)
    "Nb-97": 5e-6, // (W/Y)
    "Nd-144": 2e-13, // Not listed in source; alpha emitter default
    "Nd-147": 2e-7, // (W/Y)
    "Nd-149": 4e-6, // (W/Y)
    "Ni-56": 4e-7, // (Inorg F/Carbonyl)
    "Ni-57": 5e-7, // (Inorg F)
    "Ni-59": 6e-7, // (Carbonyl)
    "Ni-63": 2e-7, // (Carbonyl)
    "Ni-65": 8e-7, // (Carbonyl)
    "Np-235": 1e-6,
    "Np-236": 4e-11, // (Long-lived)
    "Np-237": 8e-12,
    "Np-239": 5e-7,

    // O
    "Os-185": 5e-7, // (F/S)
    "Os-191": 3e-7, // (S)
    "Os-191m": 4e-6, // (F)
    "Os-193": 8e-7, // (M/S)

    // P
    "P-32": 1e-7, // (M)
    "P-33": 4e-7, // (M)
    "Pa-230": 9e-10, // (M)
    "Pa-231": 1e-12, // (W)
    "Pa-233": 1e-7, // (M)
    "Pb-203": 2e-6,
    "Pb-210": 1e-10,
    "Pb-212": 5e-9,
    "Pd-103": 1e-6, // (M/S)
    "Pd-107": 1e-6, // (S)
    "Pd-109": 1e-6, // (M/S)
    "Pm-143": 5e-7, // (W)
    "Pm-144": 1e-7, // (W/Y)
    "Pm-145": 1e-7, // (W)
    "Pm-147": 1e-7, // (W/Y)
    "Pm-148": 2e-7, // (W/Y)
    "Pm-148m": 1e-7, // (W/Y)
    "Pm-149": 6e-7, // (Y)
    "Pm-151": 8e-7, // (Y)
    "Po-208": 2e-13, // Not listed; alpha default
    "Po-209": 2e-13, // Not listed; alpha default
    "Po-210": 2e-10, // (M)
    "Pr-142": 7e-7, // (Y)
    "Pr-143": 2e-7, // (W/Y)
    "Pt-191": 1e-6,
    "Pt-193": 2e-5,
    "Pt-193m": 2e-6,
    "Pt-195m": 1e-6,
    "Pt-197": 3e-6,
    "Pt-197m": 7e-6,
    "Pu-236": 1e-11, // (W)
    "Pu-237": 1e-6, // (W/Y)
    "Pu-238": 6e-12, // (W)
    "Pu-239": 5e-12, // (W)
    "Pu-240": 5e-12, // (W)
    "Pu-241": 2e-10, // (W)
    "Pu-242": 5e-12, // (W)
    "Pu-244": 5e-12, // (W)

    // R
    "Ra-223": 9e-11,
    "Ra-224": 2e-10,
    "Ra-225": 1e-10,
    "Ra-226": 2e-10,
    "Ra-228": 1e-10,
    "Rb-81": 2e-6,
    "Rb-83": 5e-7,
    "Rb-84": 3e-7,
    "Rb-86": 4e-7,
    "Rb-87": 7e-7,
    "Rb-88": 1e-5,
    "Re-184": 3e-7, // (F)
    "Re-184m": 1e-7, // (M)
    "Re-186": 4e-7, // (M)
    "Re-187": 1e-4, // (M)
    "Re-188": 7e-7, // (F)
    "Re-189": 9e-7, // (M)
    "Rh-99": 6e-7, // (M/S)
    "Rh-101": 1e-7, // (S)
    "Rh-102": 6e-8, // (F)
    "Rh-102m": 1e-7, // (S)
    "Rh-103m": 2e-4, // (M/S)
    "Rh-105": 1e-6, // (F/M/S)
    "Rn-220": 1e-8, // (Includes daughters)
    "Rn-222": 8e-8, // (Includes daughters)
    "Ru-97": 2e-6, // (F/M/S)
    "Ru-103": 2e-7, // (M/S)
    "Ru-105": 2e-6, // (F/M/S)
    "Ru-106": 1e-8, // (S)

    // S
    "S-35": 5e-7, // (M)
    "Sb-122": 4e-7, // (M)
    "Sb-124": 1e-7, // (M)
    "Sb-125": 1e-7, // (M)
    "Sb-126": 1e-7, // (M)
    "Sc-44": 1e-6,
    "Sc-44m": 2e-7,
    "Sc-46": 1e-7,
    "Sc-47": 7e-7,
    "Sc-48": 2e-7,
    "Se-73": 1e-6, // (F/M)
    "Se-75": 3e-7, // (M)
    "Se-79": 1e-7, // (M)
    "Si-31": 5e-6, // (M/S)
    "Si-32": 1e-8, // (S)
    "Sm-145": 4e-7,
    "Sm-147": 2e-11,
    "Sm-151": 7e-8,
    "Sm-153": 8e-7,
    "Sn-113": 1e-7, // (M)
    "Sn-117m": 2e-7, // (F)
    "Sn-119m": 3e-7, // (F)
    "Sn-121": 2e-6, // (F)
    "Sn-121m": 1e-7, // (F)
    "Sn-123": 1e-7, // (F)
    "Sn-125": 2e-7, // (F)
    "Sn-126": 3e-8, // (M/S)
    "Sr-82": 7e-8, // (M)
    "Sr-85": 8e-7, // (M)
    "Sr-85m": 3e-5, // (M)
    "Sr-87m": 9e-6, // (M)
    "Sr-89": 1e-7, // (M)
    "Sr-90": 7e-9, // (M)
    "Sr-91": 9e-7, // (M)
    "Sr-92": 1e-6, // (M)

    // T
    "Ta-178": 3e-6,
    "Ta-179": 1e-6, // (M)
    "Ta-182": 7e-8, // (M)
    "Tb-157": 2e-7,
    "Tb-158": 1e-8,
    "Tb-160": 1e-7,
    "Tc-94": 1e-6, // (F/M)
    "Tc-94m": 4e-6, // (F)
    "Tc-95": 1e-6, // (F/M)
    "Tc-95m": 6e-7, // (F)
    "Tc-96": 3e-7, // (F/M)
    "Tc-96m": 2e-5, // (F/M)
    "Tc-97": 3e-6, // (F)
    "Tc-97m": 2e-7, // (M)
    "Tc-98": 9e-8, // (F)
    "Tc-99": 1e-7, // (M)
    "Tc-99m": 1e-5, // (F/M)
    "Te-121": 1e-7, // (Vapor/Particulate W)
    "Te-121m": 4e-8, // (Particulate Y)
    "Te-123": 1e-8, // (Vapor)
    "Te-123m": 1e-7, // (Particulate W/Y)
    "Te-125m": 1e-7, // (Vapor/Particulate Y)
    "Te-127": 3e-6, // (M)
    "Te-127m": 6e-8, // (Vapor)
    "Te-129": 7e-6, // (Y)
    "Te-129m": 1e-7, // (Particulate W/Y)
    "Te-131": 6e-6, // (Vapor)
    "Te-131m": 1e-7, // (Vapor/Particulate)
    "Te-132": 7e-8, // (Vapor)
    "Th-227": 7e-11, // (M)
    "Th-228": 2e-11, // (W/Y)
    "Th-229": 2e-12, // (W)
    "Th-230": 3e-12, // (W)
    "Th-231": 1e-6, // (W/Y)
    "Th-232": 3e-12, // (W)
    "Th-234": 9e-8, // (Y)
    "Ti-44": 7e-9, // (M)
    "Tl-200": 8e-7,
    "Tl-201": 4e-6,
    "Tl-202": 1e-6,
    "Tl-204": 9e-7,
    "Tm-167": 5e-7,
    "Tm-170": 1e-7,
    "Tm-171": 2e-7,

    // U
    "U-230": 4e-11, // (S)
    "U-232": 2e-11, // (S)
    "U-233": 7e-11, // (S)
    "U-234": 7e-11, // (S)
    "U-235": 8e-11, // (S)
    "U-236": 7e-11, // (S)
    "U-237": 3e-7, // (M/S)
    "U-238": 8e-11, // (S)
    "U-239": 9e-6, // (M/S)
    "U-240": 6e-7, // (S)

    // V
    "V-48": 2e-7, // (F/M)
    "V-49": 1e-5, // (M)

    // W
    "W-178": 3e-6,
    "W-181": 1e-5,
    "W-185": 2e-6,
    "W-187": 1e-6,
    "W-188": 6e-7,

    // Y
    "Y-86": 4e-7, // (M/S)
    "Y-87": 8e-7, // (S)
    "Y-88": 1e-7, // (M/S)
    "Y-90": 3e-7, // (M/S)
    "Y-91": 9e-8, // (S)
    "Y-91m": 2e-5, // (M/S)
    "Y-92": 2e-6, // (M/S)
    "Y-93": 9e-7, // (M/S)
    "Yb-169": 2e-7, // (M/S)
    "Yb-175": 8e-7, // (M/S)

    // Z
    "Zn-62": 8e-7, // (S)
    "Zn-63": 5e-6, // (S)
    "Zn-65": 2e-7, // (S)
    "Zn-69": 7e-6, // (S)
    "Zn-69m": 1e-6, // (S)
    "Zr-88": 1e-7, // (F)
    "Zr-89": 6e-7, // (F/M/S)
    "Zr-93": 3e-9, // (F)
    "Zr-95": 9e-8, // (F)
    "Zr-97": 4e-7, // (M/S)

    // Default
    "Other": 2e-13 // (Alpha/SF Default)
  };

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
    return dacValues[n.name] ?? 1e-12;
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
        final dacFractionWithBoth = (airConc / dac) / (t.pfe * t.pfr);
        final dacFractionEngOnly = (airConc / dac) / t.pfe;

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
    'alara8',       // Entry into areas with dose rates > 10 rem/hr (calculated)
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
        final dacWithBoth = (airConc / dac) / (t.pfe * t.pfr);
        final dacEngOnly = (airConc / dac) / t.pfe;
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

        setState(() {
          workOrderController.text = state['projectInfo']?['workOrder'] ?? '';
          dateController.text = state['projectInfo']?['date'] ?? '';
          descriptionController.text = state['projectInfo']?['description'] ?? '';
          // dispose existing task controllers first
          for (final tt in tasks) {
            tt.disposeControllers();
          }
          tasks = (state['tasks'] as List? ?? []).map((t) => TaskData.fromJson(t)).toList();
          // load trigger overrides if present
          triggerOverrides = Map<String, bool>.from(state['triggerOverrides'] ?? {});
          overrideJustifications = Map<String, String>.from(state['overrideJustifications'] ?? {});
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
                              color: finalTriggers['cams'] == true
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
    double totalIndividualEffective = 0.0;
    double totalIndividualExtremity = 0.0;
    double totalCollectiveExternal = 0.0;
    double totalCollectiveInternal = 0.0;
    final rows = <TableRow>[];
    final computedTriggers = computeGlobalTriggers();
    final finalTriggers = getFinalTriggerStates();

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.playlist_add_check, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                const Text('', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: () { addTask(); }, icon: const Icon(Icons.add), label: const Text('Add Task'))
              ]),
            ),
          ),
        ),
      );
    }

    double totalWorkers = 0.0;
    Set<int> workerCounts = {};

    for (final t in tasks) {
      final totals = calculateTaskTotals(t);
      final workers = t.workers;
      workerCounts.add(workers);
      totalWorkers += workers;

      final individualExternal = workers > 0 ? (totals['collectiveExternal']! / workers) : 0.0;
      final individualInternal = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
      totalCollectiveExternal += totals['collectiveExternal']!;
      totalCollectiveInternal += totals['collectiveInternal']!;
      final individualTotal = individualExternal + individualInternal;
      totalIndividualEffective += individualTotal;
      totalIndividualExtremity += totals['totalExtremityDose']! / (workers);

      rows.add(TableRow(children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(t.title)),
        Padding(padding: const EdgeInsets.all(8), child: Text(t.location)),
        Padding(padding: const EdgeInsets.all(8), child: Text('${t.workers}')),
  Padding(padding: const EdgeInsets.all(8), child: Text(formatNumber(totals['totalDacFraction']!))),
        Padding(padding: const EdgeInsets.all(8), child: Text(individualExternal.toStringAsFixed(2))),
  Padding(padding: const EdgeInsets.all(8), child: Text(formatNumber(individualInternal))),
        Padding(padding: const EdgeInsets.all(8), child: Text((workers > 0 ? (totals['totalExtremityDose']! / workers) : 0.0).toStringAsFixed(2))),
        Padding(padding: const EdgeInsets.all(8), child: Text(totals['collectiveExternal']!.toStringAsFixed(2))),
  Padding(padding: const EdgeInsets.all(8), child: Text(formatNumber(totals['collectiveInternal']!))),
        Padding(padding: const EdgeInsets.all(8), child: Text(individualTotal.toStringAsFixed(2))),
      ]));
    }

    // Build a list of small cards for each task to show key dose numbers prominently
    final taskCards = tasks.asMap().entries.map((entry) {
      final i = entry.key;
      final t = entry.value;
      final totals = calculateTaskTotals(t);
      final workers = t.workers;
      final indExternal = workers > 0 ? (totals['collectiveExternal']! / workers) : 0.0;
      final indInternal = workers > 0 ? (totals['collectiveInternal']! / workers) : 0.0;
      final indExtremity = totals['individualExtremity']!;
      final indTotal = indExternal + indInternal;

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Task ${i + 1}: ${t.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Individual External', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(indExternal.toStringAsFixed(2), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Individual Internal', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(formatNumber(indInternal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Extremity Dose', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(indExtremity.toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Individual', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(indTotal.toStringAsFixed(2), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blueAccent)),
              ]),
            ])
          ]),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detailed triggers section first
        buildTriggers(),
        const SizedBox(height: 12),

        // ALARA/Air Sampling/CAMs indicator cards second
        Row(children: [
          Expanded(child: Card(
            color: finalTriggers['alaraReview'] == true ? Colors.red.shade50 : Colors.grey.shade100,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Icon(
                    finalTriggers['alaraReview'] == true ? Icons.check_circle : Icons.close,
                    color: finalTriggers['alaraReview'] == true ? Colors.red : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ALARA Review',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: finalTriggers['alaraReview'] == true ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    finalTriggers['alaraReview'] == true ? 'Required' : 'Not Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: finalTriggers['alaraReview'] == true ? Colors.red.shade600 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: Card(
            color: finalTriggers['airSampling'] == true ? Colors.red.shade50 : Colors.grey.shade100,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Icon(
                    finalTriggers['airSampling'] == true ? Icons.check_circle : Icons.close,
                    color: finalTriggers['airSampling'] == true ? Colors.red : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Air Sampling',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: finalTriggers['airSampling'] == true ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    finalTriggers['airSampling'] == true ? 'Required' : 'Not Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: finalTriggers['airSampling'] == true ? Colors.red.shade600 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: Card(
            color: finalTriggers['camsRequired'] == true ? Colors.red.shade50 : Colors.grey.shade100,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Icon(
                    finalTriggers['camsRequired'] == true ? Icons.check_circle : Icons.close,
                    color: finalTriggers['camsRequired'] == true ? Colors.red : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CAMs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: finalTriggers['camsRequired'] == true ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    finalTriggers['camsRequired'] == true ? 'Required' : 'Not Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: finalTriggers['camsRequired'] == true ? Colors.red.shade600 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ]),
        const SizedBox(height: 16),

        // Task summary cards with enhanced styling
        if (taskCards.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Individual Task Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  const SizedBox(width: 4),
                  ...taskCards.map((c) => Padding(padding: const EdgeInsets.only(right: 12.0), child: c)),
                  const SizedBox(width: 4),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Overall dose summary last with enhanced design
        Container(
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Overall Dose Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              // Main Collective Dose Card with breakdown
              Expanded(
                flex: 2,
                child: Card(
                  color: Colors.purple.shade50,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main title
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TOTAL COLLECTIVE DOSE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Total value
                        Text(
                          '${(totalCollectiveExternal + totalCollectiveInternal).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.purple),
                        ),
                        const SizedBox(height: 4),
                        const Text('person-mrem', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        // Breakdown cards
                        Row(children: [
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EXTERNAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade800)),
                                const SizedBox(height: 4),
                                Text('${totalCollectiveExternal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green.shade800)),
                              ],
                            ),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('INTERNAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue.shade800)),
                                const SizedBox(height: 4),
                                Text(formatNumber(totalCollectiveInternal), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blue.shade800)),
                              ],
                            ),
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Extremity Dose Card
              Expanded(
                flex: 1,
                child: Card(
                  color: Colors.orange.shade50,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'EXTREMITY DOSE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Individual and Collective side by side
                        Row(children: [
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.deepOrange.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('INDIVIDUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.deepOrange.shade800)),
                                const SizedBox(height: 4),
                                Text('${tasks.fold<double>(0, (sum, t) => sum + calculateTaskTotals(t)['individualExtremity']!).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.deepOrange.shade800)),
                                const SizedBox(height: 2),
                                Text('mrem/person', style: TextStyle(fontSize: 9, color: Colors.deepOrange.shade700)),
                              ],
                            ),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('COLLECTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade800)),
                                const SizedBox(height: 4),
                                Text('${tasks.fold<double>(0, (sum, t) => sum + calculateTaskTotals(t)['collectiveExtremity']!).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red.shade800)),
                                const SizedBox(height: 2),
                                Text('person-mrem', style: TextStyle(fontSize: 9, color: Colors.red.shade700)),
                              ],
                            ),
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[const Tab(text: 'Summary')];
    tabs.addAll(List.generate(tasks.length, (i) {
      final td = tasks[i];
      // Show the task number before the title. If no title, show just the number.
      final label = (td.title.trim().isEmpty) ? '${i + 1}' : '${i + 1} ${td.title}';
      return Tab(key: ValueKey('task-tab-$i'), text: label);
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('RPP-742 Task-Based Dose Assessment'),
        actions: [
          IconButton(onPressed: saveToFile, icon: const Icon(Icons.save)),
          IconButton(onPressed: loadFromFile, icon: const Icon(Icons.folder_open)),
          IconButton(onPressed: printSummaryReport, icon: const Icon(Icons.print)),
          IconButton(onPressed: () {
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
          }, icon: const Icon(Icons.bug_report)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced Project Info card with modern styling to match result cards
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: workOrderController,
                    decoration: InputDecoration(
                      labelText: 'RWP (Radiological Work Permit) Number',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey.shade300),
                      ),
                    ),
                    style: TextStyle(color: Colors.blueGrey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Work Description',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey.shade300),
                      ),
                    ),
                    maxLines: 3,
                    style: TextStyle(color: Colors.blueGrey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Triggers moved into the Summary tab only

            // Tab area centered inside a rounded Card with lively accents
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha((0.08*255).round())),
                boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 8, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Inner elevated TabBar with rounded, raised indicator
                      Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: PhysicalModel(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          // Pill slider container with background and animated indicator
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Stack(
                              children: [
                                // Animated pill indicator
                                AnimatedBuilder(
                                  animation: tabController,
                                  builder: (context, child) {
                                    final selectedIndex = tabController.index;
                                    const tabWidth = 160.0; // Fixed width for consistent sliding
                                    const tabSpacing = 4.0;

                                    return AnimatedPositioned(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      left: selectedIndex * (tabWidth + tabSpacing),
                                      child: Container(
                                        width: tabWidth,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          // Translucent glassy effect
                                          color: selectedIndex == 0
                                            ? Colors.indigo.shade200.withOpacity(0.4)
                                            : Colors.blue.shade200.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: selectedIndex == 0
                                              ? Colors.indigo.shade300.withOpacity(0.6)
                                              : Colors.blue.shade300.withOpacity(0.6),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (selectedIndex == 0 ? Colors.indigo : Colors.blue).withOpacity(0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Tab buttons on top of the slider
                                Row(
                                  children: List.generate(tabs.length, (index) {
                                    final isSelected = tabController.index == index;
                                    const tabWidth = 160.0;

                                    return Container(
                                      width: tabWidth,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () {
                                            tabController.animateTo(index);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Center(
                                              child: Text(
                                                tabs[index].text ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                    ? (index == 0 ? Colors.indigo.shade800 : Colors.blue.shade800)
                                                    : Colors.grey.shade700,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Enhanced Add Task button with card styling
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                addTask();
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  try {
                                    tabController.animateTo(tasks.length);
                                  } catch (_) {}
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Task',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      // Summary tab — emphasized summary card
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(padding: const EdgeInsets.all(12), child: buildSummary()),
                        ),
                      ),
                      // Task tabs
                      for (var i = 0; i < tasks.length; i++) KeyedSubtree(key: ValueKey('task-view-$i'), child: buildTaskTab(i)),
                    ],
                  ),
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTriggers() {
    final computedTriggers = computeGlobalTriggers();
    final finalTriggers = getFinalTriggerStates();
    final reasons = computeTriggerReasons();
    // Build ALARA card and Air Sampling card similar to original HTML checklist
    return Column(children: [
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Workplace Air Sampling Triggers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: finalTriggers['sampling1'] ?? false,
              onChanged: (v) { handleTriggerOverride('sampling1', v); },
              title: const Text('Worker likely to exceed 40 DAC-hours per year (air sampling required)'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (reasons.containsKey('sampling1')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['sampling1']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('sampling1')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['sampling1']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(
              value: finalTriggers['sampling2'] ?? false,
              onChanged: (v) { handleTriggerOverride('sampling2', v); },
              title: const Text('Respiratory protection prescribed (air sampling required)'), controlAffinity: ListTileControlAffinity.leading,
            ),
            if (reasons.containsKey('sampling2')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['sampling2']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('sampling2')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['sampling2']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(
              value: finalTriggers['sampling3'] ?? false,
              onChanged: (v) { handleTriggerOverride('sampling3', v); },
              title: const Text('Air sample needed to estimate internal dose'), controlAffinity: ListTileControlAffinity.leading,
            ),
            if (reasons.containsKey('sampling3')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['sampling3']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('sampling3')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['sampling3']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(
              value: finalTriggers['sampling4'] ?? false,
              onChanged: (v) { handleTriggerOverride('sampling4', v); },
              title: const Text('Estimated intake > 10% ALI or 500 mrem'), controlAffinity: ListTileControlAffinity.leading,
            ),
            if (reasons.containsKey('sampling4')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['sampling4']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('sampling4')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['sampling4']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(
              value: finalTriggers['sampling5'] ?? false,
              onChanged: (v) { handleTriggerOverride('sampling5', v); },
              title: const Text('Airborne concentration > 0.3 DAC averaged over 40 hr or >1 DAC spike'), controlAffinity: ListTileControlAffinity.leading,
            ),
            if (reasons.containsKey('sampling5')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['sampling5']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('sampling5')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['sampling5']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(
              value: finalTriggers['camsRequired'] ?? false,
              onChanged: (v) { handleTriggerOverride('camsRequired', v); },
              title: const Text('CAMs required (worker > 40 DAC-hrs in week)'), controlAffinity: ListTileControlAffinity.leading,
            ),
            if (reasons.containsKey('camsRequired')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['camsRequired']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('camsRequired')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['camsRequired']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ALARA Trigger Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(value: finalTriggers['alara1'] ?? false, onChanged: (v) { handleTriggerOverride('alara1', v); }, title: const Text('Non-routine or complex work'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara1')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara1']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara1')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara1']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara2'] ?? false, onChanged: (v) { handleTriggerOverride('alara2', v); }, title: const Text('Estimated individual total effective dose > 500 mrem'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara2')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara2']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara2')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara2']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara3'] ?? false, onChanged: (v) { handleTriggerOverride('alara3', v); }, title: const Text('Estimated individual extremity/skin dose > 5000 mrem'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara3')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara3']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara3')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara3']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara4'] ?? false, onChanged: (v) { handleTriggerOverride('alara4', v); }, title: const Text('Collective dose > 750 person-mrem'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara4')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara4']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara4')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara4']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara5'] ?? false, onChanged: (v) { handleTriggerOverride('alara5', v); }, title: const Text('Airborne >200 DAC averaged over 1 hr or spike >1000 DAC'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara5')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara5']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara5')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara5']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara6'] ?? false, onChanged: (v) { handleTriggerOverride('alara6', v); }, title: const Text('Removable contamination > 1000x Appendix D levels'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara6')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara6']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara6')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara6']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara7'] ?? false, onChanged: (v) { handleTriggerOverride('alara7', v); }, title: const Text('Worker likely to receive internal dose >100 mrem'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara7')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara7']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara7')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara7']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
            CheckboxListTile(value: finalTriggers['alara8'] ?? false, onChanged: (v) { handleTriggerOverride('alara8', v); }, title: const Text('Entry into areas with dose rates > 10 rem/hr at 30 cm'), controlAffinity: ListTileControlAffinity.leading),
            if (reasons.containsKey('alara8')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text(reasons['alara8']!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            if (overrideJustifications.containsKey('alara8')) Padding(padding: const EdgeInsets.only(left: 56.0, bottom: 8.0), child: Text('Override: ${overrideJustifications['alara8']!}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic))),
          ]),
        ),
      ),
    ]);
  }

  Widget buildTaskTab(int index) {
    final t = tasks[index];
    final totals = calculateTaskTotals(t);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    controller: t.titleController,
                    focusNode: t.titleFocusNode,
                    autofocus: t.titleController.text.isEmpty,
                    onChanged: (v) { setState(() {}); }
                  )),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(onPressed: () => removeTask(index), icon: const Icon(Icons.delete), label: const Text('Remove Task'))
                ]),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Location',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  controller: t.locationController,
                  onChanged: (v) { setState(() {}); }
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Time Estimation
          Card(
            child: ExpansionTile(
              title: const Text('Time Estimation'),
              initiallyExpanded: t.sectionExpansionStates['timeEstimation'] ?? true,
              onExpansionChanged: (expanded) {
                setState(() {
                  t.sectionExpansionStates['timeEstimation'] = expanded;
                });
              },
              children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: TextField(
                      decoration: InputDecoration(
                        labelText: '# Workers',
                        hintText: 'Enter number of workers',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      controller: t.workersController,
                      onChanged: (v) { setState(() {}); }
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Hours Each',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: t.hoursController,
                      onChanged: (v) { setState(() {}); }
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Card(
                      color: Colors.blue.shade50,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Person-Hours', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text('${calculateTaskTotals(t)['personHours']!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ))
                  ])
                ]),
              )
            ]),
          ),

          const SizedBox(height: 12),

          Card(
            child: ExpansionTile(
              title: const Text('mPIF Calculation'),
              initiallyExpanded: t.sectionExpansionStates['mpifCalculation'] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  t.sectionExpansionStates['mpifCalculation'] = expanded;
                });
              },
              children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<double>(
                      value: t.mpifR > 0.0 ? t.mpifR : null,
                      decoration: InputDecoration(
                        labelText: 'Release Factor (R)',
                        hintText: 'Select R',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: releaseFactors.entries.map((e) => DropdownMenuItem(value: e.value, child: Text('${e.key}'))).toList(),
                      onChanged: (v) { t.mpifR = v ?? 0.0; setState(() {}); }
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<double>(
                      value: t.mpifC > 0.0 ? t.mpifC : null,
                      decoration: InputDecoration(
                        labelText: 'Confinement Factor (C)',
                        hintText: 'Select C',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: confinementFactors.entries.map((e) => DropdownMenuItem(value: e.value, child: Text('${e.key}'))).toList(),
                      onChanged: (v) { t.mpifC = v ?? 0.0; setState(() {}); }
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    // Dispersibility dropdown 1..10
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: (t.mpifD > 0.0) ? t.mpifD.toInt() : null,
                        decoration: InputDecoration(
                          labelText: 'Dispersibility (D)',
                          hintText: 'Select D',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            t.mpifD = v.toDouble();
                            t.mpifDController.text = v.toString();
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Uncertainty dropdown 1..10
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: (t.mpifU > 0.0) ? t.mpifU.toInt() : null,
                        decoration: InputDecoration(
                          labelText: 'Uncertainty (U)',
                          hintText: 'Select U',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
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
                    // Special Form dropdown (placed last in row)
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: (t.mpifS > 0.0) ? t.mpifS : null,
                        decoration: InputDecoration(
                          labelText: 'Special Form (S)',
                          hintText: 'Select S',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        items: [0.1, 1.0].map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
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
                    Expanded(child: Card(
                      color: Colors.purple.shade50,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('mPIF Result', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Tooltip(
                              message: 'mPIF = 1e-6 * R * C * D * S * U',
                              child: Text(
                                calculateTaskTotals(t)['mPIF']! > 0.0 ? '${calculateTaskTotals(t)['mPIF']!.toStringAsExponential(2)}' : '(not set)',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                  ]),
                  const SizedBox(height: 12),
                  // Reference note for mPIF factors
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Refer to Attachment A of HPP 9.1 for details on mPIF factors',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              )
            ]),
          ),

          const SizedBox(height: 12),

          Card(
            child: ExpansionTile(
              title: const Text('External Dose Estimate'),
              initiallyExpanded: t.sectionExpansionStates['externalDose'] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  t.sectionExpansionStates['externalDose'] = expanded;
                });
              },
              children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  Column(children: [
                    Row(children: [
                      Expanded(child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Dose Rate (mrem/hr)',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        controller: t.doseRateController,
                        onChanged: (v) { setState(() {}); }
                      )),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Card(
                        color: Colors.green.shade50,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Person-Hours', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text('${totals['personHours']!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Card(
                        color: Colors.orange.shade50,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Collective External', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text('${totals['collectiveExternal']!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 2),
                              const Text('(mrem)', style: TextStyle(fontSize: 10, color: Colors.black45)),
                            ],
                          ),
                        ),
                      )),
                    ]),
                  ])
                ]),
              )
            ]),
          ),

          const SizedBox(height: 12),

          Card(
            child: ExpansionTile(
              title: const Text('Extremity/Skin Dose Estimate'),
              initiallyExpanded: t.sectionExpansionStates['extremityDose'] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  t.sectionExpansionStates['extremityDose'] = expanded;
                });
              },
              children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  Column(children: List.generate(t.extremities.length, (ei) {
                    final e = t.extremities[ei];
                    return Row(children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              // Add "Other" and "Various" options along with dacValues
                              final allOptions = ['Other', 'Various', ...dacValues.keys];
                              if (textEditingValue.text == '') return allOptions;
                              return allOptions.where((k) => k.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Material(
                                elevation: 4,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            onSelected: (selection) { e.nuclide = selection; setState(() {}); },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              controller.text = e.nuclide ?? '';
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Select a radionuclide',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                )
                              );
                            },
                          ),
                        ),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Dose Rate (mrem/hr)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      controller: e.doseRateController,
                      onChanged: (v) { setState(() { e.doseRate = double.tryParse(v) ?? 0.0; }); }
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Time (hr)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      controller: e.timeController,
                      onChanged: (v) { setState(() { e.time = double.tryParse(v) ?? 0.0; }); }
                    )),
                    IconButton(onPressed: () { setState(() { e.disposeControllers(); t.extremities.removeAt(ei); }); }, icon: const Icon(Icons.delete, color: Colors.red)),
                  ]);
                  })),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(onPressed: () { setState(() { t.extremities.add(ExtremityEntry()); }); }, icon: const Icon(Icons.add), label: const Text('Add Extremity Dose')),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Card(
                      color: Colors.deepOrange.shade50,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Individual Extremity Dose', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text('${totals['individualExtremity']!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                            const SizedBox(height: 2),
                            const Text('(mrem per person)', style: TextStyle(fontSize: 10, color: Colors.black45)),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Card(
                      color: Colors.red.shade50,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Collective Extremity Dose', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text('${totals['collectiveExtremity']!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 2),
                            const Text('(mrem)', style: TextStyle(fontSize: 10, color: Colors.black45)),
                          ],
                        ),
                      ),
                    )),
                  ])
                ]),
              )
            ]),
          ),

          const SizedBox(height: 12),

          Card(
            child: ExpansionTile(
              title: const Text('Protection Factors'),
              initiallyExpanded: t.sectionExpansionStates['protectionFactors'] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  t.sectionExpansionStates['protectionFactors'] = expanded;
                });
              },
              children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Respiratory (PFR)'),
                    RadioListTile<double>(value: 1.0, groupValue: t.pfr, title: const Text('None (PFR=1)'), onChanged: (v) { t.pfr = v ?? t.pfr; setState(() {}); }),
                    RadioListTile<double>(value: 50.0, groupValue: t.pfr, title: const Text('APR (PFR=50)'), onChanged: (v) { t.pfr = v ?? t.pfr; setState(() {}); }),
                    RadioListTile<double>(value: 1000.0, groupValue: t.pfr, title: const Text('PAPR (PFR=1000)'), onChanged: (v) { t.pfr = v ?? t.pfr; setState(() {}); }),
                    const SizedBox(height: 6),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Engineering (PFE)'),
                    RadioListTile<double>(value: 1.0, groupValue: t.pfe, title: const Text('No Controls (PFE=1)'), onChanged: (v) { t.pfe = v ?? t.pfe; setState(() {}); }),
                    RadioListTile<double>(value: 1000.0, groupValue: t.pfe, title: const Text('Type I (PFE=1,000)'), onChanged: (v) { t.pfe = v ?? t.pfe; setState(() {}); }),
                    RadioListTile<double>(value: 100000.0, groupValue: t.pfe, title: const Text('Type II (PFE=100,000)'), onChanged: (v) { t.pfe = v ?? t.pfe; setState(() {}); }),
                    const SizedBox(height: 6),
                  ])),
                ]),
              )
            ]),
          ),

          const SizedBox(height: 12),

          Card(
            child: ExpansionTile(
              title: const Text('Internal Dose Calculation'),
              initiallyExpanded: t.sectionExpansionStates['internalDose'] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  t.sectionExpansionStates['internalDose'] = expanded;
                });
              },
              children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                    Column(children: List.generate(t.nuclides.length, (ni) {
                    final n = t.nuclides[ni];
                    final res = computeNuclideDose(n, t);
                    final dac = res['dac'] ?? 1e-12;
                    final airConc = res['airConc'] ?? 0.0;
                    final dacFractionEngOnly = res['dacFractionEngOnly'] ?? 0.0;
                    final nuclideCollective = res['collective'] ?? 0.0;
                    final nuclideIndividualPerPerson = res['individual'] ?? 0.0;

                    return Column(children: [
                      Row(children: [
                        Expanded(
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(text: n.name ?? ''),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') return dacValues.keys.toList();
                              return dacValues.keys.where((k) => k.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Material(
                                elevation: 4,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      final dac = dacValues[option] ?? 1e-12;
                                      return ListTile(
                                        title: Text(option),
                                        subtitle: option == 'Other'
                                            ? const Text('Custom DAC required')
                                            : Text('DAC: ${formatNumber(dac)}'),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            onSelected: (selection) {
                              n.name = selection;
                              // Clear custom DAC when changing from "Other" to a specific nuclide
                              if (selection != 'Other') {
                                n.customDAC = null;
                                n.dacController.clear();
                              }
                              setState(() {});
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              controller.text = n.name ?? '';
                              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Nuclide',
                                    hintText: 'Select a radionuclide',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  )
                                )
                              ]);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Always show DAC field - editable for "Other", read-only for others, empty when no nuclide selected
                        Expanded(child: TextField(
                          decoration: InputDecoration(
                            labelText: 'DAC (µCi/mL)',
                            hintText: n.name == 'Other' ? 'Enter custom DAC' : (n.name == null ? 'Select nuclide first' : ''),
                            filled: true,
                            fillColor: n.name == 'Other' ? Colors.orange.shade50 : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: n.name == 'Other' ? Colors.orange.shade300 : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: n.name == 'Other' ? Colors.orange.shade300 : Colors.grey.shade300),
                            ),
                          ),
                          controller: n.name == 'Other' ? n.dacController : TextEditingController(text: n.name != null ? formatNumber(dac) : ''),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            // allow digits, decimal point, exponent notation (e/E) and signs
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-\.]')),
                          ],
                          readOnly: n.name != 'Other',
                          enabled: n.name == 'Other',
                          onChanged: (v) { setState(() {}); },
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(
                          decoration: const InputDecoration(labelText: 'Contam. (dpm/100cm²)', hintText: 'enter contamination level here'),
                          controller: n.contamController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            // allow digits, decimal point, exponent notation (e/E) and signs
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-\.]')),
                          ],
                          onChanged: (v) { setState(() {}); },
                        )),
                        IconButton(onPressed: () { setState(() { n.disposeControllers(); t.nuclides.removeAt(ni); }); }, icon: const Icon(Icons.delete, color: Colors.red)),
                      ]),

                      // Single concise card showing internal dose computed as:
                      // InternalDose_collective = ((airConc / (PFE * PFR)) / DAC) * (workers * hours) / 2000 * 5000
                      // InternalDose_individual = InternalDose_collective / workers
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: Colors.white,
                          child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Per-nuclide Details', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Airborne conc.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(airConc.isFinite ? airConc.toStringAsExponential(3) : '0', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ])),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('DAC Fraction (after PFE)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(dacFractionEngOnly.isFinite ? formatNumber(dacFractionEngOnly) : '0', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ])),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: Text('Internal Dose (per person): ${formatNumber(nuclideIndividualPerPerson)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Internal Dose (collective): ${formatNumber(nuclideCollective)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                            ])
                          ])),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Divider(),
                    ]);
                  })),
                  ElevatedButton.icon(onPressed: () { setState(() { t.nuclides.add(NuclideEntry()); }); }, icon: const Icon(Icons.add), label: const Text('Add Nuclide')),
                ]),
              )
            ]),
          ),

          const SizedBox(height: 12),

          // Prominent per-task totals displayed as three compact cards for visual emphasis
          // Task-level DAC summary card (summed DAC fraction and DAC-hours)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Summed DAC Fraction (post-PFE)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(formatNumber(totals['totalDacFraction'] ?? 0.0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('DAC-hours (post-PFE)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(formatNumber((totals['totalDacFraction'] ?? 0.0) * t.hours), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ])),
                ]),
              ),
            ),
          ),

          Row(children: [
            Expanded(
        child: Card(
          color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Collective Effective', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(totals['collectiveEffective']!.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 4),
                    Text('(mrem)', style: TextStyle(fontSize: 11, color: Colors.black45)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Individual Effective', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(totals['individualEffective']!.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 4),
                    Text('(mrem per person)', style: TextStyle(fontSize: 11, color: Colors.black45)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
        child: Card(
          color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Individual Extremity', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(totals['individualExtremity']!.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    const SizedBox(height: 4),
                    Text('(mrem per person)', style: TextStyle(fontSize: 11, color: Colors.black45)),
                  ]),
                ),
              ),
            ),
          ]),

          // Respirator penalty note
          if (totals['respiratorPenalty']! > 1.0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dose values include 15% respirator penalty (×1.15) for external and internal doses',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
