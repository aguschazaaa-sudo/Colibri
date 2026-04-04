import 'dart:async';

import 'package:flutter/material.dart';

/// Atom: a thin horizontal line that marks the current time on the day timeline.
///
/// Automatically updates every minute via [Timer.periodic]. The parent is
/// responsible for only rendering this widget when [selectedDate] is today.
///
/// Positioning is absolute — wrap in a [Positioned] inside a [Stack] and
/// set `left`/`right` to cover the full appointment area width.
class CurrentTimeIndicator extends StatefulWidget {
  const CurrentTimeIndicator({
    super.key,
    required this.rangeStartMinutes,
    required this.pixelsPerMinute,
  });

  /// Minutes from midnight to the start of the visible range
  /// (e.g. rangeStartHour * 60).
  final int rangeStartMinutes;

  /// Pixels per minute — same value used by the parent timeline.
  final double pixelsPerMinute;

  @override
  State<CurrentTimeIndicator> createState() => _CurrentTimeIndicatorState();
}

class _CurrentTimeIndicatorState extends State<CurrentTimeIndicator> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final nowMinutesFromMidnight = _now.hour * 60 + _now.minute;
    final top =
        (nowMinutesFromMidnight - widget.rangeStartMinutes) *
        widget.pixelsPerMinute;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: _TimeIndicatorLine(color: colorScheme.tertiary),
    );
  }
}

// ── Atom: the visual line + dot ───────────────────────────────────────────────

class _TimeIndicatorLine extends StatelessWidget {
  const _TimeIndicatorLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: color,
          ),
        ),
      ],
    );
  }
}
