import 'package:flutter/material.dart';

import '../../core/markdown/block_parser.dart';
import 'paginator.dart';

class ReaderPageView extends StatelessWidget {
  const ReaderPageView({
    super.key,
    required this.page,
    required this.styles,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    this.highlightBlockIndex,
    this.highlightRange,
    this.onTap,
  });

  final ReaderPage page;
  final ReaderTextStyles styles;
  final EdgeInsets padding;

  /// Source block index of the word currently being spoken, or null.
  final int? highlightBlockIndex;

  /// Character range `(start, end)` within the source block, or null.
  final (int, int)? highlightRange;

  /// Callback when text is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlightColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.22);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < page.pieces.length; i++)
              _buildPiece(
                  page.pieces[i], page.pieceBlockIndexes[i], highlightColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPiece(
      PagePiece piece, int? pieceBlockIndex, Color highlightColor) {
    switch (piece.kind) {
      case BlockKind.h1:
        return Padding(
          padding: EdgeInsets.only(bottom: styles.h1Gap),
          child: _buildHeading(piece, styles.h1),
        );
      case BlockKind.h2:
        return Padding(
          padding: EdgeInsets.only(bottom: styles.h2Gap),
          child: _buildHeading(piece, styles.h2),
        );
      case BlockKind.h3:
        return Padding(
          padding: EdgeInsets.only(bottom: styles.h3Gap),
          child: _buildHeading(piece, styles.h3),
        );
      case BlockKind.paragraph:
        return _buildParagraph(piece, pieceBlockIndex, highlightColor);
      case BlockKind.blank:
        return SizedBox(height: styles.blankGap);
    }
  }

  Widget _buildHeading(PagePiece piece, TextStyle style) {
    return Text.rich(
      TextSpan(
        style: style,
        children: _buildStyledSpans(
          text: piece.text,
          baseStyle: style,
          inlineStyles: piece.inlineStyles,
        ),
      ),
    );
  }

  Widget _buildParagraph(
    PagePiece piece,
    int? pieceBlockIndex,
    Color highlightColor,
  ) {
    final range = highlightRange;
    final offset = piece.blockCharOffset ?? 0;
    (int, int)? localHighlight;
    if (range != null &&
        highlightBlockIndex != null &&
        pieceBlockIndex == highlightBlockIndex) {
      final localStart = range.$1 - offset;
      final localEnd = range.$2 - offset;
      if (localEnd > 0 && localStart < piece.text.length) {
        final s = localStart.clamp(0, piece.text.length);
        final e = localEnd.clamp(0, piece.text.length);
        if (e > s) {
          localHighlight = (s, e);
        }
      }
    }

    return SelectableText.rich(
      TextSpan(
        style: styles.paragraph,
        children: _buildStyledSpans(
          text: piece.text,
          baseStyle: styles.paragraph,
          inlineStyles: piece.inlineStyles,
          highlightRange: localHighlight,
          highlightColor: highlightColor,
        ),
      ),
      onTap: onTap,
    );
  }

  List<TextSpan> _buildStyledSpans({
    required String text,
    required TextStyle baseStyle,
    required List<InlineStyleRange> inlineStyles,
    (int, int)? highlightRange,
    Color? highlightColor,
  }) {
    if (text.isEmpty) return const [];

    final boundaries = <int>{0, text.length};
    for (final range in inlineStyles) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    if (highlightRange != null) {
      boundaries.add(highlightRange.$1.clamp(0, text.length));
      boundaries.add(highlightRange.$2.clamp(0, text.length));
    }

    final cuts = boundaries.toList()..sort();
    final spans = <TextSpan>[];
    for (var i = 0; i < cuts.length - 1; i++) {
      final start = cuts[i];
      final end = cuts[i + 1];
      if (start >= end) continue;

      var bold = false;
      var italic = false;
      for (final range in inlineStyles) {
        if (range.start < end && range.end > start) {
          bold = bold || range.bold;
          italic = italic || range.italic;
        }
      }

      final highlighted = highlightRange != null &&
          highlightRange.$1 < end &&
          highlightRange.$2 > start;

      spans.add(TextSpan(
        text: text.substring(start, end),
        style: baseStyle.copyWith(
          fontWeight: bold ? FontWeight.w700 : null,
          fontStyle: italic ? FontStyle.italic : null,
          backgroundColor: highlighted ? highlightColor : null,
        ),
      ));
    }
    return spans;
  }
}
