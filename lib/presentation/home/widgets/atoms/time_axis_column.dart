import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Atom: fixed-width left column that renders hour labels and horizontal
/// divider lines for the day timeline.
///
/// Designed to sit inside a [Stack] alongside the appointments layer.
/// The [width] is fixed at [TimeAxisColumn.columnWidth] so the parent can
/// reserve that space for the appointments area.
class TimeAxisColumn extends StatelessWidget {
  const TimeAxisColumn({
    super.key,
    required this.rangeStartHour,
    required this.rangeEndHour,
    required this.pixelsPerMinute,
  });

  /// Hour (0–23) where the timeline starts.
  final int rangeStartHour;

  /// Hour (0–23) where the timeline ends (exclusive).
  final int rangeEndHour;

  /// Pixels per minute — determines vertical positioning of labels.
  final double pixelsPerMinute;

  /// Fixed width reserved for the time axis.
  static const double columnWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hourCount = rangeEndHour - rangeStartHour;

    return SizedBox(
      width: columnWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i <= hourCount; i++)
            _HourLabel(
              hour: rangeStartHour + i,
              top: i * 60 * pixelsPerMinute,
              textStyle: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Atom: single hour label ───────────────────────────────────────────────────

class _HourLabel extends StatelessWidget {
  const _HourLabel({
    required this.hour,
    required this.top,
    required this.textStyle,
  });

  final int hour;
  final double top;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final label = '${hour.toString().padLeft(2, '0')}:00';
    return Positioned(
      top: top - AppSpacing.sm,
      left: 0,
      right: 0,
      child: Text(
        label,
        style: textStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}

/// Renders the full-width horizontal divider lines for each hour.
///
/// Separate from [TimeAxisColumn] so it can span the entire timeline width
/// (behind the appointment cards) using a [CustomPaint].
class TimeAxisLines extends CustomPainter {
  TimeAxisLines({
    required this.rangeStartHour,
    required this.rangeEndHour,
    required this.pixelsPerMinute,
    required this.lineColor,
  });

  final int rangeStartHour;
  final int rangeEndHour;
  final double pixelsPerMinute;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    final hourCount = rangeEndHour - rangeStartHour;
    for (int i = 0; i <= hourCount; i++) {
      final y = i * 60 * pixelsPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(TimeAxisLines oldDelegate) =>
      oldDelegate.rangeStartHour != rangeStartHour ||
      oldDelegate.rangeEndHour != rangeEndHour ||
      oldDelegate.pixelsPerMinute != pixelsPerMinute ||
      oldDelegate.lineColor != lineColor;
}
