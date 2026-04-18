import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = "Couldn't load",
  });

  final Object error;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: textTheme.headlineMedium),
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
