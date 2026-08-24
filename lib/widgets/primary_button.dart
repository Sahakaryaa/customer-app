import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable primary CTA button with orange background, loading state,
/// and optional icon.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final bool isOutlined;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutlined ? AppColors.teal : Colors.white,
            ),
          ),
          const SizedBox(width: 6),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: 50,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
