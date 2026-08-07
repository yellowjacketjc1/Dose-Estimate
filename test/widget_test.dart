// Basic smoke test: the app builds and shows the topbar brand title.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/main.dart';

void main() {
  testWidgets('App shows title', (WidgetTester tester) async {
    // Desktop-sized surface — the topbar is designed for desktop widths.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Build the app and trigger a frame.
    await tester.pumpWidget(const DoseEstimateApp());

    // Verify that the topbar brand title is present.
    expect(find.text('Dose Assessment'), findsOneWidget);

    // The topbar must not overflow at a normal desktop width. This is asserted
    // explicitly because an overflowing Row clips its children: a few pixels
    // of font-metric difference on a CI runner silently dropped the title and
    // failed the check above with a confusing "found 0 widgets".
    expect(
      tester.takeException(),
      isNull,
      reason: 'topbar overflowed at 1440x900',
    );
  });
}
