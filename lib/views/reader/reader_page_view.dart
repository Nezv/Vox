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
  });

  final ReaderPage page;
  final ReaderTextStyles styles;
  final EdgeInsets padding;

  /// Source block index of the word currently being spoken, or null.
  final int? highlightBlockIndex;

  /// Character range `(start, end)` within the source block, or null.
  final (int, int)? highlightRange;

  @override
  Widget build(BuildContext context) {
    final highlightColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.22);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < page.pieces.length; i++)
            _buildPiece(page.pieces[i], page.pieceBlockIndexes[i], highlightColor),
        ],
      ),
    );
  }

  Widget _buildPiece(PagePiece piece, int? pieceBlockIndex, Color highlightColor) {
    switch (piece.kind) {
      case BlockKind.h1:
        return Padding(
          padding: EdgeInsets.only(bottom: styles.h1Gap),
          child: Text(piece.text, style: styles.h1),
        );
      case BlockKind.h2:
        return Padding(
          padding: EdgeInsets.only(bottom: styles.h2Gap),
          child: Text(piece.text, style: styles.h2),
        );
      case BlockKind.h3:
        return Padding(
          padding: EdgeInsets.only(bottom: styles.h3Gap),
          child: Text(piece.text, style: styles.h3),
        );
      case BlockKind.paragraph:
        return _buildParagraph(piece, pieceBlockIndex, highlightColor);
      case BlockKind.blank:
        return SizedBox(height: styles.blankGap);
    }
  }

  Widget _buildParagraph(
    PagePiece piece,
    int? pieceBlockIndex,
    Color highlightColor,
  ) {
    final range = highlightRange;
    final offset = piece.blockCharOffset ?? 0;
    if (range == null ||
        highlightBlockIndex == null ||
        pieceBlockIndex != highlightBlockIndex) {
      return SelectableText(piece.text, style: styles.paragraph);
    }
    final localStart = range.$1 - offset;
    final localEnd = range.$2 - offset;
    if (localEnd <= 0 || localStart >= piece.text.length) {
      return SelectableText(piece.text, style: styles.paragraph);
    }
    final s = localStart.clamp(0, piece.text.length);
    final e = localEnd.clamp(0, piece.text.length);
    return SelectableText.rich(
      TextSpan(
        style: styles.paragraph,
        children: [
          if (s > 0) TextSpan(text: piece.text.substring(0, s)),
          TextSpan(
            text: piece.text.substring(s, e),
            style: TextStyle(backgroundColor: highlightColor),
          ),
          if (e < piece.text.length)
            TextSpan(text: piece.text.substring(e)),
        ],
      ),
    );
  }
}
