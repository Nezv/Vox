import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/markdown/block_parser.dart';
import '../data/book_content_repository.dart';
import '../models/book.dart';
import 'error_state.dart';

class BookView extends StatefulWidget {
  const BookView({
    super.key,
    required this.book,
    required this.onBack,
    required this.repository,
  });

  final Book book;
  final VoidCallback onBack;
  final BookContentRepository repository;

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  bool _loading = true;
  Object? _error;
  List<Block> _blocks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await widget.repository.read(widget.book.path);
      if (!mounted) return;
      setState(() {
        _blocks = parseMarkdownBlocks(raw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to library',
          onPressed: widget.onBack,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(
        error: _error!,
        onRetry: _load,
        title: "Couldn't open book",
      );
    }
    final hasContent = _blocks.any((b) => b.kind != BlockKind.blank);
    if (!hasContent) {
      final textTheme = Theme.of(context).textTheme;
      return Center(
        child: Text('Empty book', style: textTheme.bodyMedium),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      itemCount: _blocks.length,
      itemBuilder: (context, index) => _BlockWidget(block: _blocks[index]),
    );
  }
}

class _BlockWidget extends StatelessWidget {
  const _BlockWidget({required this.block});

  final Block block;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    switch (block.kind) {
      case BlockKind.h1:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(block.text, style: textTheme.headlineMedium),
        );
      case BlockKind.h2:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(block.text, style: textTheme.titleLarge),
        );
      case BlockKind.h3:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(block.text, style: textTheme.titleMedium),
        );
      case BlockKind.paragraph:
        return SelectableText(block.text, style: textTheme.bodyLarge);
      case BlockKind.blank:
        return const SizedBox(height: 16);
    }
  }
}
