import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/core/markdown/block_parser.dart';
import 'package:vox/views/reader/paginator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const styles = ReaderTextStyles(
    h1: TextStyle(fontSize: 24, height: 1.2),
    h2: TextStyle(fontSize: 20, height: 1.2),
    h3: TextStyle(fontSize: 18, height: 1.2),
    paragraph: TextStyle(fontSize: 16, height: 1.6),
  );

  test('empty input yields no pages', () {
    final pages = paginateBlocks(
      blocks: const [],
      pageSize: const Size(400, 600),
      styles: styles,
    );
    expect(pages, isEmpty);
  });

  test('short content fits on a single page', () {
    final blocks = parseMarkdownBlocks('# Hello\n\nShort paragraph.');
    final pages = paginateBlocks(
      blocks: blocks,
      pageSize: const Size(400, 600),
      styles: styles,
    );
    expect(pages, hasLength(1));
    expect(pages.first.pieces.first.kind, BlockKind.h1);
    expect(pages.first.pieces.any((p) =>
        p.kind == BlockKind.paragraph && p.text == 'Short paragraph.'),
        isTrue);
    expect(pages.first.blockIndexes, containsAll([0, 2]));
  });

  test('long paragraph splits across multiple pages', () {
    final long = List.filled(400, 'word').join(' ');
    final blocks = [Block(BlockKind.paragraph, long)];
    final pages = paginateBlocks(
      blocks: blocks,
      pageSize: const Size(300, 200),
      styles: styles,
    );
    expect(pages.length, greaterThan(1));
    for (final page in pages) {
      expect(page.blockIndexes, contains(0));
      expect(page.pieces.first.kind, BlockKind.paragraph);
    }
    final rejoined =
        pages.map((p) => p.pieces.first.text).join(' ').replaceAll('  ', ' ');
    expect(rejoined.split(' ').length, greaterThanOrEqualTo(400));
  });

  test('leading blank is stripped from top of a page', () {
    final blocks = [
      const Block(BlockKind.blank, ''),
      const Block(BlockKind.paragraph, 'Hello.'),
    ];
    final pages = paginateBlocks(
      blocks: blocks,
      pageSize: const Size(300, 300),
      styles: styles,
    );
    expect(pages.first.pieces.first.kind, BlockKind.paragraph);
  });

  test('findSpreadForBlock returns the correct spread index', () {
    const pages = [
      ReaderPage(pieces: [], blockIndexes: [0, 1]),
      ReaderPage(pieces: [], blockIndexes: [2]),
      ReaderPage(pieces: [], blockIndexes: [3]),
      ReaderPage(pieces: [], blockIndexes: [4]),
    ];
    expect(findSpreadForBlock(pages: pages, blockIndex: 0, pagesPerSpread: 2), 0);
    expect(findSpreadForBlock(pages: pages, blockIndex: 2, pagesPerSpread: 2), 0);
    expect(findSpreadForBlock(pages: pages, blockIndex: 3, pagesPerSpread: 2), 1);
    expect(findSpreadForBlock(pages: pages, blockIndex: 4, pagesPerSpread: 2), 1);
    expect(findSpreadForBlock(pages: pages, blockIndex: 2, pagesPerSpread: 1), 1);
  });
}
