import 'package:flutter/painting.dart';

import '../../core/markdown/block_parser.dart';

class ReaderTextStyles {
  const ReaderTextStyles({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.paragraph,
    this.h1Gap = 16,
    this.h2Gap = 12,
    this.h3Gap = 8,
    this.blankGap = 16,
  });

  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle paragraph;
  final double h1Gap;
  final double h2Gap;
  final double h3Gap;
  final double blankGap;

  TextStyle styleFor(BlockKind kind) {
    switch (kind) {
      case BlockKind.h1:
        return h1;
      case BlockKind.h2:
        return h2;
      case BlockKind.h3:
        return h3;
      case BlockKind.paragraph:
      case BlockKind.blank:
        return paragraph;
    }
  }

  double gapFor(BlockKind kind) {
    switch (kind) {
      case BlockKind.h1:
        return h1Gap;
      case BlockKind.h2:
        return h2Gap;
      case BlockKind.h3:
        return h3Gap;
      case BlockKind.blank:
        return blankGap;
      case BlockKind.paragraph:
        return 0;
    }
  }
}

class PagePiece {
  const PagePiece({required this.kind, required this.text});

  final BlockKind kind;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagePiece && other.kind == kind && other.text == text);

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'PagePiece(${kind.name}, "$text")';
}

class ReaderPage {
  const ReaderPage({required this.pieces, required this.blockIndexes});

  final List<PagePiece> pieces;
  final List<int> blockIndexes;
}

List<ReaderPage> paginateBlocks({
  required List<Block> blocks,
  required Size pageSize,
  required ReaderTextStyles styles,
}) {
  if (pageSize.width <= 0 || pageSize.height <= 0 || blocks.isEmpty) {
    return const [];
  }

  final pages = <ReaderPage>[];
  var pieces = <PagePiece>[];
  var blockIndexes = <int>{};
  var usedHeight = 0.0;

  void finalize() {
    if (pieces.isEmpty) return;
    pages.add(ReaderPage(
      pieces: List.unmodifiable(pieces),
      blockIndexes: (blockIndexes.toList()..sort()),
    ));
    pieces = <PagePiece>[];
    blockIndexes = <int>{};
    usedHeight = 0;
  }

  double remaining() => pageSize.height - usedHeight;

  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    switch (block.kind) {
      case BlockKind.h1:
      case BlockKind.h2:
      case BlockKind.h3:
        final style = styles.styleFor(block.kind);
        final gap = styles.gapFor(block.kind);
        final height =
            _measureHeight(block.text, style, pageSize.width) + gap;
        if (height > remaining() && pieces.isNotEmpty) {
          finalize();
        }
        pieces.add(PagePiece(kind: block.kind, text: block.text));
        blockIndexes.add(i);
        usedHeight += height;
        break;

      case BlockKind.blank:
        if (pieces.isEmpty) continue;
        final gap = styles.blankGap;
        if (gap > remaining()) {
          finalize();
          continue;
        }
        pieces.add(const PagePiece(kind: BlockKind.blank, text: ''));
        usedHeight += gap;
        break;

      case BlockKind.paragraph:
        var text = block.text;
        while (text.isNotEmpty) {
          final full = _measureHeight(text, styles.paragraph, pageSize.width);
          final room = remaining();
          if (full <= room) {
            pieces.add(PagePiece(kind: BlockKind.paragraph, text: text));
            blockIndexes.add(i);
            usedHeight += full;
            text = '';
            break;
          }
          if (pieces.isEmpty && room <= 0) {
            // Degenerate: page is too small even empty; avoid infinite loop.
            pieces.add(PagePiece(kind: BlockKind.paragraph, text: text));
            blockIndexes.add(i);
            finalize();
            text = '';
            break;
          }
          final split = _splitAtHeight(
            text,
            styles.paragraph,
            pageSize.width,
            room,
          );
          if (split.$1.isEmpty) {
            finalize();
            continue;
          }
          pieces.add(PagePiece(kind: BlockKind.paragraph, text: split.$1));
          blockIndexes.add(i);
          finalize();
          text = split.$2;
        }
        break;
    }
  }

  finalize();
  return pages;
}

int findSpreadForBlock({
  required List<ReaderPage> pages,
  required int blockIndex,
  required int pagesPerSpread,
}) {
  for (var i = 0; i < pages.length; i++) {
    if (pages[i].blockIndexes.contains(blockIndex)) {
      return i ~/ pagesPerSpread;
    }
  }
  return 0;
}

double _measureHeight(String text, TextStyle style, double width) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final h = tp.height;
  tp.dispose();
  return h;
}

(String, String) _splitAtHeight(
  String text,
  TextStyle style,
  double width,
  double maxHeight,
) {
  if (maxHeight <= 0) return ('', text);
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);

  final pos = tp.getPositionForOffset(Offset(width, maxHeight));
  tp.dispose();
  var cut = pos.offset;
  if (cut <= 0) return ('', text);
  if (cut >= text.length) return (text, '');

  var snap = cut;
  while (snap > 0 && !_isBreak(text.codeUnitAt(snap - 1))) {
    snap--;
  }
  if (snap == 0) snap = cut;

  final prefix = text.substring(0, snap).replaceFirst(RegExp(r'\s+$'), '');
  final remainder = text.substring(snap).replaceFirst(RegExp(r'^\s+'), '');
  if (prefix.isEmpty) return ('', text);
  return (prefix, remainder);
}

bool _isBreak(int c) => c == 0x20 || c == 0x0A || c == 0x09;
