import 'package:flutter_test/flutter_test.dart';

import 'package:vox/core/markdown/block_parser.dart';
import 'package:vox/core/markdown/toc.dart';

void main() {
  group('buildToc', () {
    test('returns empty list when there are no headings', () {
      final blocks = parseMarkdownBlocks('plain paragraph\n\nanother one');
      expect(buildToc(blocks), isEmpty);
    });

    test('emits one entry per heading in document order', () {
      final blocks = parseMarkdownBlocks(
        '# Part One\n\nintro\n\n## Chapter 1\n\nbody\n\n### Section A\n\nmore\n\n## Chapter 2',
      );
      final toc = buildToc(blocks);
      expect(toc.map((e) => e.title).toList(), [
        'Part One',
        'Chapter 1',
        'Section A',
        'Chapter 2',
      ]);
      expect(toc.map((e) => e.level).toList(), [
        BlockKind.h1,
        BlockKind.h2,
        BlockKind.h3,
        BlockKind.h2,
      ]);
    });

    test('depth reflects heading level for indentation', () {
      final blocks = parseMarkdownBlocks('# A\n## B\n### C');
      final toc = buildToc(blocks);
      expect(toc.map((e) => e.depth).toList(), [0, 1, 2]);
    });

    test('blockIndex points back at the source block', () {
      final blocks = parseMarkdownBlocks('# A\n\npara\n\n## B');
      final toc = buildToc(blocks);
      expect(blocks[toc[0].blockIndex].text, 'A');
      expect(blocks[toc[1].blockIndex].text, 'B');
    });
  });
}
