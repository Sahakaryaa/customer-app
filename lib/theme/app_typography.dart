import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system using Sora (display/headings) and Inter (body/labels).
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      // Display — large hero text
      displayLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      ),

      // Headlines — section headings
      headlineLarge: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      ),

      // Title — screen titles, card titles
      titleLarge: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.4,
      ),

      // Body — main content
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.inkLight,
        height: 1.5,
      ),

      // Labels — buttons, chips, small UI elements
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.inkLight,
        height: 1.4,
      ),
    );
  }
}
