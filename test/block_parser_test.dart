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

    test('line breaks inside paragraph are preserved', () {
      final blocks = parseMarkdownBlocks('line1\nline2\n\nline3');
      expect(blocks, [
        const Block(BlockKind.paragraph, 'line1\nline2'),
        const Block(BlockKind.blank, ''),
        const Block(BlockKind.paragraph, 'line3'),
      ]);
    });

    test('two trailing spaces keep the source line break', () {
      final blocks = parseMarkdownBlocks('line1  \nline2');
      expect(blocks, [const Block(BlockKind.paragraph, 'line1\nline2')]);
    });

    test('trailing backslash is preserved literally', () {
      final blocks = parseMarkdownBlocks('line1\\\nline2');
      expect(blocks, [const Block(BlockKind.paragraph, 'line1\\\nline2')]);
    });

    test('mixed paragraph keeps original line breaks', () {
      final blocks = parseMarkdownBlocks('one  \ntwo\nthree');
      expect(blocks, [const Block(BlockKind.paragraph, 'one\ntwo\nthree')]);
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

    test('parses inline bold and italic styles in paragraph text', () {
      final blocks = parseMarkdownBlocks('alpha **bold** and *italic* text');
      expect(blocks, [
        const Block(
          BlockKind.paragraph,
          'alpha bold and italic text',
          inlineStyles: [
            InlineStyleRange(6, 10, bold: true),
            InlineStyleRange(15, 21, italic: true),
          ],
        ),
      ]);
    });

    test('parses inline bold and italic styles in heading text', () {
      final blocks = parseMarkdownBlocks('# Title with **bold** and *italic*');
      expect(blocks, [
        const Block(
          BlockKind.h1,
          'Title with bold and italic',
          inlineStyles: [
            InlineStyleRange(11, 15, bold: true),
            InlineStyleRange(20, 26, italic: true),
          ],
        ),
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
