import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/markdown/block_parser.dart';
import '../core/markdown/toc.dart';
import '../core/reader_settings.dart';
import '../core/theme/theme_controller.dart';
import '../data/book_content_repository.dart';
import '../models/book.dart';
import '../tts/playback_controller.dart';
import '../tts/tts_engine.dart';
import 'error_state.dart';
import 'reader/paginator.dart';
import 'reader/playback_bar.dart';
import 'reader/reader_page_view.dart';
import 'reader/reader_settings_sheet.dart';

const double _spreadBreakpoint = 720;
const double _spreadGutter = 24;
const EdgeInsets _pagePadding =
    EdgeInsets.symmetric(horizontal: 32, vertical: 24);
const Duration _fadeDelay = Duration(seconds: 3);
const Duration _fadeDuration = Duration(milliseconds: 250);

class BookView extends StatefulWidget {
  const BookView({
    super.key,
    required this.book,
    required this.onBack,
    required this.repository,
    required this.settings,
    required this.theme,
    required this.ttsEngine,
    this.initialPage = 0,
    this.onPageChanged,
  });

  final Book book;
  final VoidCallback onBack;
  final BookContentRepository repository;
  final ReaderSettings settings;
  final ThemeController theme;
  final TtsEngine ttsEngine;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  bool _loading = true;
  Object? _error;
  List<Block> _blocks = const [];
  List<TocEntry> _toc = const [];

  PageController? _controller;
  List<ReaderPage> _cachedPages = const [];
  String? _pageCacheKey;
  int _pagesPerSpread = 1;
  int _currentSpread = 0;

  bool _chromeVisible = true;
  Timer? _fadeTimer;

  late final PlaybackController _playback;
  bool _autoFollow = true;
  Timer? _autoFollowRearmTimer;

