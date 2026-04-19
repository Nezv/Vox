import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vox/core/markdown/block_parser.dart';
import 'package:vox/views/reader/paginator.dart';
import 'package:vox/views/reader/reader_page_view.dart';

const _styles = ReaderTextStyles(
  h1: TextStyle(fontSize: 24, height: 1.2),
  h2: TextStyle(fontSize: 20, height: 1.2),
  h3: TextStyle(fontSize: 18, height: 1.2),
  paragraph: TextStyle(fontSize: 16, height: 1.6),
);

Widget _harness(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 400, child: child)),
    );

void main() {
  testWidgets('renders plain SelectableText when no highlight', (tester) async {
    const page = ReaderPage(
      pieces: [
        PagePiece(
          kind: BlockKind.paragraph,
          text: 'alpha beta gamma',
          blockCharOffset: 0,
        )
      ],
      pieceBlockIndexes: [0],
      blockIndexes: [0],
    );
    await tester.pumpWidget(_harness(
      const ReaderPageView(page: page, styles: _styles),
    ));
    expect(find.text('alpha beta gamma'), findsOneWidget);
  });

  testWidgets('applies inline markdown styles in paragraph spans',
      (tester) async {
    const page = ReaderPage(
      pieces: [
        PagePiece(
          kind: BlockKind.paragraph,
          text: 'alpha bold and italic',
          blockCharOffset: 0,
          inlineStyles: [
            InlineStyleRange(6, 10, bold: true),
            InlineStyleRange(15, 21, italic: true),
          ],
        )
      ],
      pieceBlockIndexes: [0],
      blockIndexes: [0],
    );

    await tester.pumpWidget(_harness(
      const ReaderPageView(page: page, styles: _styles),
    ));

    final selectable =
        tester.widget<SelectableText>(find.byType(SelectableText));
    final children = selectable.textSpan!.children!;
    expect(children, hasLength(4));
    expect((children[0] as TextSpan).text, 'alpha ');
    expect((children[1] as TextSpan).text, 'bold');
    expect((children[1] as TextSpan).style?.fontWeight, FontWeight.w700);
    expect((children[2] as TextSpan).text, ' and ');
    expect((children[3] as TextSpan).text, 'italic');
    expect((children[3] as TextSpan).style?.fontStyle, FontStyle.italic);
  });

  testWidgets('highlight splits paragraph into three TextSpans',
      (tester) async {
    const page = ReaderPage(
      pieces: [
        PagePiece(
          kind: BlockKind.paragraph,
          text: 'alpha beta gamma',
          blockCharOffset: 0,
        )
      ],
      pieceBlockIndexes: [0],
      blockIndexes: [0],
    );
    await tester.pumpWidget(_harness(
      const ReaderPageView(
        page: page,
        styles: _styles,
        highlightBlockIndex: 0,
        highlightRange: (6, 10),
      ),
    ));

    final selectable =
        tester.widget<SelectableText>(find.byType(SelectableText));
    final span = selectable.textSpan!;
    final children = span.children!;
    expect(children, hasLength(3));
    expect((children[0] as TextSpan).text, 'alpha ');
    expect((children[1] as TextSpan).text, 'beta');
    expect((children[2] as TextSpan).text, ' gamma');
    expect((children[1] as TextSpan).style?.backgroundColor, isNotNull);
  });

  testWidgets('highlight offset respects blockCharOffset of split piece',
      (tester) async {
    const page = ReaderPage(
      pieces: [
        PagePiece(
          kind: BlockKind.paragraph,
          text: 'beta gamma',
          blockCharOffset: 6,
        )
      ],
      pieceBlockIndexes: [0],
      blockIndexes: [0],
    );
    await tester.pumpWidget(_harness(
      const ReaderPageView(
        page: page,
        styles: _styles,
        highlightBlockIndex: 0,
        highlightRange: (6, 10),
      ),
    ));

    final selectable =
        tester.widget<SelectableText>(find.byType(SelectableText));
    final children = selectable.textSpan!.children!;
    expect(children, hasLength(2));
    expect((children[0] as TextSpan).text, 'beta');
    expect((children[1] as TextSpan).text, ' gamma');
  });
}
