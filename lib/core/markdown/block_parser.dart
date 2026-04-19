enum BlockKind { h1, h2, h3, paragraph, blank }

class InlineStyleRange {
  const InlineStyleRange(
    this.start,
    this.end, {
    this.bold = false,
    this.italic = false,
  });

  final int start;
  final int end;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InlineStyleRange &&
          other.start == start &&
          other.end == end &&
          other.bold == bold &&
          other.italic == italic);

  @override
  int get hashCode => Object.hash(start, end, bold, italic);
}

class Block {
  const Block(
    this.kind,
    this.text, {
    this.inlineStyles = const [],
  });

  final BlockKind kind;
  final String text;
  final List<InlineStyleRange> inlineStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Block &&
          other.kind == kind &&
          other.text == text &&
          _inlineStylesEqual(other.inlineStyles, inlineStyles));

  @override
  int get hashCode => Object.hash(kind, text, Object.hashAll(inlineStyles));

  @override
  String toString() => 'Block(${kind.name}, ${text.isEmpty ? '""' : text})';
}

List<Block> parseMarkdownBlocks(String source) {
  final blocks = <Block>[];
  final lines = source.split('\n');
  final paragraph = <_ParagraphLine>[];
  var sawBlank = false;

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    final out = StringBuffer();
    for (var i = 0; i < paragraph.length; i++) {
      if (i > 0) {
        out.write(paragraph[i - 1].hardBreakAfter ? '\n' : ' ');
      }
      out.write(paragraph[i].text);
    }
    final parsed = _parseInlineMarkdown(out.toString());
    blocks.add(Block(
      BlockKind.paragraph,
      parsed.text,
      inlineStyles: parsed.styles,
    ));
    paragraph.clear();
  }

  void flushBlank() {
    if (!sawBlank) return;
    blocks.add(const Block(BlockKind.blank, ''));
    sawBlank = false;
  }

  for (final raw in lines) {
    if (raw.trim().isEmpty) {
      flushParagraph();
      sawBlank = true;
      continue;
    }

    final heading = _matchHeading(raw.trimRight());
    if (heading != null) {
      flushParagraph();
      flushBlank();
      blocks.add(heading);
      continue;
    }

    flushBlank();
    paragraph.add(_paragraphLineFromRaw(raw));
  }

  flushParagraph();
  return blocks;
}

Block? _matchHeading(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('### ')) {
    final parsed = _parseInlineMarkdown(trimmed.substring(4).trim());
    return Block(BlockKind.h3, parsed.text, inlineStyles: parsed.styles);
  }
  if (trimmed.startsWith('## ')) {
    final parsed = _parseInlineMarkdown(trimmed.substring(3).trim());
    return Block(BlockKind.h2, parsed.text, inlineStyles: parsed.styles);
  }
  if (trimmed.startsWith('# ')) {
    final parsed = _parseInlineMarkdown(trimmed.substring(2).trim());
    return Block(BlockKind.h1, parsed.text, inlineStyles: parsed.styles);
  }
  return null;
}

_InlineParseResult _parseInlineMarkdown(String input) {
  final segments = _parseInlineSegments(input);
  final text = StringBuffer();
  final styles = <InlineStyleRange>[];
  var offset = 0;

  for (final segment in segments) {
    if (segment.text.isEmpty) continue;
    final start = offset;
    text.write(segment.text);
    offset += segment.text.length;
    if (!segment.bold && !segment.italic) continue;

    if (styles.isNotEmpty &&
        styles.last.end == start &&
        styles.last.bold == segment.bold &&
        styles.last.italic == segment.italic) {
      final last = styles.removeLast();
      styles.add(InlineStyleRange(
        last.start,
        offset,
        bold: segment.bold,
        italic: segment.italic,
      ));
      continue;
    }

    styles.add(InlineStyleRange(
      start,
      offset,
      bold: segment.bold,
      italic: segment.italic,
    ));
  }

  return _InlineParseResult(text.toString(), styles);
}

List<_InlineSegment> _parseInlineSegments(
  String text, {
  bool bold = false,
  bool italic = false,
}) {
  final segments = <_InlineSegment>[];
  final plain = StringBuffer();
  var i = 0;

  void flushPlain() {
    if (plain.isEmpty) return;
    segments.add(_InlineSegment(
      text: plain.toString(),
      bold: bold,
      italic: italic,
    ));
    plain.clear();
  }

  while (i < text.length) {
    final marker = _inlineMarkerAt(text, i);
    if (marker == null) {
      plain.write(text[i]);
      i++;
      continue;
    }

    final close = text.indexOf(marker, i + marker.length);
    if (close <= i + marker.length) {
      plain.write(text[i]);
      i++;
      continue;
    }

    flushPlain();
    final inner = text.substring(i + marker.length, close);
    segments.addAll(_parseInlineSegments(
      inner,
      bold: bold || _isBoldMarker(marker),
      italic: italic || _isItalicMarker(marker),
    ));
    i = close + marker.length;
  }

  flushPlain();
  return _mergeInlineSegments(segments);
}

String? _inlineMarkerAt(String text, int index) {
  for (final marker in const ['***', '___', '**', '__', '*', '_']) {
    if (text.startsWith(marker, index)) {
      return marker;
    }
  }
  return null;
}

bool _isBoldMarker(String marker) => marker.length >= 2;

bool _isItalicMarker(String marker) => marker.length == 1 || marker.length == 3;

List<_InlineSegment> _mergeInlineSegments(List<_InlineSegment> segments) {
  if (segments.isEmpty) return const [];
  final merged = <_InlineSegment>[segments.first];
  for (var i = 1; i < segments.length; i++) {
    final current = segments[i];
    final last = merged.last;
    if (last.bold == current.bold && last.italic == current.italic) {
      merged[merged.length - 1] = _InlineSegment(
        text: last.text + current.text,
        bold: current.bold,
        italic: current.italic,
      );
      continue;
    }
    merged.add(current);
  }
  return merged;
}

bool _inlineStylesEqual(List<InlineStyleRange> a, List<InlineStyleRange> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

_ParagraphLine _paragraphLineFromRaw(String raw) {
  final trailingSpaces = raw.length - raw.trimRight().length;
  var trimmedRight = raw.trimRight();
  var hardBreakAfter = trailingSpaces >= 2;

  if (trimmedRight.endsWith(r'\')) {
    hardBreakAfter = true;
    trimmedRight = trimmedRight.substring(0, trimmedRight.length - 1);
  }

  return _ParagraphLine(
    text: trimmedRight.trimLeft(),
    hardBreakAfter: hardBreakAfter,
  );
}

class _ParagraphLine {
  const _ParagraphLine({
    required this.text,
    required this.hardBreakAfter,
  });

  final String text;
  final bool hardBreakAfter;
}

class _InlineParseResult {
  const _InlineParseResult(this.text, this.styles);

  final String text;
  final List<InlineStyleRange> styles;
}

class _InlineSegment {
  const _InlineSegment({
    required this.text,
    required this.bold,
    required this.italic,
  });

  final String text;
  final bool bold;
  final bool italic;
}
