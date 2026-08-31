import 'package:flutter/material.dart';

/// SahaKarya "Luxe" design tokens (customer app) — see docs/DESIGN_SPEC.md.
/// Primary = Indigo/Violet gradient; Amber accents for CTAs; zero Material blue.
class AppColors {
  AppColors._();

  // ── Core palette ──
  static const Color bg = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEDF2EE);

  static const Color ink = Color(0xFF101F19);
  static const Color inkSoft = Color(0xFF4E6158);
  static const Color inkFaint = Color(0xFF82968D);

  // Primary Sahakarya Forest Green → gradient [#093F2B, #137A54]
  static const Color primary = Color(0xFF0D5238);
  static const Color primaryDeep = Color(0xFF093F2B);
  static const Color primaryLight = Color(0xFF137A54);

  // Amber / Gold CTA accent [#F5A623, #F8B63B]
  static const Color amber = Color(0xFFF5A623);
  static const Color amberSoft = Color(0xFFF8B63B);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Dark hero surfaces (splash, tracking hero)
  static const Color darkStart = Color(0xFF091612);
  static const Color darkEnd = Color(0xFF0E1F1A);

  // Hairlines
  static const Color border = Color(0xFFDFE7E2);

  // ── Brand Aliases ──
  static const Color teal = primary;
  static const Color tealLight = primaryLight;
  static const Color orange = amber;
  static const Color gold = amber;
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
