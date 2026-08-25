import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Animated number count-up for money/ratings — Sora w800, tight spacing,
/// per DESIGN_SPEC numeric emphasis rules.
class CountUpText extends StatelessWidget {
  final double value;
  final String prefix;
  final String? suffix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const CountUpText(
    this.value, {
    super.key,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, anim, _) {
        final text = anim.toStringAsFixed(decimals);
        return Text(
          '$prefix$text$suffix',
          style: style ??
              GoogleFonts.sora(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
        );
      },
    );
  }
}
