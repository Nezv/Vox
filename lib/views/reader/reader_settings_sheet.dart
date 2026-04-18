import 'package:flutter/material.dart';

import '../../core/reader_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';

Future<void> showReaderSettingsSheet(
  BuildContext context, {
  required ReaderSettings settings,
  required ThemeController theme,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _ReaderSettingsSheet(settings: settings, theme: theme),
  );
}

class _ReaderSettingsSheet extends StatefulWidget {
  const _ReaderSettingsSheet({required this.settings, required this.theme});

  final ReaderSettings settings;
  final ThemeController theme;

  @override
  State<_ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<_ReaderSettingsSheet> {
  late ReaderFontScale _scale = widget.settings.scale;
  late ReaderFontFamily _family = widget.settings.family;
  late AppThemeMode _themeMode = widget.theme.mode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reading', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Font size', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            SegmentedButton<ReaderFontScale>(
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
            const SizedBox(height: 16),
            Text('Font family', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            SegmentedButton<ReaderFontFamily>(
              segments: [
                for (final f in ReaderFontFamily.values)
                  ButtonSegment(value: f, label: Text(f.label)),
              ],
              selected: {_family},
              onSelectionChanged: (value) {
                final picked = value.first;
                setState(() => _family = picked);
                widget.settings.setFamily(picked);
              },
            ),
            const SizedBox(height: 16),
            Text('Theme', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            SegmentedButton<AppThemeMode>(
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
          ],
        ),
      ),
    );
  }
}
