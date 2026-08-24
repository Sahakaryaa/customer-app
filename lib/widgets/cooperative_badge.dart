import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The signature "Cooperative Verified" badge — teal pill with gold checkmark.
/// Features an elastic scale-in entrance animation respecting reduced-motion settings.
class CooperativeBadge extends StatefulWidget {
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
  State<CooperativeBadge> createState() => _CooperativeBadgeState();
}

class _CooperativeBadgeState extends State<CooperativeBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isSmall = widget.effectiveCompact;
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
            color: AppColors.teal.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: isSmall ? 12 : 14,
            color: AppColors.gold,
          ),
          SizedBox(width: isSmall ? 3 : 5),
          Text(
            widget.federationName ?? (isSmall ? 'Verified' : 'Cooperative Verified'),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 9 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (disableAnimations || !widget.animate) {
      return badgeContent;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: badgeContent,
    );
  }
}
