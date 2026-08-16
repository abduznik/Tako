import 'package:flutter/material.dart';

/// Assigns each board column a color along a neutral→blue→amber→green
/// progression based on its position, so the board communicates "how far
/// along" a column is at a glance — regardless of how many columns exist
/// or what they're named (works for the default 4-column Kanboard layout
/// and for custom boards alike).
class ColumnTheme {
  /// Anchor hues sampled across the progression; intermediate column counts
  /// interpolate between the nearest two.
  static const List<Color> _progression = [
    Color(0xFF9AA5B1), // neutral grey — backlog / not started
    Color(0xFF4C8DFF), // blue — ready / queued
    Color(0xFFF5A623), // amber — in progress
    Color(0xFF34C759), // green — done
  ];

  /// Returns a header color for [index] of [total] columns, interpolated
  /// along the progression so it degrades gracefully for any column count.
  static Color headerColor(int index, int total) {
    if (total <= 1) return _progression.first;
    final t = index / (total - 1);
    final scaled = t * (_progression.length - 1);
    final lower = scaled.floor().clamp(0, _progression.length - 1);
    final upper = scaled.ceil().clamp(0, _progression.length - 1);
    final localT = scaled - lower;
    return Color.lerp(_progression[lower], _progression[upper], localT)!;
  }

  /// Header background: the progression color, softened for the current
  /// theme brightness so text stays readable without hardcoding per-mode
  /// hex values.
  static Color headerBackground(BuildContext context, int index, int total) {
    final base = headerColor(index, total);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Color.alphaBlend(
      base.withValues(alpha: isDark ? 0.28 : 0.18),
      Theme.of(context).colorScheme.surfaceContainerLow,
    );
  }

  static Color headerForeground(BuildContext context, int index, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  static Color accentColor(BuildContext context, int index, int total) {
    return headerColor(index, total);
  }
}
