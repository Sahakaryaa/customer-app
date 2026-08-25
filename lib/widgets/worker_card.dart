import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/worker.dart';
import '../theme/app_colors.dart';

/// Worker list item card — Hero-ready avatar, skills, rating, distance,
/// verification + online status, press feedback and staggered entrance.
class WorkerCard extends StatefulWidget {
  final Worker worker;
  final int index;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    this.index = 0,
    this.onTap,
  });

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard> {
  bool _isPressed = false;

  String get _initials {
    final parts = widget.worker.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return widget.worker.name.isNotEmpty
        ? widget.worker.name[0].toUpperCase()
        : 'W';
  }

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
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828)
                    .withValues(alpha: _isPressed ? 0.10 : 0.05),
                blurRadius: _isPressed ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.worker.name,
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.worker.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: widget.worker.skills.take(2).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _capitalizeFirst(skill),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          widget.worker.ratingAvg.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          ' (${widget.worker.totalRatings} jobs)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.inkFaint),
                        const SizedBox(width: 2),
                        Text(
                          widget.worker.distanceFormatted.isEmpty
                              ? 'Nearby'
                              : widget.worker.distanceFormatted,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.inkSoft),
                        ),
                        const Spacer(),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.worker.isOnline
                                ? AppColors.success
                                : AppColors.inkFaint,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.worker.isOnline ? 'Online' : 'Offline',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: widget.worker.isOnline
                                ? AppColors.success
                                : AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.inkFaint, size: 22),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * widget.index.clamp(0, 12)))
        .fade(duration: 320.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildAvatar() {
    return Hero(
      tag: 'worker-avatar-${widget.worker.id}',
      child: Container(
        width: 54,
        height: 54,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.worker.isOnline
              ? AppColors.primaryGradient
              : LinearGradient(colors: [
                  AppColors.inkFaint.withValues(alpha: 0.4),
                  AppColors.inkFaint.withValues(alpha: 0.25)
                ]),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
          ),
          child: Center(
            child: Text(
              _initials,
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Shimmer skeleton loader for WorkerCard during loading state.
class WorkerCardSkeleton extends StatelessWidget {
  final int index;

  const WorkerCardSkeleton({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 140, height: 13, color: AppColors.surfaceAlt),
                const SizedBox(height: 9),
                Container(
                    width: 90, height: 11, color: AppColors.surfaceAlt),
                const SizedBox(height: 9),
                Container(
                    width: 180, height: 11, color: AppColors.surfaceAlt),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 60 * index)).fade(duration: 250.ms);
  }
}
