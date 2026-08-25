import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../theme/app_colors.dart';

/// Horizontal animated stepper across the live booking lifecycle:
/// Accepted → En Route → Arrived → Started → Completed
/// (pending shows before acceptance; declined/cancelled render a single pill).
class StatusStepper extends StatelessWidget {
  final BookingStatus currentStatus;

  const StatusStepper({super.key, required this.currentStatus});

  static const _steps = [
    _StepData(BookingStatus.accepted, Icons.handshake_rounded, 'Accepted'),
    _StepData(BookingStatus.enRoute, Icons.electric_moped_rounded, 'En Route'),
    _StepData(BookingStatus.arrived, Icons.location_on_rounded, 'Arrived'),
    _StepData(BookingStatus.started, Icons.handyman_rounded, 'Started'),
    _StepData(BookingStatus.completed, Icons.check_circle_rounded, 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isEven) {
            final step = _steps[index ~/ 2];
            return _buildStepCircle(step);
          }
          final nextStep = _steps[(index ~/ 2) + 1];
          return _buildConnector(nextStep.status);
        }),
      ),
    );
  }

  Widget _buildStepCircle(_StepData step) {
    final completed =
        currentStatus.stepIndex > step.status.stepIndex && !_isTerminalBad;
    final active = currentStatus == step.status;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: active ? 42 : 34,
            height: active ? 42 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: completed || active
                  ? AppColors.primaryGradient
                  : null,
              color: completed || active ? null : AppColors.surfaceAlt,
              border: Border.all(
                color: completed || active
                    ? Colors.transparent
                    : AppColors.border,
                width: 2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              completed || active ? step.icon : Icons.circle_outlined,
              size: active ? 19 : 15,
              color: completed || active
                  ? Colors.white
                  : AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: active || completed
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: active
                  ? AppColors.primary
                  : completed
                      ? AppColors.ink
                      : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BookingStatus next) {
    final lit = currentStatus.stepIndex >= next.stepIndex && !_isTerminalBad;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 3,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: lit ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  bool get _isTerminalBad =>
      currentStatus == BookingStatus.declined ||
      currentStatus == BookingStatus.cancelled;
}

class _StepData {
  final BookingStatus status;
  final IconData icon;
  final String label;

  const _StepData(this.status, this.icon, this.label);
}
