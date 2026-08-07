/// Text folding for the PDF reports.
///
/// The reports are typeset in the PDF standard Helvetica faces, whose encoding
/// covers Latin-1 (so µ, °, ² and ³ render) but not the General Punctuation
/// block. Characters from that block come out as hollow boxes.
///
/// This matters because the fields most likely to carry them — description,
/// section notes, override justifications — are free text, and pasting from
/// Word silently converts hyphens to en/em dashes and straight quotes to
/// curly ones. A signed dose assessment should not show boxes because of how
/// the preparer's word processor is configured, so user text is folded to
/// characters the font can actually draw.
library;

/// Characters outside Latin-1 that have a sensible ASCII spelling.
const Map<int, String> _foldings = {
  0x2010: '-', // hyphen
  0x2011: '-', // non-breaking hyphen
  0x2012: '-', // figure dash
  0x2013: '-', // en dash
  0x2014: '-', // em dash
  0x2015: '-', // horizontal bar
  0x2212: '-', // minus sign
  0x2018: "'", // left single quote
  0x2019: "'", // right single quote / apostrophe
  0x201A: "'", // single low quote
  0x201B: "'", // single high-reversed quote
  0x2032: "'", // prime
  0x201C: '"', // left double quote
  0x201D: '"', // right double quote
  0x201E: '"', // double low quote
  0x201F: '"', // double high-reversed quote
  0x2033: '"', // double prime
  0x2026: '...', // ellipsis
  0x2022: '-', // bullet
  0x2023: '-', // triangular bullet
  0x00A0: ' ', // non-breaking space
  0x2002: ' ', // en space
  0x2003: ' ', // em space
  0x2007: ' ', // figure space
  0x2009: ' ', // thin space
  0x200A: ' ', // hair space
  0x202F: ' ', // narrow no-break space
  0x200B: '', // zero-width space
  0x200C: '', // zero-width non-joiner
  0x200D: '', // zero-width joiner
  0xFEFF: '', // BOM / zero-width no-break space
  0x2039: '<',
  0x203A: '>',
  0x2044: '/', // fraction slash
  0x20AC: 'EUR', // euro sign — outside Latin-1
  0x2122: '(TM)',
  0x2192: '->',
  0x2190: '<-',
};

/// Folds [input] onto characters the report fonts can render.
///
/// Latin-1 passes through unchanged; known typographic characters are spelled
/// out in ASCII; anything else becomes '?' so the text stays legible and the
/// loss is visible rather than silent.
String pdfSafeText(String input) {
  if (input.isEmpty) return input;

  // Fast path: the overwhelmingly common case is text that needs no folding.
  // Note the foldings check — some entries (non-breaking space) are inside
  // Latin-1, so a bare `rune > 0xFF` test would skip them.
  var needsWork = false;
  for (final rune in input.runes) {
    if (rune > 0xFF || _foldings.containsKey(rune)) {
      needsWork = true;
      break;
    }
  }
  if (!needsWork) return input;

  final buf = StringBuffer();
  for (final rune in input.runes) {
    final folded = _foldings[rune];
    if (folded != null) {
      buf.write(folded);
    } else if (rune <= 0xFF) {
      buf.writeCharCode(rune);
    } else {
      buf.write('?');
    }
  }
  return buf.toString();
}
