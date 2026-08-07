import 'package:flutter_test/flutter_test.dart';

import 'package:dose_dart_version/pdf_text.dart';

void main() {
  group('pdfSafeText', () {
    test('leaves plain ASCII untouched', () {
      const s = 'Valve repack, Co-60 field (30 cm) - see RS-2026-0810.';
      expect(pdfSafeText(s), s);
    });

    test('keeps Latin-1 characters the base font can draw', () {
      // These render correctly in the report today and must not regress to '?'.
      const s = 'DAC 5e-12 µCi/mL, 25 °C, 100 cm², 2e8 cm³, 90° bend';
      expect(pdfSafeText(s), s);
    });

    test('folds the dashes Word produces on paste', () {
      expect(
        pdfSafeText('Cell 4 outage — scaffold – removal'),
        'Cell 4 outage - scaffold - removal',
      );
      expect(pdfSafeText('minus − sign'), 'minus - sign');
    });

    test('folds curly quotes and apostrophes', () {
      expect(
        pdfSafeText('“Breach” in the worker’s glovebox'),
        '"Breach" in the worker\'s glovebox',
      );
    });

    test('spells out ellipsis and symbols', () {
      expect(pdfSafeText('pending…'), 'pending...');
      expect(pdfSafeText('™ mark'), '(TM) mark');
      expect(pdfSafeText('a → b'), 'a -> b');
    });

    test('collapses exotic spaces to a normal space', () {
      expect(pdfSafeText('5 mrem'), '5 mrem');
      expect(pdfSafeText('5 mrem'), '5 mrem');
    });

    test('drops zero-width characters entirely', () {
      expect(pdfSafeText('Pu​-239'), 'Pu-239');
      expect(pdfSafeText('﻿leading BOM'), 'leading BOM');
    });

    test('replaces unmappable characters visibly rather than silently', () {
      // A CJK character has no ASCII spelling; '?' makes the loss obvious
      // instead of dropping content out of a signed record.
      expect(pdfSafeText('dose 中 value'), 'dose ? value');
    });

    test('handles empty input', () {
      expect(pdfSafeText(''), '');
    });

    test('output of a fold is itself unchanged by a second pass', () {
      const messy = 'Word’s “paste” — pending…';
      final once = pdfSafeText(messy);
      expect(pdfSafeText(once), once);
    });
  });
}
