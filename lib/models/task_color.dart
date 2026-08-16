import 'package:flutter/material.dart';

/// Kanboard's built-in named task colors. `color_id` on the wire is one of
/// these string keys (e.g. "yellow"), not a numeric id — confirmed against
/// a live instance's getTask response.
///
/// Each entry stores a saturated base [hue] rather than a fixed pastel, so
/// card fills can be derived per-theme (see [fillColor]/[foregroundColor])
/// instead of baking in a light-mode-only tone that goes muddy in dark
/// theme.
class TaskColor {
  final String id;
  final String label;
  final Color hue;

  const TaskColor(this.id, this.label, this.hue);

  static const List<TaskColor> all = [
    TaskColor('yellow', 'Yellow', Color(0xFFE0B400)),
    TaskColor('blue', 'Blue', Color(0xFF2E86DE)),
    TaskColor('green', 'Green', Color(0xFF2FA84F)),
    TaskColor('purple', 'Purple', Color(0xFF9B59B6)),
    TaskColor('red', 'Red', Color(0xFFE0433D)),
    TaskColor('orange', 'Orange', Color(0xFFE08A2E)),
    TaskColor('grey', 'Grey', Color(0xFF8A97A0)),
    TaskColor('brown', 'Brown', Color(0xFF9C6B44)),
    TaskColor('deepOrange', 'Deep orange', Color(0xFFD9631E)),
    TaskColor('darkGrey', 'Dark grey', Color(0xFF66727A)),
    TaskColor('pink', 'Pink', Color(0xFFE0559A)),
    TaskColor('teal', 'Teal', Color(0xFF1F9C8C)),
    TaskColor('cyan', 'Cyan', Color(0xFF1DA7C7)),
    TaskColor('lime', 'Lime', Color(0xFF9CBF2E)),
    TaskColor('lightGreen', 'Light green', Color(0xFF6FBF4F)),
    TaskColor('amber', 'Amber', Color(0xFFD9A027)),
  ];

  static const defaultColor = 'yellow';

  static TaskColor byId(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => all.first);
  }

  /// Card background: the hue tinted onto the current theme's surface, so
  /// it reads as a soft fill in light mode and a richer, still-legible tone
  /// in dark mode rather than one fixed hex value for both.
  Color fillColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Color.alphaBlend(
      hue.withValues(alpha: isDark ? 0.32 : 0.22),
      theme.colorScheme.surfaceContainerHigh,
    );
  }

  /// Text/icon color guaranteed readable against [fillColor] in either
  /// theme.
  Color foregroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  /// Small saturated accent (e.g. the dot in a color picker) — always the
  /// raw hue, independent of theme.
  Color get accent => hue;
}
