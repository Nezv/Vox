import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/book.dart';

class BookView extends StatelessWidget {
  const BookView({super.key, required this.book, required this.onBack});

  final Book book;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to library',
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(book.title, style: textTheme.headlineMedium),
        ),
      ),
    );
  }
}
