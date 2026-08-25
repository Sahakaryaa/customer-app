import 'package:flutter/material.dart';

/// SahaKarya "Luxe" design tokens (customer app) — see docs/DESIGN_SPEC.md.
/// Primary = Indigo/Violet gradient; Amber accents for CTAs; zero Material blue.
class AppColors {
  AppColors._();

  // ── Core palette ──
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF0F7);

  static const Color ink = Color(0xFF101828);
  static const Color inkSoft = Color(0xFF667085);
  static const Color inkFaint = Color(0xFF98A2B3);

  // Primary indigo → gradient [#6A5AE0, #8E7CF0]
  static const Color primary = Color(0xFF5B5FE9);
  static const Color primaryDeep = Color(0xFF6A5AE0);
  static const Color primaryLight = Color(0xFF8E7CF0);

  // Amber CTA accent
  static const Color amber = Color(0xFFFFB020);
  static const Color amberSoft = Color(0xFFFFC85C);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Dark hero surfaces (splash, tracking hero)
  static const Color darkStart = Color(0xFF0B1220);
  static const Color darkEnd = Color(0xFF111A2C);

  // Hairlines
  static const Color border = Color(0xFFE7EAF3);

  // ── Legacy aliases (existing widgets keep compiling; brand now indigo/amber) ──
  static const Color teal = primary;
  static const Color tealLight = primaryLight;
  static const Color orange = amber;
  static const Color gold = warning;
  static const Color error = danger;
  static const Color inkLight = inkSoft;
  static const Color inkMuted = inkFaint;
  static const Color divider = surfaceAlt;

  // ── Gradients (135°) ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primaryLight],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkStart, darkEnd],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, amberSoft],
  );

  /// Mesh-gradient palette for service icon tiles.
  static const List<List<Color>> meshGradients = [
    [Color(0xFF6A5AE0), Color(0xFF9B8CFF)],
    [Color(0xFF0EA5E9), Color(0xFF67E8F9)],
    [Color(0xFFF59E0B), Color(0xFFFCD34D)],
    [Color(0xFFEC4899), Color(0xFFF9A8D4)],
    [Color(0xFF10B981), Color(0xFF6EE7B7)],
    [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
    [Color(0xFFEF4444), Color(0xFFFCA5A5)],
    [Color(0xFF14B8A6), Color(0xFF99F6E4)],
  ];

  /// Soft shadow token from the spec.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
