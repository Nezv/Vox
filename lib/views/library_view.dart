import 'package:flutter/material.dart';

import '../core/constants.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(kAppTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Library', style: textTheme.headlineMedium),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onOpen,
                child: const Text('Open sample'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
