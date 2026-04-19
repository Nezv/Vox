import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/reader_settings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/book_content_repository.dart';
import 'data/library_repository.dart';
import 'data/reading_state_repository.dart';
import 'models/book.dart';
import 'tts/noop_tts_engine.dart';
import 'tts/tts_engine.dart';
import 'views/book_view.dart';
import 'views/library_view.dart';

class VoxApp extends StatefulWidget {
  const VoxApp({
    super.key,
    this.repository,
    this.contentRepository,
    this.readingStateRepository,
    this.themeController,
    this.readerSettings,
    this.ttsEngine,
  });

  final LibraryRepository? repository;
  final BookContentRepository? contentRepository;
  final ReadingStateRepository? readingStateRepository;
  final ThemeController? themeController;
  final ReaderSettings? readerSettings;
  final TtsEngine? ttsEngine;

  @override
  State<VoxApp> createState() => _VoxAppState();
}

class _VoxAppState extends State<VoxApp> {
  late final ThemeController _theme =
      widget.themeController ?? ThemeController();
  late final ReaderSettings _settings =
      widget.readerSettings ?? ReaderSettings();
  late final LibraryRepository _repository =
      widget.repository ?? FileSystemLibraryRepository();
  late final BookContentRepository _contentRepository =
      widget.contentRepository ?? const FileSystemBookContentRepository();
  late final ReadingStateRepository _stateRepository =
      widget.readingStateRepository ?? FileSystemReadingStateRepository();
  late final TtsEngine _ttsEngine = widget.ttsEngine ?? NoopTtsEngine();

  late final bool _ownsTheme = widget.themeController == null;
  late final bool _ownsSettings = widget.readerSettings == null;
  late final bool _ownsTts = widget.ttsEngine == null;

  @override
  void dispose() {
    if (_ownsTheme) _theme.dispose();
    if (_ownsSettings) _settings.dispose();
    if (_ownsTts) _ttsEngine.dispose();
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
          home: AppShell(
            repository: _repository,
            contentRepository: _contentRepository,
            stateRepository: _stateRepository,
            theme: _theme,
            settings: _settings,
            ttsEngine: _ttsEngine,
          ),
        );
      },
    );
  }
}

enum View { library, book }

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.contentRepository,
    required this.stateRepository,
    required this.theme,
    required this.settings,
    required this.ttsEngine,
  });

  final LibraryRepository repository;
  final BookContentRepository contentRepository;
  final ReadingStateRepository stateRepository;
  final ThemeController theme;
  final ReaderSettings settings;
  final TtsEngine ttsEngine;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  View _view = View.library;
  Book? _selected;
  int _initialPage = 0;
  int _initialBlockIndex = 0;
  int _initialCharOffset = 0;
  bool _booting = true;

  int _currentPage = 0;
  int _currentBlockIndex = 0;
  int _currentCharOffset = 0;
  double _currentFraction = 0.0;
  Map<String, double> _bookProgress = const {};

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final progress = await widget.stateRepository.loadAllProgress();
      if (!mounted) return;
      setState(() {
        _bookProgress = progress;
        _booting = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _booting = false);
      }
    }
  }

  void _open(Book book) {
    setState(() {
      _selected = book;
      _initialPage = 0;
      _initialBlockIndex = 0;
      _initialCharOffset = 0;
      _currentPage = 0;
      _currentBlockIndex = 0;
      _currentCharOffset = 0;
      _currentFraction = 0.0;
      _view = View.book;
    });
    widget.stateRepository.save(
      ReadingState(bookPath: book.path, pageIndex: 0),
    );
  }

  void _back() {
    setState(() => _view = View.library);
  }

  void _onPageChanged(int page) {
    final book = _selected;
    if (book == null) return;
    _currentPage = page;
    widget.stateRepository.save(ReadingState(
      bookPath: book.path,
      pageIndex: page,
      blockIndex: _currentBlockIndex,
      charOffset: _currentCharOffset,
      progressFraction: _currentFraction,
    ));
  }

  void _onCursorChanged(int blockIndex, int charOffset, double fraction) {
    final book = _selected;
    if (book == null) return;
    _currentBlockIndex = blockIndex;
    _currentCharOffset = charOffset;
    _currentFraction = fraction;
    _bookProgress = Map.of(_bookProgress)..[book.path] = fraction;
    widget.stateRepository.save(ReadingState(
      bookPath: book.path,
      pageIndex: _currentPage,
      blockIndex: blockIndex,
      charOffset: charOffset,
      progressFraction: fraction,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (_view) {
      case View.library:
        return LibraryView(
          repository: widget.repository,
          onOpen: _open,
          bookProgress: _bookProgress,
        );
      case View.book:
        assert(_selected != null, 'BookView requires a selected book');
        return BookView(
          book: _selected!,
          onBack: _back,
          repository: widget.contentRepository,
          settings: widget.settings,
          theme: widget.theme,
          ttsEngine: widget.ttsEngine,
          initialPage: _initialPage,
          initialBlockIndex: _initialBlockIndex,
          initialCharOffset: _initialCharOffset,
          onPageChanged: _onPageChanged,
          onCursorChanged: _onCursorChanged,
        );
    }
  }
}
