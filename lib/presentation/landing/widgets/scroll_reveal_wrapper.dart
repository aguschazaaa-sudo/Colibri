import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ScrollRevealWrapper extends StatefulWidget {
  const ScrollRevealWrapper({
    super.key,
    required this.childBuilder,
    this.visibilityThreshold = 0.1,
  });

  final Widget Function(BuildContext context, bool isVisible) childBuilder;
  final double visibilityThreshold;

  @override
  State<ScrollRevealWrapper> createState() => _ScrollRevealWrapperState();
}

class _ScrollRevealWrapperState extends State<ScrollRevealWrapper> {
  bool _hasAppeared = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? ValueKey(widget.hashCode),
      onVisibilityChanged: (info) {
        if (!_hasAppeared &&
            info.visibleFraction >= widget.visibilityThreshold) {
          if (mounted) {
            setState(() {
              _hasAppeared = true;
            });
          }
        }
      },
      child: widget.childBuilder(context, _hasAppeared),
    );
  }
}
