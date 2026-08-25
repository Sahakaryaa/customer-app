import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../theme/app_colors.dart';

/// Animated color-morph status pill covering the full contract status enum:
/// pending | accepted | declined | en_route | arrived | started | completed | cancelled.
class StatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool dense;

  const StatusChip({super.key, required this.status, this.dense = false});

  static Color colorFor(BookingStatus status) {
    return switch (status) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.accepted => AppColors.info,
      BookingStatus.declined => AppColors.danger,
      BookingStatus.enRoute => AppColors.primary,
      BookingStatus.arrived => AppColors.primaryLight,
      BookingStatus.started => AppColors.success,
      BookingStatus.completed => AppColors.success,
      BookingStatus.cancelled => AppColors.inkFaint,
    };
  }

  static IconData iconFor(BookingStatus status) {
    return switch (status) {
      BookingStatus.pending => Icons.schedule_rounded,
      BookingStatus.accepted => Icons.handshake_rounded,
      BookingStatus.declined => Icons.cancel_rounded,
      BookingStatus.enRoute => Icons.electric_moped_rounded,
      BookingStatus.arrived => Icons.location_on_rounded,
      BookingStatus.started => Icons.handyman_rounded,
      BookingStatus.completed => Icons.check_circle_rounded,
      BookingStatus.cancelled => Icons.block_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(status), size: dense ? 12 : 14, color: color),
          SizedBox(width: dense ? 3 : 5),
          Text(
            status.label,
            style: GoogleFonts.inter(
              fontSize: dense ? 10 : 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
