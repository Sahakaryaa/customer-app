import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import 'package:google_fonts/google_fonts.dart';

/// Service category grid tile — icon + label for the home screen grid.
/// Features a tactile scale spring animation on tap.
class ServiceCategoryTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const ServiceCategoryTile({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  /// Maps service type IDs to official Material icons.
  static IconData getIconForService(String serviceId) {
    return switch (serviceId) {
      'electrician' => Icons.bolt_rounded,
      'plumber' => Icons.plumbing_rounded,
      'carpenter' => Icons.carpenter_rounded,
      'painter' => Icons.format_paint_rounded,
      'cleaner' => Icons.cleaning_services_rounded,
      'caregiver' => Icons.health_and_safety_rounded,
      'driver' => Icons.directions_car_rounded,
      'gardener' => Icons.yard_rounded,
      _ => Icons.handyman_rounded,
    };
  }

  @override
  State<ServiceCategoryTile> createState() => _ServiceCategoryTileState();
}

class _ServiceCategoryTileState extends State<ServiceCategoryTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.teal : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected ? AppColors.teal : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxH = constraints.maxHeight;
              final iconBoxSize = (boxH * 0.46).clamp(24.0, 38.0);
              final iconSize = (iconBoxSize * 0.58).clamp(15.0, 22.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(iconBoxSize * 0.3),
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: iconSize,
                        color: widget.isSelected ? Colors.white : AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: (boxH * 0.13).clamp(10.0, 11.5),
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected ? Colors.white : AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
