import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/worker.dart';
import '../theme/app_colors.dart';
import 'cooperative_badge.dart';
import 'package:shimmer/shimmer.dart';

/// Worker list item card — shows photo, name, skills, rating, distance,
/// and the Cooperative Badge for verified workers with smooth press feedback and Hero transitions.
class WorkerCard extends StatefulWidget {
  final Worker worker;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    this.onTap,
  });

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed ? AppColors.teal : AppColors.border,
              width: _isPressed ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.04),
                blurRadius: _isPressed ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Hero Worker avatar
              _buildAvatar(),
              const SizedBox(width: 14),

              // Worker details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & verification badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.worker.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.worker.isVerified) ...[
                          const SizedBox(width: 6),
                          const CooperativeBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Primary skill chip
                    Wrap(
                      spacing: 4,
                      children: widget.worker.skills.take(2).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _capitalizeFirst(skill),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Rating, jobs count & distance
                    Row(
                      children: [
                        // Star rating
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.worker.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          ' (${widget.worker.totalRatings})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkLight,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Distance indicator
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.inkLight,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.worker.distanceFormatted.isEmpty
                              ? 'Nearby'
                              : widget.worker.distanceFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkLight,
                          ),
                        ),

                        const Spacer(),

                        // Availability dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.worker.isOnline
                                ? AppColors.success
                                : AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.worker.isOnline ? 'Available' : 'Busy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: widget.worker.isOnline
                                ? AppColors.success
                                : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAvatar() {
    return Hero(
      tag: 'worker-avatar-${widget.worker.id}',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.worker.isVerified
                ? AppColors.teal.withValues(alpha: 0.35)
                : AppColors.border,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getInitials(widget.worker.name),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.teal,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'W';
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Shimmer skeleton loader for WorkerCard during loading state.
class WorkerCardSkeleton extends StatelessWidget {
  const WorkerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
