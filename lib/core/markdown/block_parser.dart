enum BlockKind { h1, h2, h3, paragraph, blank }

class Block {
  const Block(this.kind, this.text);

  final BlockKind kind;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Block && other.kind == kind && other.text == text);

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'Block(${kind.name}, ${text.isEmpty ? '""' : text})';
}

List<Block> parseMarkdownBlocks(String source) {
  final blocks = <Block>[];
  final lines = source.split('\n');
  final paragraph = <String>[];
  var sawBlank = false;

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(Block(BlockKind.paragraph, paragraph.join(' ')));
    paragraph.clear();
  }

  void flushBlank() {
    if (!sawBlank) return;
    blocks.add(const Block(BlockKind.blank, ''));
    sawBlank = false;
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flushParagraph();
      sawBlank = true;
      continue;
    }

    final heading = _matchHeading(line);
    if (heading != null) {
      flushParagraph();
      flushBlank();
      blocks.add(heading);
      continue;
    }

    flushBlank();
    paragraph.add(line.trimLeft());
  }

  flushParagraph();
  return blocks;
}

Block? _matchHeading(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('### ')) {
    return Block(BlockKind.h3, trimmed.substring(4).trim());
  }
  if (trimmed.startsWith('## ')) {
    return Block(BlockKind.h2, trimmed.substring(3).trim());
  }
  if (trimmed.startsWith('# ')) {
    return Block(BlockKind.h1, trimmed.substring(2).trim());
  }
  return null;
}