  @override
  void initState() {
    super.initState();
    _currentSpread = widget.initialPage;
    widget.settings.addListener(_onSettingsChanged);
    widget.theme.addListener(_onSettingsChanged);
    _playback = PlaybackController(engine: widget.ttsEngine);
    _playback.addListener(_onPlaybackChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant BookView old) {
    super.didUpdateWidget(old);
    if (old.book != widget.book) {
      _currentSpread = widget.initialPage;
      _controller?.dispose();
      _controller = null;
      _cachedPages = const [];
      _pageCacheKey = null;
      _load();
    }
    if (old.settings != widget.settings) {
      old.settings.removeListener(_onSettingsChanged);
      widget.settings.addListener(_onSettingsChanged);
    }
    if (old.theme != widget.theme) {
      old.theme.removeListener(_onSettingsChanged);
      widget.theme.addListener(_onSettingsChanged);
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _autoFollowRearmTimer?.cancel();
    widget.settings.removeListener(_onSettingsChanged);
    widget.theme.removeListener(_onSettingsChanged);
    _playback.removeListener(_onPlaybackChanged);
    widget.ttsEngine.stop();
    _playback.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {
      _pageCacheKey = null;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await widget.repository.read(widget.book.path);
      if (!mounted) return;
      final blocks = parseMarkdownBlocks(raw);
      setState(() {
        _blocks = blocks;
        _toc = buildToc(blocks);
        _loading = false;
        _pageCacheKey = null;
      });
      _playback.updateBlocks(blocks);
      _armFadeTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  ReaderTextStyles _stylesFor(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final scale = widget.settings.scale.multiplier;
    final family = widget.settings.family.fontFamily;

    TextStyle scaled(TextStyle? base, double fallbackSize, double fallbackHeight) {
      final merged = defaultStyle.merge(base);
      return merged.copyWith(
        fontSize: (merged.fontSize ?? fallbackSize) * scale,
        height: merged.height ?? fallbackHeight,
        fontFamily: family,
        inherit: false,
      );
    }

    return ReaderTextStyles(
      h1: scaled(textTheme.headlineMedium, 28, 1.2),
      h2: scaled(textTheme.titleLarge, 22, 1.2),
      h3: scaled(textTheme.titleMedium, 18, 1.2),
      paragraph: scaled(textTheme.bodyLarge, 16, 1.6),
    );
  }

  List<ReaderPage> _paginate(Size pageSize, ReaderTextStyles styles) {
    final key = '${pageSize.width.toStringAsFixed(1)}x'
        '${pageSize.height.toStringAsFixed(1)}|'
        '${widget.settings.scale.name}|'
        '${widget.settings.family.name}|'
        '${widget.theme.mode.name}|'
        '${_blocks.length}';
    if (key == _pageCacheKey) return _cachedPages;
    _cachedPages = paginateBlocks(
      blocks: _blocks,
      pageSize: pageSize,
      styles: styles,
    );
    _pageCacheKey = key;
    return _cachedPages;
  }

  void _ensureController(int spreadCount) {
    if (_controller == null) {
      final start = spreadCount == 0
          ? 0
          : widget.initialPage.clamp(0, spreadCount - 1);
      _currentSpread = start;
      _controller = PageController(initialPage: start);
    } else if (spreadCount > 0 && _currentSpread >= spreadCount) {
      _currentSpread = spreadCount - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller!.hasClients) {
          _controller!.jumpToPage(_currentSpread);
        }
      });
    }
  }

  void _onSpreadChanged(int spread) {
    _currentSpread = spread;
    widget.onPageChanged?.call(spread);
    _armFadeTimer();
  }

  void _onPlaybackChanged() {
    if (!_autoFollow) return;
    final pages = _playback.pages;
    if (pages.isEmpty) return;
    final idx = _playback.cursorBlockIndex;
    final spread = findSpreadForBlock(
      pages: pages,
      blockIndex: idx,
      pagesPerSpread: _pagesPerSpread,
    );
    if (spread != _currentSpread &&
        (_controller?.hasClients ?? false)) {
      _controller!.animateToPage(
        spread,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _suspendAutoFollow() {
    _autoFollow = false;
    _autoFollowRearmTimer?.cancel();
    _autoFollowRearmTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _autoFollow = true;
    });
  }

  void _previousPage() {
    _suspendAutoFollow();
    if (!(_controller?.hasClients ?? false)) return;
    final target = (_currentSpread - 1).clamp(0, 1 << 30);
    _controller!.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _nextPage() {
    _suspendAutoFollow();
    if (!(_controller?.hasClients ?? false)) return;
    _controller!.animateToPage(
      _currentSpread + 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _armFadeTimer() {
    _fadeTimer?.cancel();
    if (!_chromeVisible) return;
    _fadeTimer = Timer(_fadeDelay, () {
      if (!mounted) return;
      setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _armFadeTimer();
  }

  void _jumpToBlock(int blockIndex) {
    final spread = findSpreadForBlock(
      pages: _cachedPages,
      blockIndex: blockIndex,
      pagesPerSpread: _pagesPerSpread,
    );
    if (_controller?.hasClients ?? false) {
      _controller!.animateToPage(
        spread,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openSettings() async {
    _fadeTimer?.cancel();
    await showReaderSettingsSheet(
      context,
      settings: widget.settings,
      theme: widget.theme,
    );
    if (mounted) _armFadeTimer();
  }

  @override
  Widget build(BuildContext context) {
    final bar = AppBar(
      title: const Text(kAppTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to library',
        onPressed: widget.onBack,
      ),
      actions: _blocks.isEmpty || _error != null
          ? null
          : [
              if (_toc.isNotEmpty)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_book),
                    tooltip: 'Contents',
                    onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Reading settings',
                onPressed: _openSettings,
              ),
            ],
    );
    final barHeight = bar.preferredSize.height;
    final showChrome = _chromeVisible || _loading || _error != null;
    final showPlaybackBar = !_loading && _error == null && _blocks.isNotEmpty;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(barHeight),
        child: AnimatedOpacity(
          opacity: showChrome ? 1.0 : 0.0,
          duration: _fadeDuration,
          child: IgnorePointer(ignoring: !showChrome, child: bar),
        ),
      ),
      endDrawer: _toc.isEmpty ? null : _buildTocDrawer(context),
      body: SafeArea(top: false, child: _buildBody(context)),
      bottomNavigationBar: !showPlaybackBar
          ? null
          : AnimatedOpacity(
              opacity: showChrome ? 1.0 : 0.0,
              duration: _fadeDuration,
              child: IgnorePointer(
                ignoring: !showChrome,
                child: PlaybackBar(
                  controller: _playback,
                  onPreviousPage: _previousPage,
                  onNextPage: _nextPage,
                ),
              ),
            ),
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
      return Center(child: Text('Empty book', style: textTheme.bodyMedium));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _pagesPerSpread = constraints.maxWidth >= _spreadBreakpoint ? 2 : 1;
        final totalWidth = constraints.maxWidth;
        final pageWidth = _pagesPerSpread == 2
            ? (totalWidth - _spreadGutter) / 2
            : totalWidth;
        const safetyMargin = 24.0;
        final contentSize = Size(
          (pageWidth - _pagePadding.horizontal).clamp(1, double.infinity),
          (constraints.maxHeight - _pagePadding.vertical - safetyMargin)
              .clamp(1, double.infinity),
        );
        final styles = _stylesFor(context);
        final pages = _paginate(contentSize, styles);
        final spreadCount =
            (pages.length / _pagesPerSpread).ceil().clamp(1, 1 << 30);
        _ensureController(spreadCount);
        if (!identical(_playback.pages, pages)) {
          _playback.updatePages(pages);
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleChrome,
          child: AnimatedBuilder(
            animation: _playback,
            builder: (context, _) => PageView.builder(
              controller: _controller,
              itemCount: spreadCount,
              onPageChanged: _onSpreadChanged,
              itemBuilder: (context, spreadIndex) => _buildSpread(
                spreadIndex: spreadIndex,
                pages: pages,
                styles: styles,
                pageWidth: pageWidth,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpread({
    required int spreadIndex,
    required List<ReaderPage> pages,
    required ReaderTextStyles styles,
    required double pageWidth,
  }) {
    final firstPageIndex = spreadIndex * _pagesPerSpread;
    final children = <Widget>[];
    final highlightBlock = _playback.cursorBlockIndex;
    final highlightRange = _playback.currentWordRange;
    for (var i = 0; i < _pagesPerSpread; i++) {
      final pageIndex = firstPageIndex + i;
      final pageWidget = SizedBox(
        width: pageWidth,
        child: pageIndex < pages.length
            ? ReaderPageView(
                page: pages[pageIndex],
                styles: styles,
                padding: _pagePadding,
                highlightBlockIndex: highlightBlock,
                highlightRange: highlightRange,
              )
            : const SizedBox.shrink(),
      );
      children.add(pageWidget);
      if (_pagesPerSpread == 2 && i == 0) {
        children.add(const SizedBox(width: _spreadGutter));
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildTocDrawer(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text('Contents', style: textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _toc.length,
                itemBuilder: (context, i) {
                  final entry = _toc[i];
                  return ListTile(
                    contentPadding: EdgeInsets.only(
                      left: 24.0 + entry.depth * 16,
                      right: 16,
                    ),
                    title: Text(
                      entry.title,
                      style: entry.level == BlockKind.h1
                          ? textTheme.titleMedium
                          : textTheme.bodyLarge,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _jumpToBlock(entry.blockIndex);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
