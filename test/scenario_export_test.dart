// Generates dose + containment PDFs for a set of representative scenarios,
// organised one folder per scenario under build/scenario_pdfs/.
//
//   flutter test test/scenario_export_test.dart
//
// Each scenario exercises a different combination of triggers, source terms
// and confinement so the reports can be reviewed side by side.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/containment.dart';
import 'package:dose_dart_version/main.dart';

Map<String, dynamic> nuc(String name, double contam, {double? customDAC}) => {
  'name': name,
  'contam': contam,
  if (customDAC != null) 'customDAC': customDAC,
};

Map<String, dynamic> task({
  required String title,
  String location = '',
  int workers = 2,
  double hours = 4,
  double mpifR = 0.1,
  double mpifC = 100,
  double mpifD = 1,
  double mpifS = 1,
  double mpifU = 1,
  double doseRate = 5,
  double pfr = 1,
  double pfe = 1,
  List<Map<String, dynamic>> nuclides = const [],
  List<Map<String, dynamic>> extremities = const [],
  Map<String, String> sectionNotes = const {},
}) => {
  'title': title,
  'location': location,
  'workers': workers,
  'hours': hours,
  'mpifR': mpifR,
  'mpifC': mpifC,
  'mpifD': mpifD,
  'mpifO': 1.0,
  'mpifS': mpifS,
  'mpifU': mpifU,
  'doseRate': doseRate,
  'pfr': pfr,
  'pfe': pfe,
  'nuclides': nuclides,
  'extremities': extremities,
  'sectionNotes': sectionNotes,
};

/// One scenario: a dose-estimate state and a containment state.
class Scenario {
  final String folder;
  final Map<String, dynamic> dose;
  final Map<String, dynamic> containment;
  const Scenario(this.folder, this.dose, this.containment);
}

Future<void> writeDose(
  WidgetTester tester,
  Scenario s,
  Directory outDir,
) async {
  final key = GlobalKey<DoseEstimateScreenState>();
  await tester.pumpWidget(
    MaterialApp(
      home: DoseEstimateScreen(key: key, initialState: s.dose),
    ),
  );
  await tester.pumpAndSettle();
  tester.takeException(); // headless-viewport layout noise

  final expected = (s.dose['tasks'] as List).length;
  expect(
    key.currentState!.tasks.length,
    expected,
    reason: '${s.folder}: dose state was rejected on import',
  );

  List<int>? bytes;
  await tester.runAsync(() async {
    bytes = await key.currentState!.buildSummaryReportDocument().save();
  });
  expect(bytes, isNotNull);
  File('${outDir.path}/Dose Assessment.pdf').writeAsBytesSync(bytes!);
}

