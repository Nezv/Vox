import 'package:flutter/material.dart';

import '../../tts/playback_controller.dart';

class PlaybackBar extends StatelessWidget {
  const PlaybackBar({
    super.key,
    required this.controller,
    required this.onPreviousPage,
    required this.onNextPage,
    this.isTrackingPageView = true,
    this.onEnableTrackMode = _noop,
  });

  final PlaybackController controller;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final bool isTrackingPageView;
  final VoidCallback onEnableTrackMode;

  static void _noop() {}

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
                  IconButton(
                    tooltip: isTrackingPageView
                        ? 'Page tracking active'
                        : 'Return to track mode',
                    onPressed: isTrackingPageView ? null : onEnableTrackMode,
                    icon: _TrackModeIcon(active: isTrackingPageView),
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

class _TrackModeIcon extends StatelessWidget {
  const _TrackModeIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurface;
    return CustomPaint(
      size: const Size(22, 22),
      painter: _TrackModeIconPainter(color: color),
    );
  }
}

class _TrackModeIconPainter extends CustomPainter {
  const _TrackModeIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const x0 = 2.5;
    final x1 = size.width - 2.5;
    final yTop = size.height * 0.26;
    final yMid = size.height * 0.5;
    final yBot = size.height * 0.74;

    canvas.drawLine(Offset(x0, yTop), Offset(x1, yTop), linePaint);
    canvas.drawLine(Offset(x0, yMid), Offset(x1, yMid), linePaint);
    canvas.drawLine(Offset(x0, yBot), Offset(x1, yBot), linePaint);

    final triangle = Path()
      ..moveTo(size.width * 0.44, size.height * 0.37)
      ..lineTo(size.width * 0.61, size.height * 0.5)
      ..lineTo(size.width * 0.44, size.height * 0.63)
      ..close();
    final trianglePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(triangle, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant _TrackModeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
