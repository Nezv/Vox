import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/constants.dart';
import '../data/library_repository.dart';
import '../models/book.dart';
import 'error_state.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    required this.repository,
    required this.onOpen,
    this.bookProgress = const {},
  });

  final LibraryRepository repository;
  final ValueChanged<Book> onOpen;
  final Map<String, double> bookProgress;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

enum _BookSort { nameAsc, nameDesc, progressDesc }

class _LibraryViewState extends State<LibraryView> {
  bool _loading = true;
  Object? _error;
  List<Book> _books = const [];
  _BookSort _sort = _BookSort.nameAsc;

  List<Book> get _sortedBooks {
    final sorted = List.of(_books);
    switch (_sort) {
      case _BookSort.nameAsc:
        sorted.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _BookSort.nameDesc:
        sorted.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case _BookSort.progressDesc:
        sorted.sort((a, b) {
          final pa = widget.bookProgress[a.path] ?? 0.0;
          final pb = widget.bookProgress[b.path] ?? 0.0;
          return pb.compareTo(pa);
        });
    }
    return sorted;
  }

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
      final books = await widget.repository.loadBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
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

  Future<void> _importBooks() async {
    final messenger = ScaffoldMessenger.of(context);
    final imported = await widget.repository.importBooks();
    if (!mounted) return;
    if (imported > 0) {
      await _load();
      final noun = imported == 1 ? 'book' : 'books';
      messenger.showSnackBar(SnackBar(content: Text('Imported $imported $noun')));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('No markdown files selected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppTitle),
        actions: [
          PopupMenuButton<_BookSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _BookSort.nameAsc,
                child: Text('Name A–Z'),
              ),
              PopupMenuItem(
                value: _BookSort.nameDesc,
                child: Text('Name Z–A'),
              ),
              PopupMenuItem(
                value: _BookSort.progressDesc,
                child: Text('Most read first'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import books',
            onPressed: _importBooks,
          ),
        ],
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
        title: "Couldn't load library",
      );
    }
    if (_books.isEmpty) {
      return _EmptyState(
        folderPath: widget.repository.folderPath,
        onImportBooks: _importBooks,
      );
    }
    final books = _sortedBooks;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          itemCount: books.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.67,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            final fraction = widget.bookProgress[book.path] ?? 0.0;
            return _BookCard(
              book: book,
              progressFraction: fraction,
              onOpen: () => widget.onOpen(book),
              onAction: (action) => _handleAction(action, book),
            );
          },
        );
      },
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 980) return 6;
    if (width >= 760) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  Future<void> _handleAction(_BookAction action, Book book) async {
    switch (action) {
      case _BookAction.rename:
        await _renameBook(book);
        break;
      case _BookAction.delete:
        await _deleteBook(book);
        break;
    }
  }

  Future<void> _renameBook(Book book) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentBase = p.basenameWithoutExtension(book.path);
    final newBase = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameDialog(initial: currentBase),
    );
    if (newBase == null || newBase.trim().isEmpty) return;
    if (newBase.trim() == currentBase) return;
    try {
      await widget.repository.rename(book, newBase.trim());
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't rename: $e")));
    }
  }

  Future<void> _deleteBook(Book book) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('"${book.title}" will be removed from disk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.delete(book);
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't delete: $e")));
    }
  }
}

enum _BookAction { rename, delete }

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.progressFraction,
    required this.onOpen,
    required this.onAction,
  });

  final Book book;
  final double progressFraction;
  final VoidCallback onOpen;
  final ValueChanged<_BookAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 4,
                      top: 4,
                      child: PopupMenuButton<_BookAction>(
                        tooltip: 'More',
                        icon: const Icon(Icons.more_vert),
                        onSelected: onAction,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _BookAction.rename,
                            child: Text('Rename'),
                          ),
                          PopupMenuItem(
                            value: _BookAction.delete,
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Icon(
                        Icons.menu_book,
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Text(
                p.basename(book.path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (progressFraction > 0.01)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 3,
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Name cannot be empty');
      return;
    }
    if (value.contains('/') || value.contains('\\') || value.contains(':')) {
      setState(() => _errorText = 'No path separators');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename book'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'File name',
          suffixText: '.md',
          errorText: _errorText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Rename')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.folderPath, required this.onImportBooks});

  final String? folderPath;
  final VoidCallback onImportBooks;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final location = folderPath ?? '(no folder)';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No books yet', style: textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text('Library folder', style: textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(location, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              'Import .md files to build your library. Imported books stay in this folder for future runs.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onImportBooks,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import books'),
            ),
          ],
        ),
      ),
    );
  }
}

