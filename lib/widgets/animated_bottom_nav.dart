import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Floating pill bottom navigation bar with animated indicator dot and
/// icon+label morph on select — per DESIGN_SPEC.
class AnimatedBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavItemView(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

class _NavItemView extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItemView({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.inkSoft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(item.icon, size: 21, color: color),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
