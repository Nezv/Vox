import 'block_parser.dart';

class TocEntry {
  const TocEntry({
    required this.level,
    required this.title,
    required this.blockIndex,
  });

  final BlockKind level;
  final String title;
  final int blockIndex;

  int get depth {
    switch (level) {
      case BlockKind.h1:
        return 0;
      case BlockKind.h2:
        return 1;
      case BlockKind.h3:
        return 2;
      case BlockKind.paragraph:
      case BlockKind.blank:
        return 0;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TocEntry &&
          other.level == level &&
          other.title == title &&
          other.blockIndex == blockIndex);

  @override
  int get hashCode => Object.hash(level, title, blockIndex);
}

List<TocEntry> buildToc(List<Block> blocks) {
  final entries = <TocEntry>[];
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    if (b.kind == BlockKind.h1 ||
        b.kind == BlockKind.h2 ||
        b.kind == BlockKind.h3) {
      entries.add(TocEntry(level: b.kind, title: b.text, blockIndex: i));
    }
  }
  return entries;
}
