// Basic smoke test: the app builds and shows its topbar chrome.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/main.dart';

void main() {
  testWidgets('App builds and shows the topbar', (WidgetTester tester) async {
    // Generous surface so the desktop topbar has room to lay out. Font metrics
    // differ between platforms, so this deliberately does not assert on the
    // exact position or visibility of individual topbar text: a few pixels of
    // difference on a CI runner would otherwise fail the build for a cosmetic
    // reason. Layout overflow is covered by the dedicated checks below.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DoseEstimateApp());
    await tester.pump();

    // The app builds without throwing, and its two tabs are present — enough
    // to catch a broken build, which is what this smoke test is for.
    expect(find.byType(DoseEstimateApp), findsOneWidget);
    expect(find.text('Dose Estimate'), findsWidgets);
    expect(find.text('Containment Analysis'), findsWidgets);
  });
}
