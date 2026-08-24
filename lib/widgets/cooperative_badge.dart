import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// The signature "Cooperative Verified" badge — teal pill with gold checkmark.
/// Features an elastic scale-in entrance animation and subtle gold shimmer respecting reduced motion.
class CooperativeBadge extends StatelessWidget {
  final bool compact;
  final bool isCompact;
  final bool animate;
  final String? federationName;

  const CooperativeBadge({
    super.key,
    this.compact = false,
    this.isCompact = false,
    this.animate = true,
    this.federationName,
  });

  bool get effectiveCompact => compact || isCompact;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isSmall = effectiveCompact;

    final badgeContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: isSmall ? 12 : 15,
            color: AppColors.gold,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            federationName ?? (isSmall ? 'Verified' : 'Cooperative Verified'),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 9 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (disableAnimations || !animate) {
      return badgeContent;
    }

    return badgeContent
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
          duration: 600.ms,
        )
        .then(delay: 200.ms)
        .shimmer(
          duration: 1200.ms,
          color: AppColors.gold.withValues(alpha: 0.4),
        );
  }
}
