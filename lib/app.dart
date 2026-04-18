import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class VoxApp extends StatefulWidget {
  const VoxApp({super.key});

  @override
  State<VoxApp> createState() => _VoxAppState();
}

class _VoxAppState extends State<VoxApp> {
  final ThemeController _theme = ThemeController();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _theme,
      builder: (context, _) {
        return MaterialApp(
          title: kAppTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(_theme.mode),
          home: HomeScaffold(controller: _theme),
        );
      },
    );
  }
}

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key, required this.controller});

  final ThemeController controller;

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
              Text(
                'dev environment — scaffold',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: AppThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.sepia,
                    label: Text('Sepia'),
                    icon: Icon(Icons.menu_book_outlined),
                  ),
                ],
                selected: {controller.mode},
                onSelectionChanged: (selection) =>
                    controller.setMode(selection.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
