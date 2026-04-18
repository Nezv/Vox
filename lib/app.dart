import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'views/book_view.dart';
import 'views/library_view.dart';

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
          home: const AppShell(),
        );
      },
    );
  }
}

enum View { library, book }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  View _view = View.library;

  void _go(View next) => setState(() => _view = next);

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case View.library:
        return LibraryView(onOpen: () => _go(View.book));
      case View.book:
        return BookView(onBack: () => _go(View.library));
    }
  }
}
