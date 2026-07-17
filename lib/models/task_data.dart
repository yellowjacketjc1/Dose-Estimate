import 'package:flutter/material.dart';

/// Data model for a single task in the dose estimate.
///
/// Also owns the persistent [TextEditingController]s for its editable fields
/// so cursor/selection behavior stays stable across rebuilds. Callers must
/// invoke [disposeControllers] when discarding an instance.
class TaskData {
  String title;
  String location;
  int workers;
  double hours;
  double?
  mpifR; // null = not yet selected; 0.0 = encapsulated (R=0 is a valid selection)
  double mpifC; // -1.0 = custom value; use mpifCCustom for actual value
  double? mpifCCustom; // only used when mpifC == -1.0
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

  // Notes for each section (keyed by stateKey)
  Map<String, String> sectionNotes;

  // Persistent controllers so cursor/selection behavior remains stable
  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController workersController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  final TextEditingController mpifDController = TextEditingController();
  final TextEditingController mpifSController = TextEditingController();
  final TextEditingController mpifUController = TextEditingController();
  final TextEditingController mpifCCustomController = TextEditingController();
  final TextEditingController doseRateController = TextEditingController();

  TaskData({
    this.title = '',
    this.location = '',
    this.workers = 1,
    this.hours = 1.0,
    // null = not yet selected; 0.0 = encapsulated (R=0 explicitly chosen). UI requires selection before computing mPIF.
    this.mpifR,
    this.mpifC = 0.0,
    this.mpifCCustom,
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
    Map<String, String>? sectionNotes,
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
           },
       sectionNotes = sectionNotes ?? {} {
    titleController.text = title;
    locationController.text = location;
    workersController.text = workers.toString();
    hoursController.text = hours.toString();
    // Leave mPIF field controllers empty when value is 0.0 (not selected)
    mpifDController.text = mpifD > 0.0 ? mpifD.toString() : '';
    mpifSController.text = mpifS > 0.0 ? mpifS.toString() : '';
    mpifUController.text = mpifU > 0.0 ? mpifU.toString() : '';
    // Show the custom C value when C is the custom sentinel (-1.0), so a
    // loaded file's hidden custom value is visible and editable.
    mpifCCustomController.text = (mpifC == -1.0 && mpifCCustom != null)
        ? mpifCCustom.toString()
        : '';
    doseRateController.text = doseRate.toString();

    // keep model fields in sync with controllers
    titleController.addListener(() {
      title = titleController.text;
    });
    locationController.addListener(() {
      location = locationController.text;
    });
    workersController.addListener(() {
      // Keep the last valid value on unparseable input (e.g. "1,000") rather
      // than silently computing with 1 worker.
      workers = int.tryParse(workersController.text) ?? workers;
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
    mpifCCustomController.addListener(() {
      if (mpifC == -1.0) {
        mpifCCustom = double.tryParse(mpifCCustomController.text);
      }
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
    mpifCCustomController.dispose();
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
    'mpifCCustom': mpifCCustom,
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
    'sectionNotes': sectionNotes,
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
      mpifCCustom: j['mpifCCustom'] != null
          ? (j['mpifCCustom'] as num).toDouble()
          : null,
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
      sectionNotes: j['sectionNotes'] != null
          ? Map<String, String>.from(j['sectionNotes'])
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
