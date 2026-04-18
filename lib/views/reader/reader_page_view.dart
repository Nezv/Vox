import 'package:flutter/material.dart';

import '../../core/markdown/block_parser.dart';
import 'paginator.dart';

class ReaderPageView extends StatelessWidget {
  const ReaderPageView({
    super.key,
    required this.page,
    required this.styles,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
  });

  final ReaderPage page;
  final ReaderTextStyles styles;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final piece in page.pieces) _buildPiece(piece),
        ],
      ),
    );
  }

  Widget _buildPiece(PagePiece piece) {
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
        return SelectableText(piece.text, style: styles.paragraph);
      case BlockKind.blank:
        return SizedBox(height: styles.blankGap);
    }
  }
}
