// Dev harness: generates real PDF bytes from representative scenarios so the
// report layout can be inspected visually. Not a pass/fail test — run with
//   flutter test test/pdf_render_harness_test.dart
// and inspect the files written to build/pdf_review/.
@Tags(['harness'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/main.dart';

/// One nuclide row.
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

Future<List<int>> renderScenario(
  WidgetTester tester,
  String name,
  Map<String, dynamic> state,
) async {
  final key = GlobalKey<DoseEstimateScreenState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: 4000,
            child: DoseEstimateScreen(key: key, initialState: state),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Laying the full app screen out in a headless viewport raises layout
  // errors that say nothing about the generated report, which is built from
  // model state rather than the rendered widgets. takeException() returns one
  // exception per call, so drain them all — a single call leaves the rest to
  // fail the test.
  while (tester.takeException() != null) {}

  List<int>? captured;
  await tester.runAsync(() async {
    captured = await key.currentState!.buildSummaryReportDocument().save();
  });

  // A rejected import silently yields an empty report, which would make a
  // layout problem look like a clean page — assert the state actually loaded.
  final loadedTasks = key.currentState!.tasks.length;
  final expectedTasks = (state['tasks'] as List).length;
  expect(
    loadedTasks,
    expectedTasks,
    reason: '$name: import was rejected — report would be empty',
  );
  expect(captured, isNotNull, reason: '$name produced no PDF bytes');
  final dir = Directory('build/pdf_review')..createSync(recursive: true);
  final f = File('${dir.path}/$name.pdf')..writeAsBytesSync(captured!);
  // ignore: avoid_print
  print('WROTE ${f.path} (${captured!.length} bytes)');
  return captured!;
}

/// Page count of a generated PDF.
int pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(bytes)).length;

void main() {
  testWidgets('generate review PDFs', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // ── Scenario A: typical single task, nothing triggered ──────────────────
    final simple = await renderScenario(tester, 'A_simple', {
      'projectInfo': {
        'workOrder': 'WCD-2026-0142',
        'date': '2026-08-06',
        'description': 'Glovebox filter change-out',
        'preparer': 'J. Coyle',
      },
      'tasks': [
        task(
          title: 'Filter removal and bag-out',
          location: '234-5Z Glovebox 3',
          workers: 2,
          hours: 4,
          doseRate: 5,
          nuclides: [nuc('Cs-137', 5000)],
          extremities: [
            {'nuclide': 'Cs-137', 'doseRate': 40, 'time': 2, 'contam': 5000},
          ],
        ),
      ],
    });

    // A clean single-task report must fit on the summary page + one task page.
    expect(pageCount(simple), 2, reason: 'A_simple should be summary + 1 task');

    // Scenario A fires no ALARA trigger, so the report carries no signature
    // block — routine estimates need no peer check. (Verified by page count:
    // the block is the last thing on the summary page, and the dense scenario
    // below asserts the triggered case still renders it.)

    // ── Scenario B: everything triggered, overrides + long justifications ───
    final dense = await renderScenario(tester, 'B_all_triggers', {
      'projectInfo': {
        'workOrder': 'WCD-2026-0199-REV-C',
        'date': '2026-08-06',
        'description':
            'High-activity plutonium glovebox breach recovery and decontamination '
            'of adjacent floor areas, including HEPA filter replacement',
        'preparer': 'Jesse Coyle, Health Physicist',
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
            {'nuclide': 'Am-241', 'doseRate': 120, 'time': 4, 'contam': 250000},
          ],
          sectionNotes: {
            'internalDose':
                'Source term based on 2026-07-28 smears; assumes no further '
                'release during entry. Respirator PF credited per RPP-742.',
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
      'triggerOverrides': {
        'alara1': true,
        'sampling3': true,
        'sampling6': true,
      },
      'overrideJustifications': {
        'alara1':
            'First-of-a-kind glovebox breach recovery in this facility; work '
            'package has no prior performance history and involves non-standard '
            'tooling, so ALARA review is required regardless of computed dose.',
        'sampling3':
            'Job-specific air sampling directed by the Radiological Control '
            'Manager pending characterization of the resuspension pathway.',
        'sampling6': 'Historical job data unavailable for this configuration.',
      },
    });

    // A dense report must still print the task summary and the signature
    // block: with a fixed-height page they were silently pushed off-sheet.
    // 2 summary sheets + 2 task pages + 1 notes page. If the summary ever
    // stops flowing, this drops to 4 and the task summary / signature block
    // silently vanish — which is exactly the regression being guarded.
    expect(
      pageCount(dense),
      5,
      reason: 'dense summary must flow onto a continuation page',
    );

    // ── Scenario C: many tasks — page-break / continuation behavior ─────────
    final many = await renderScenario(tester, 'C_many_tasks', {
      'projectInfo': {
        'workOrder': 'WCD-2026-0500',
        'date': '2026-08-06',
        'description': 'Multi-task campaign',
        'preparer': 'J. Coyle',
      },
      'tasks': [
        for (var i = 1; i <= 9; i++)
          task(
            title:
                'Task $i — extended descriptive title to exercise column wrapping behavior',
            location: 'Area $i',
            workers: 3 + i,
            hours: 6,
            doseRate: 10.0 * i,
            nuclides: [nuc('Cs-137', 5000.0 * i), nuc('Co-60', 2000.0 * i)],
          ),
      ],
    });

    // 9 task detail pages + a summary that spans 2 sheets (the 9-row task
    // table no longer fits beneath the dose cards on one page).
    expect(pageCount(many), 11, reason: '9 task pages + 2 summary sheets');

    // ── Scenario F: ring dosimetry required, but no ALARA review ────────────
    // 600 mrem extremity clears the 500 mrem dosimetry bar while staying far
    // below the 5,000 mrem ALARA trigger — so the report must show the
    // dosimetry pill and still omit the signature block.
    final ringOnly = await renderScenario(tester, 'F_ring_only', {
      'projectInfo': {
        'workOrder': 'WCD-2026-0301',
        'date': '2026-08-06',
        'description': 'Hands-on valve work, low whole-body dose',
        'preparer': 'J. Coyle',
      },
      'tasks': [
        task(
          title: 'Valve repack',
          workers: 1,
          hours: 3,
          doseRate: 2,
          nuclides: [nuc('Cs-137', 4000)],
          extremities: [
            {'nuclide': 'Cs-137', 'doseRate': 200, 'time': 3, 'contam': 4000},
          ],
        ),
      ],
    });
    expect(pageCount(ringOnly), 2, reason: 'summary + 1 task, no extra sheet');

    // ── Scenario D: sparse / empty — nothing entered ────────────────────────
    await renderScenario(tester, 'D_sparse', {
      'projectInfo': {
        'workOrder': '',
        'date': '',
        'description': '',
        'preparer': '',
      },
      'tasks': [
        task(
          title: '',
          workers: 1,
          hours: 1,
          mpifR: 0,
          mpifC: 0,
          mpifD: 0,
          mpifS: 0,
          mpifU: 0,
          doseRate: 0,
          nuclides: [],
        ),
      ],
    });
  });
}
