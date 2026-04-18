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
  });

  final LibraryRepository repository;
  final ValueChanged<Book> onOpen;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  bool _loading = true;
  Object? _error;
  List<Book> _books = const [];

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

  Future<void> _pickFolder() async {
    final changed = await widget.repository.chooseFolder();
    if (changed) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Choose folder',
            onPressed: _pickFolder,
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
        onPickFolder: _pickFolder,
      );
    }
    return ListView.builder(
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return ListTile(
          title: Text(book.title),
          subtitle: Text(p.basename(book.path)),
          onTap: () => widget.onOpen(book),
          trailing: PopupMenuButton<_BookAction>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleAction(action, book),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _BookAction.rename, child: Text('Rename')),
              PopupMenuItem(value: _BookAction.delete, child: Text('Delete')),
            ],
          ),
        );
      },
    );
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
  const _EmptyState({required this.folderPath, required this.onPickFolder});

  final String? folderPath;
  final VoidCallback onPickFolder;

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
            Text('No books in', style: textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(location, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              'Add .md files or choose another folder.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onPickFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose folder'),
            ),
          ],
        ),
      ),
    );
  }
}

