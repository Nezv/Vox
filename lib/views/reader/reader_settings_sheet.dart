import 'package:flutter/material.dart';

import '../../core/reader_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../tts/playback_controller.dart';
import '../../tts/tts_engine.dart';

Future<void> showReaderSettingsSheet(
  BuildContext context, {
  required ReaderSettings settings,
  required ThemeController theme,
  required TtsEngine engine,
  required PlaybackController controller,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss reader settings',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, _, __) {
      final size = MediaQuery.sizeOf(dialogContext);
      final panelWidth = _panelWidthFor(size.width);
      return SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 18,
              top: 14,
              bottom: 14,
              child: SizedBox(
                width: panelWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4A000000),
                        blurRadius: 26,
                        spreadRadius: 1,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Material(
                      type: MaterialType.transparency,
                      child: _ReaderSettingsSheet(
                        settings: settings,
                        theme: theme,
                        engine: engine,
                        controller: controller,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            alignment: Alignment.centerRight,
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

double _panelWidthFor(double screenWidth) {
  if (screenWidth >= 1700) return 520;
  if (screenWidth >= 1400) return 470;
  if (screenWidth >= 1100) return 430;
  if (screenWidth >= 900) return 390;
  return (screenWidth * 0.96).clamp(320.0, 420.0);
}

class _ReaderSettingsSheet extends StatefulWidget {
  const _ReaderSettingsSheet({
    required this.settings,
    required this.theme,
    required this.engine,
    required this.controller,
  });

  final ReaderSettings settings;
  final ThemeController theme;
  final TtsEngine engine;
  final PlaybackController controller;

  @override
  State<_ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<_ReaderSettingsSheet> {
  late ReaderFontScale _scale = widget.settings.scale;
  late ReaderFontFamily _family = widget.settings.family;
  late AppThemeMode _themeMode = widget.theme.mode;
  late double _speechRate = widget.settings.speechRate;

  List<String> _languages = const [];
  List<Map<String, String>> _voices = const [];
  String? _selectedLanguage;
  Map<String, String>? _selectedVoice;
  bool _voicesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    final languages = await widget.engine.getLanguages();
    final voices = await widget.engine.getVoices();
    if (!mounted) return;
    setState(() {
      _languages = languages;
      _voices = voices;
      _voicesLoaded = true;
    });
  }

  List<Map<String, String>> get _filteredVoices {
    if (_selectedLanguage == null) return _voices;
    return _voices
        .where((v) =>
            (v['locale'] ?? v['language'] ?? '').startsWith(_selectedLanguage!))
        .toList();
  }

  int _wpm(double rate) => (rate * 5.0 * 60).round();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
          child: Row(
            children: [
              Expanded(child: Text('Reader Settings', style: textTheme.titleLarge)),
              IconButton(
                tooltip: 'Close settings',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Font size', style: textTheme.bodyMedium),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<ReaderFontScale>(
                    segments: [
                      for (final s in ReaderFontScale.values)
                        ButtonSegment(value: s, label: Text(s.label)),
                    ],
                    selected: {_scale},
                    onSelectionChanged: (value) {
                      final picked = value.first;
                      setState(() => _scale = picked);
                      widget.settings.setScale(picked);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('Font family', style: textTheme.bodyMedium),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ReaderFontFamily.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.1,
                  ),
                  itemBuilder: (context, i) {
                    final family = ReaderFontFamily.values[i];
                    final selected = family == _family;
                    final scheme = Theme.of(context).colorScheme;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _family = family);
                        widget.settings.setFamily(family);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? scheme.secondaryContainer
                              : scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? scheme.secondary
                                : scheme.outlineVariant,
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Text(
                          family.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textTheme.labelMedium?.copyWith(
                            color: selected
                                ? scheme.onSecondaryContainer
                                : scheme.onSurface,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reading speed', style: textTheme.bodyMedium),
                    Text('${_wpm(_speechRate)} WPM', style: textTheme.bodySmall),
                  ],
                ),
                Slider(
                  min: 0.25,
                  max: 1.0,
                  divisions: 6,
                  value: _speechRate,
                  onChanged: (v) {
                    setState(() => _speechRate = v);
                    widget.settings.setSpeechRate(v);
                    widget.engine.setRate(v);
                    widget.controller.reseedWps(v * 5.0);
                  },
                ),
                const SizedBox(height: 16),
                Text('Theme', style: textTheme.bodyMedium),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: AppThemeMode.sepia, label: Text('Sepia')),
                      ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (value) {
                      final picked = value.first;
                      setState(() => _themeMode = picked);
                      widget.theme.setMode(picked);
                    },
                  ),
                ),
                if (_voicesLoaded && _languages.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Voice', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text('Language', style: textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedLanguage,
                    hint: const Text('System default'),
                    items: [
                      for (final lang in _languages)
                        DropdownMenuItem(value: lang, child: Text(lang)),
                    ],
                    onChanged: (lang) {
                      setState(() {
                        _selectedLanguage = lang;
                        _selectedVoice = null;
                      });
                      if (lang != null) widget.engine.setLanguage(lang);
                    },
                  ),
                  if (_filteredVoices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Voice', style: textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButton<Map<String, String>>(
                      isExpanded: true,
                      value: _selectedVoice,
                      hint: const Text('System default'),
                      items: [
                        for (final voice in _filteredVoices)
                          DropdownMenuItem(
                            value: voice,
                            child: Text(voice['name'] ?? voice.toString()),
                          ),
                      ],
                      onChanged: (voice) {
                        setState(() => _selectedVoice = voice);
                        if (voice != null) widget.engine.setVoice(voice);
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
