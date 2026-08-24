import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_colors.dart';

/// Visual stepper showing booking status progression with smooth 300ms animated transitions.
/// Requested → Matched → In Progress → Completed
class StatusStepper extends StatelessWidget {
  final BookingStatus currentStatus;

  const StatusStepper({super.key, required this.currentStatus});

  static const _steps = [
    _StepData(BookingStatus.requested, Icons.schedule_rounded, 'Requested'),
    _StepData(BookingStatus.matched, Icons.person_search_rounded, 'Matched'),
    _StepData(BookingStatus.inProgress, Icons.handyman_rounded, 'In Progress'),
    _StepData(BookingStatus.completed, Icons.check_circle_rounded, 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Steps row
          Row(
            children: List.generate(_steps.length * 2 - 1, (index) {
              if (index.isEven) {
                final step = _steps[index ~/ 2];
                return _buildStepCircle(step);
              } else {
                final nextStep = _steps[(index ~/ 2) + 1];
                return _buildConnector(nextStep.status);
              }
            }),
          ),
          const SizedBox(height: 12),

          // Labels row
          Row(
            children: _steps.map((step) {
              final isComp = _isCompleted(step.status);
              final isAct = _isActive(step.status);
              return Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isComp || isAct ? FontWeight.w600 : FontWeight.w400,
                    color: isComp
                        ? AppColors.teal
                        : isAct
                            ? AppColors.orange
                            : AppColors.inkMuted,
                  ),
                  child: Text(
                    step.label,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(_StepData step) {
    final completed = _isCompleted(step.status);
    final active = _isActive(step.status);

    return Expanded(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: active ? 46 : 38,
          height: active ? 46 : 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? AppColors.teal
                : active
                    ? AppColors.orange
                    : AppColors.bg,
            border: Border.all(
              color: completed
                  ? AppColors.teal
                  : active
                      ? AppColors.orange
                      : AppColors.border,
              width: 2.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : completed
                    ? [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              completed ? Icons.check_rounded : step.icon,
              key: ValueKey('${step.status.name}_${completed}_$active'),
              size: active ? 22 : 18,
              color: (completed || active) ? Colors.white : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(BookingStatus next) {
    final isCompleted = _isCompleted(next) || _isActive(next);

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 3.5,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.teal : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  bool _isCompleted(BookingStatus status) {
    return status.stepIndex < currentStatus.stepIndex;
  }

  bool _isActive(BookingStatus status) {
    return status.stepIndex == currentStatus.stepIndex;
  }
}

class _StepData {
  final BookingStatus status;
  final IconData icon;
  final String label;

  const _StepData(this.status, this.icon, this.label);
}
