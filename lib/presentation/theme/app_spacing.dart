import 'package:flutter/material.dart';

/// Design-system spacing constants based on an 8px scale.
///
/// For fixed spacing, use the static constants directly:
/// ```dart
/// SizedBox(height: AppSpacing.md)
/// EdgeInsets.all(AppSpacing.sm)
/// ```
///
/// For responsive section padding (landing pages, full-width layouts),
/// use [AppSpacing.sectionPadding] which scales with viewport width:
/// ```dart
/// Padding(
///   padding: AppSpacing.sectionPadding(context),
///   child: content,
/// )
/// ```
class AppSpacing {
  AppSpacing._();

  // ── Fixed scale ─────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
  static const double huge = 80;
  static const double massive = 120;

  // ── Common EdgeInsets ───────────────────────────────────────────────────
  static const EdgeInsets edgeInsetsH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets edgeInsetsV = EdgeInsets.symmetric(vertical: md);

  // ── Breakpoints ─────────────────────────────────────────────────────────
  static const double breakpointSm = 600;
  static const double breakpointMd = 900;
  static const double breakpointLg = 1200;
  static const double breakpointXl = 1600;

  // ── Responsive section padding ──────────────────────────────────────────

  /// Returns horizontal+vertical padding that scales with viewport width.
  ///
  /// - Mobile  (< 600):  horizontal 24, vertical 48
  /// - Tablet  (< 900):  horizontal 48, vertical 64
  /// - Desktop (< 1200): horizontal 80, vertical 80
  /// - Wide    (< 1600): horizontal 120, vertical 80
  /// - Ultra   (≥ 1600): horizontal 200, vertical 80
  ///
  /// The content is also constrained to [maxContentWidth] via the
  /// helper [centeredSliver] if needed.
  static EdgeInsets sectionPadding(
    BuildContext context, {
    double? verticalOverride,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final h = _horizontalForWidth(width);
    final v = verticalOverride ?? _verticalForWidth(width);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  /// Horizontal padding only (useful for navbars, footers).
  static EdgeInsets horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return EdgeInsets.symmetric(horizontal: _horizontalForWidth(width));
  }

  /// Maximum content width for ultra-wide screens.
  static const double maxContentWidth = 1200;

  /// Wraps [child] in a centered, max-width-constrained box.
  /// Use inside sections that span full width.
  static Widget constrained({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  static double _horizontalForWidth(double width) {
    if (width < breakpointSm) return lg; // 24
    if (width < breakpointMd) return xxl; // 48
    if (width < breakpointLg) return huge; // 80
    if (width < breakpointXl) return massive; // 120
    return 200; // ultra-wide
  }

  static double _verticalForWidth(double width) {
    if (width < breakpointSm) return xxl; // 48
    if (width < breakpointMd) return xxxl; // 64
    return huge; // 80
  }
}
