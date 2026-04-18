import 'package:flutter_test/flutter_test.dart';

import 'package:vox/core/markdown/block_parser.dart';

void main() {
  group('parseMarkdownBlocks', () {
    test('empty source yields no blocks', () {
      expect(parseMarkdownBlocks(''), isEmpty);
    });

    test('parses all three heading levels, stripping the marker', () {
      final blocks = parseMarkdownBlocks('# One\n## Two\n### Three');
      expect(blocks, [
        const Block(BlockKind.h1, 'One'),
        const Block(BlockKind.h2, 'Two'),
        const Block(BlockKind.h3, 'Three'),
      ]);
    });

    test('joins consecutive non-blank lines preserving line breaks', () {
      final blocks = parseMarkdownBlocks('alpha\nbeta\ngamma');
      expect(blocks, [const Block(BlockKind.paragraph, 'alpha\nbeta\ngamma')]);
    });

    test('mixed line breaks and blank line splits into two paragraphs', () {
      final blocks = parseMarkdownBlocks('line1\nline2\n\nline3');
      expect(blocks, [
        const Block(BlockKind.paragraph, 'line1\nline2'),
        const Block(BlockKind.blank, ''),
        const Block(BlockKind.paragraph, 'line3'),
      ]);
    });

    test('splits paragraphs on blank lines and collapses runs of blanks', () {
      final blocks = parseMarkdownBlocks('one\n\n\n\ntwo');
      expect(blocks, [
        const Block(BlockKind.paragraph, 'one'),
        const Block(BlockKind.blank, ''),
        const Block(BlockKind.paragraph, 'two'),
      ]);
    });

    test('heading between paragraphs does not emit a stray blank', () {
      final blocks = parseMarkdownBlocks('intro line\n## Heading\nbody line');
      expect(blocks, [
        const Block(BlockKind.paragraph, 'intro line'),
        const Block(BlockKind.h2, 'Heading'),
        const Block(BlockKind.paragraph, 'body line'),
      ]);
    });

    test('four-hash lines are treated as paragraph text, not headings', () {
      final blocks = parseMarkdownBlocks('#### Not a heading');
      expect(blocks, [const Block(BlockKind.paragraph, '#### Not a heading')]);
    });

    test('trailing blanks do not emit a blank block', () {
      final blocks = parseMarkdownBlocks('body\n\n\n');
      expect(blocks, [const Block(BlockKind.paragraph, 'body')]);
    });
  });
}
