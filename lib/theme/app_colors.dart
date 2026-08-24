import 'package:flutter/material.dart';

/// Design tokens from the shared cooperative platform palette.
/// Teal = institutional trust, Orange = action/CTA, Gold = achievements/ratings.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color teal = Color(0xFF1B4B43);
  static const Color tealLight = Color(0xFF2A6B5F);
  static const Color tealDark = Color(0xFF0F3028);

  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFF8A5C);
  static const Color orangeDark = Color(0xFFE55A25);

  static const Color gold = Color(0xFFFFC145);
  static const Color goldLight = Color(0xFFFFD476);
  static const Color goldDark = Color(0xFFE5A830);

  // Neutrals
  static const Color bg = Color(0xFFF7F3E9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkLight = Color(0xFF6B6B6B);
  static const Color inkMuted = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE8E4DA);
  static const Color divider = Color(0xFFF0ECE2);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Gradients
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, tealLight],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, orangeLight],
  );
}
