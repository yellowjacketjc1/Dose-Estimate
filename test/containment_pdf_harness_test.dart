// Dev harness: generates the containment report from a source term large
// enough to overflow one sheet, so the layout can be inspected visually.
//   flutter test test/containment_pdf_harness_test.dart
// Output lands in build/pdf_review/.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/containment.dart';

/// Page count of a generated PDF.
int pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(bytes)).length;

void main() {
  testWidgets('generate containment review PDF', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
    // Headless-viewport layout errors say nothing about the generated report.
    // Drain them all: takeException() returns only one per call.
    while (tester.takeException() != null) {}

    // A long, realistic source term — the case that overflowed a fixed page.
    const names = [
      'Pu-239',
      'Pu-240',
      'Pu-241',
      'Am-241',
      'Cs-137',
      'Sr-90',
      'Co-60',
      'Eu-154',
      'U-235',
      'U-238',
      'Np-237',
      'Cm-244',
    ];
    key.currentState!.importState({
      'useContaminationInput': false,
      'controllers': {
        'totalActivity': '250',
        'volume': '2e8',
        'mixing': '0.6',
        'fa': '1',
        'fr': '0.01',
        'uncertainty': '1',
        'frJustification':
            'Release fraction based on RPP-742 Table 3 for spotty solid '
            'contamination inside an enclosed glovebox.',
      },
      'sourceTerm': [
        for (final n in names)
          {'name': n, 'fraction': 1.0 / names.length, 'dac': 0.0},
      ],
    });
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    List<int>? bytes;
    await tester.runAsync(() async {
      bytes = await key.currentState!.buildContainmentReportDocument().save();
    });

    expect(bytes, isNotNull);
    final dir = Directory('build/pdf_review')..createSync(recursive: true);
    File('${dir.path}/E_containment.pdf').writeAsBytesSync(bytes!);
    // ignore: avoid_print
    print('WROTE build/pdf_review/E_containment.pdf (${bytes!.length} bytes)');

    // A 12-nuclide source term must flow past one sheet rather than pushing
    // the containment verdict and bioassay assessment off the page.
    expect(
      pageCount(bytes!),
      greaterThanOrEqualTo(2),
      reason: 'long source term should flow onto a second page',
    );
  });
}
