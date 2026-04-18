import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/constants.dart';
import '../data/library_repository.dart';
import '../models/book.dart';

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
      return _ErrorState(error: _error!, onRetry: _load);
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
        );
      },
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load library", style: textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text('$error', style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