Future<void> writeContainment(
  WidgetTester tester,
  Scenario s,
  Directory outDir,
) async {
  final key = GlobalKey<ContainmentTabState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(height: 4000, child: ContainmentTab(key: key)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  tester.takeException();

  key.currentState!.importState(s.containment);
  await tester.pumpAndSettle();
  tester.takeException();

  List<int>? bytes;
  await tester.runAsync(() async {
    bytes = await key.currentState!.buildContainmentReportDocument().save();
  });
  expect(bytes, isNotNull);
  File('${outDir.path}/Containment Analysis.pdf').writeAsBytesSync(bytes!);
}

void main() {
  testWidgets('export scenario PDFs', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final scenarios = <Scenario>[
      // ── 1. Routine low-dose job: nothing triggers, adequate containment ────
      Scenario(
        '1 - Routine low-dose job',
        {
          'projectInfo': {
            'workOrder': 'WCD-2026-0142',
            'date': '2026-08-06',
            'description': 'Routine HEPA filter change-out, Cs-137 area',
            'preparer': 'J. Coyle, Health Physicist',
          },
          'tasks': [
            task(
              title: 'Filter removal and bag-out',
              location: '234-5Z Glovebox 3',
              workers: 2,
              hours: 4,
              doseRate: 5,
              mpifR: 0.001,
              mpifC: 0.01,
              nuclides: [nuc('Cs-137', 5000)],
              sectionNotes: {
                'externalDose':
                    'Dose rate from routine survey RS-2026-0731, 30 cm '
                    'from the filter housing.',
              },
            ),
          ],
        },
        {
          'useContaminationInput': false,
          'selectedConfinement': 'Glovebox, hot cell',
          'selectedForm': 'Powders',
          'selectedPifRelease': 'Solids, spotty contamination',
          'selectedOccupancy': 'Monthly (few times/yr)',
          'selectedDispersibility': 'No',
          'selectedSpecialForm': 'Normal',
          'controllers': {
            'totalActivity': '50',
            'volume': '2e8',
            'mixing': '0.6',
            'fa': '1',
            'fr': '1',
            'uncertainty': '1',
            'frJustification':
                'Bounding release fraction; no credit taken for the filter '
                'media retaining activity during the change-out.',
          },
          'sourceTerm': [
            {'name': 'Cs-137', 'fraction': 1.0, 'dac': 0.0},
          ],
        },
      ),

      // ── 2. Extremity-driven: ring dosimetry, no ALARA review ──────────────
      Scenario(
        '2 - Extremity ring dosimetry',
        {
          'projectInfo': {
            'workOrder': 'WCD-2026-0301',
            'date': '2026-08-06',
            'description':
                'Hands-on valve repack — high contact dose, low whole-body',
            'preparer': 'J. Coyle, Health Physicist',
          },
          'tasks': [
            task(
              title: 'Valve repack, direct handling',
              location: 'B-Cell valve gallery',
              workers: 1,
              hours: 3,
              doseRate: 2,
              mpifR: 0.001,
              mpifC: 1,
              nuclides: [nuc('Cs-137', 4000)],
              extremities: [
                {
                  'nuclide': 'Cs-137',
                  'doseRate': 200,
                  'time': 3,
                  'contam': 4000,
                },
              ],
              sectionNotes: {
                'extremityDose':
                    'Contact reading taken at the packing gland; ring '
                    'dosimetry issued per the 500 mrem threshold.',
              },
            ),
          ],
        },
        {
          'useContaminationInput': true,
          'areaInCm2': false,
          'selectedConfinement': 'Fume hood, bagged material',
          'selectedForm': 'Liquids',
          'selectedPifRelease': 'Liquids',
          'selectedOccupancy': 'Weekly (10s times/yr)',
          'selectedDispersibility': 'No',
          'selectedSpecialForm': 'Normal',
          'controllers': {
            'contamination': '25000',
            'area': '4',
            'volume': '1e7',
            'mixing': '0.5',
            'fa': '1',
            'fr': '0.01',
            'uncertainty': '1',
            'frJustification':
                'Liquid release fraction per RPP-742 Table 3; work is wetted '
                'throughout to suppress resuspension.',
          },
          'sourceTerm': [
            {'name': 'Cs-137', 'fraction': 1.0, 'dac': 0.0},
          ],
        },
      ),

      // ── 3. Airborne alpha work: air sampling + CAMs, respirator ───────────
      Scenario(
        '3 - Alpha airborne with respirator',
        {
          'projectInfo': {
            'workOrder': 'WCD-2026-0455',
            'date': '2026-08-06',
            'description':
                'Plutonium glovebox line decontamination with supplied-air',
            'preparer': 'J. Coyle, Health Physicist',
          },
          'tasks': [
            task(
              title: 'Glovebox interior decontamination',
              location: '234-5Z Line 7',
              workers: 3,
              hours: 6,
              doseRate: 45,
              pfr: 50,
              pfe: 1000,
              nuclides: [nuc('Pu-239', 150000), nuc('Am-241', 40000)],
              sectionNotes: {
                'internalDose':
                    'Source term from 2026-08-01 smears. PFE credited for the '
                    'glovebox; PFR 50 for the full-face APR.',
                'protectionFactors':
                    'Supplied-air respirator prescribed; 15% work-rate penalty '
                    'applied to external dose.',
              },
            ),
          ],
        },
        {
          'useContaminationInput': false,
          'selectedConfinement': 'Glovebox, hot cell',
          'selectedForm': 'Powders',
          'selectedPifRelease':
              'Nonvolatile powders, somewhat volatile liquids',
          'selectedOccupancy': 'Daily (essentially daily)',
          'selectedDispersibility': 'Yes',
          'selectedSpecialForm': 'Normal',
          'controllers': {
            'totalActivity': '12',
            'volume': '5e7',
            'mixing': '0.4',
            'fa': '1',
            'fr': '0.1',
            'uncertainty': '3',
            'frJustification':
                'Powder release fraction with an uncertainty factor of 3 for '
                'an incompletely characterised holdup deposit.',
          },
          'sourceTerm': [
            {'name': 'Pu-239', 'fraction': 0.75, 'dac': 0.0},
            {'name': 'Am-241', 'fraction': 0.25, 'dac': 0.0},
          ],
        },
      ),

      // ── 4. Multi-task campaign: several tasks, aggregate ALARA review ─────
      Scenario(
        '4 - Multi-task outage campaign',
        {
          'projectInfo': {
            'workOrder': 'WCD-2026-0500',
            'date': '2026-08-06',
            'description':
                'Outage campaign — scaffold, insulation removal, weld repair, '
                'survey and restoration in a mixed fission-product field',
            'preparer': 'J. Coyle, Health Physicist',
          },
          'tasks': [
            task(
              title: 'Scaffold erection',
              location: 'Cell 4 north face',
              workers: 4,
              hours: 8,
              doseRate: 18,
              mpifR: 0.001,
              mpifC: 100,
              nuclides: [nuc('Co-60', 8000)],
            ),
            task(
              title: 'Insulation removal',
              location: 'Cell 4 piping',
              workers: 3,
              hours: 10,
              doseRate: 35,
              mpifR: 0.01,
              mpifC: 100,
              mpifD: 10,
              nuclides: [nuc('Co-60', 22000), nuc('Cs-137', 15000)],
              sectionNotes: {
                'mpifCalculation':
                    'Dispersibility factor of 10 applied — insulation removal '
                    'is a known resuspension pathway.',
              },
            ),
            task(
              title: 'Weld repair',
              location: 'Cell 4 line 12',
              workers: 2,
              hours: 12,
              doseRate: 60,
              mpifR: 0.001,
              mpifC: 10,
              nuclides: [nuc('Co-60', 12000)],
              extremities: [
                {
                  'nuclide': 'Co-60',
                  'doseRate': 90,
                  'time': 6,
                  'contam': 12000,
                },
              ],
            ),
            task(
              title: 'Final survey and restoration',
              location: 'Cell 4',
              workers: 2,
              hours: 5,
              doseRate: 12,
              mpifR: 0.001,
              mpifC: 1,
              nuclides: [nuc('Cs-137', 6000)],
            ),
          ],
        },
        {
          'useContaminationInput': false,
          'selectedConfinement': 'Bagged/wrapped material, greenhouses',
          'selectedForm': 'Powders',
          'selectedPifRelease': 'General (large area) contamination',
          'selectedOccupancy': 'Weekly (10s times/yr)',
          'selectedDispersibility': 'Yes',
          'selectedSpecialForm': 'Normal',
          'controllers': {
            'totalActivity': '85',
            'volume': '8e7',
            'mixing': '0.5',
            'fa': '1',
            'fr': '0.01',
            'uncertainty': '2',
            'frJustification':
                'Mixed activated-corrosion-product deposit; uncertainty factor '
                'of 2 pending characterisation of the insulation loading.',
          },
          'sourceTerm': [
            {'name': 'Co-60', 'fraction': 0.6, 'dac': 0.0},
            {'name': 'Cs-137', 'fraction': 0.25, 'dac': 0.0},
            {'name': 'Sr-90', 'fraction': 0.1, 'dac': 0.0},
            {'name': 'Eu-154', 'fraction': 0.05, 'dac': 0.0},
          ],
        },
      ),

      // ── 5. High-hazard recovery: every trigger, overrides, inadequate ─────
      Scenario(
        '5 - High-hazard breach recovery',
        {
          'projectInfo': {
            'workOrder': 'WCD-2026-0199-REV-C',
            'date': '2026-08-06',
            'description':
                'Glovebox breach recovery and floor decontamination, '
                'high-activity plutonium with HEPA replacement',
            'preparer': 'J. Coyle, Health Physicist',
          },
          'tasks': [
            task(
              title: 'Breach entry, source recovery, and initial decon',
              location: '234-5Z Room 118 Glovebox 7 (west bank)',
              workers: 6,
              hours: 12,
              doseRate: 12000,
              pfr: 50,
              pfe: 1000,
              nuclides: [
                nuc('Pu-239', 750000),
                nuc('Am-241', 250000),
                nuc('Cs-137', 1100000),
                nuc('Sr-90', 90000),
                nuc('Other', 40000, customDAC: 3e-12),
              ],
              extremities: [
                {
                  'nuclide': 'Pu-239',
                  'doseRate': 600,
                  'time': 10,
                  'contam': 750000,
                },
                {
                  'nuclide': 'Am-241',
                  'doseRate': 120,
                  'time': 4,
                  'contam': 250000,
                },
              ],
              sectionNotes: {
                'internalDose':
                    'Source term based on 2026-07-28 smears; assumes no '
                    'further release during entry. Respirator PF credited '
                    'per RPP-742.',
                'externalDose':
                    'Dose rate from telemetry probe at 30 cm from the breach.',
              },
            ),
            task(
              title: 'Secondary decon and survey',
              location: '234-5Z Room 118 floor',
              workers: 4,
              hours: 8,
              doseRate: 80,
              pfr: 50,
              pfe: 100000,
              nuclides: [nuc('Pu-239', 150000), nuc('Th-229', 500000)],
            ),
          ],
          'triggerOverrides': {'alara1': true, 'sampling3': true},
          'overrideJustifications': {
            'alara1':
                'First-of-a-kind glovebox breach recovery in this facility; '
                'work package has no prior performance history and involves '
                'non-standard tooling, so ALARA review is required regardless '
                'of computed dose.',
            'sampling3':
                'Job-specific air sampling directed by the Radiological '
                'Control Manager pending characterisation of the '
                'resuspension pathway.',
          },
        },
        {
          'useContaminationInput': false,
          'selectedConfinement': 'Open benchtop or surface contamination',
          'selectedForm': 'Powders',
          'selectedPifRelease':
              'Nonvolatile powders, somewhat volatile liquids',
          'selectedOccupancy': 'Daily (essentially daily)',
          'selectedDispersibility': 'Yes',
          'selectedSpecialForm': 'Normal',
          'controllers': {
            'totalActivity': '250',
            'volume': '2e8',
            'mixing': '0.6',
            'fa': '1',
            'fr': '0.1',
            'uncertainty': '3',
            'frJustification':
                'Breached containment — no confinement credit taken. Powder '
                'release fraction with an uncertainty factor of 3 reflecting '
                'the uncharacterised dispersal.',
          },
          'sourceTerm': [
            {'name': 'Pu-239', 'fraction': 0.45, 'dac': 0.0},
            {'name': 'Pu-240', 'fraction': 0.15, 'dac': 0.0},
            {'name': 'Am-241', 'fraction': 0.2, 'dac': 0.0},
            {'name': 'Cs-137', 'fraction': 0.1, 'dac': 0.0},
            {'name': 'Sr-90', 'fraction': 0.1, 'dac': 0.0},
          ],
        },
      ),
    ];

    final root = Directory('build/scenario_pdfs');
    if (root.existsSync()) root.deleteSync(recursive: true);
    root.createSync(recursive: true);

    for (final s in scenarios) {
      final dir = Directory('${root.path}/${s.folder}')
        ..createSync(recursive: true);
      await writeDose(tester, s, dir);
      await writeContainment(tester, s, dir);
      // ignore: avoid_print
      print('WROTE ${s.folder}');
    }
  });
}
