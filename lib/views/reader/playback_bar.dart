import 'package:flutter/material.dart';

import '../../tts/playback_controller.dart';

class PlaybackBar extends StatelessWidget {
  const PlaybackBar({
    super.key,
    required this.controller,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final PlaybackController controller;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final elapsed = controller.elapsed;
        final total = controller.estimatedTotal;
        return Container(
          color: scheme.surface.withValues(alpha: 0.92),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(_fmt(elapsed), style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: controller.progress,
                      minHeight: 3,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_fmt(total), style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    tooltip: 'Previous page',
                    onPressed: onPreviousPage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    tooltip: 'Replay 10 seconds',
                    onPressed: () =>
                        controller.seek(const Duration(seconds: -10)),
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: Icon(
                      controller.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    tooltip: controller.isPlaying ? 'Pause' : 'Play',
                    onPressed: controller.togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    tooltip: 'Forward 10 seconds',
                    onPressed: () =>
                        controller.seek(const Duration(seconds: 10)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'Next page',
                    onPressed: onNextPage,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
