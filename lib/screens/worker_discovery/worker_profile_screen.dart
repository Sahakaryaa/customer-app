import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/count_up_text.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_box.dart';

/// Worker profile — parallax gradient header w/ Hero'd avatar, stats row
/// (rating CountUp / jobs / distance), certification chip and sticky CTA.
class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;

  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerProfileProvider(workerId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: workerAsync.when(
        loading: () => _buildLoading(),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          subtitle: 'Could not load this worker profile. Please try again.',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        ),
        data: (workerOrNull) {
          final worker = workerOrNull;
          if (worker == null) {
            return EmptyState(
              icon: Icons.person_off_rounded,
              title: 'Worker not found',
              subtitle:
                  'This partner may be offline or no longer part of the federation.',
              actionLabel: 'Back to discovery',
              onAction: () => context.go('/workers'),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── Parallax gradient header ──
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.darkStart,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.darkStart,
                          AppColors.darkEnd,
                          AppColors.primaryDeep.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Hero(
                            tag: 'worker-avatar-${worker.id}',
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.darkStart,
                                ),
                                child: AvatarBadge(
                                    name: worker.name,
                                    size: 84,
                                    online: worker.isOnline),
                              ),
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutCubic,
                                duration: 350.ms,
                              )
                              .fadeIn(duration: 250.ms),
                          const SizedBox(height: 14),
                          Text(
                            worker.name,
                            style: GoogleFonts.sora(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ).animate(delay: 120.ms).fade(duration: 300.ms),
                          const SizedBox(height: 8),
                          _CertificationChip(
                              status: worker.certificationStatus),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Stats row ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GlassCard(
                    opacity: 0.95,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        _statRating(worker.ratingAvg),
                        _divider(),
                        _statCount(worker.totalRatings, 'Jobs Done',
                            Icons.handyman_rounded, AppColors.info),
                        _divider(),
                        _statText(
                          worker.distanceFormatted.isEmpty
                              ? 'Nearby'
                              : worker.distanceFormatted,
                          'Away',
                          Icons.location_on_rounded,
                          AppColors.success,
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fade(duration: 380.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                ),
              ),

              // ── Federation info ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.federationName ??
                                  'East Godavari Labour Cooperative Federation',
                              style: GoogleFonts.sora(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified member • Fair wage guaranteed',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 160.ms).fade(duration: 380.ms),
              ),

              // ── Skills ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    'Services Offered',
                    style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: worker.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primaryLight.withValues(alpha: 0.12),
                          ]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.20)),
                        ),
                        child: Text(
                          skill[0].toUpperCase() + skill.substring(1),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate(delay: 200.ms).fade(duration: 380.ms),
              ),

              // ── Reviews ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Reviews',
                        style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                      Text(
                        '${worker.totalRatings} verified jobs',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _reviewCard('Amit Verma', 5,
                      'Prompt arrival and diagnosed the issue immediately. Transparent cooperative pricing.',
                      '2 days ago'),
                  _reviewCard('Pooja Sharma', 5,
                      'Very polite and thorough. Great to see the welfare contribution built in.',
                      '1 week ago'),
                  const SizedBox(height: 110),
                ]),
              ),
            ],
          );
        },
      ),

      // ── Sticky bottom CTA ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            label: 'Book Now',
            isAmber: true,
            icon: Icons.calendar_today_rounded,
            onPressed: () {
              final worker = workerAsync.valueOrNull;
              if (worker == null) return;
              final service =
                  worker.skills.isNotEmpty ? worker.skills.first : 'electrician';
              context.push(
                '/booking/new?service=$service&workerId=${worker.id}&workerName=${Uri.encodeComponent(worker.name)}',
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    // Skeleton mirrors the profile layout (shimmer, never a bare spinner).
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 180, borderRadius: 24),
          SizedBox(height: 16),
          SkeletonBox(height: 64, borderRadius: 20),
          SizedBox(height: 12),
          SkeletonBox(height: 120, borderRadius: 20),
        ],
      ),
    );
  }

  Widget _statRating(double rating) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded,
                  size: 17, color: AppColors.warning),
              const SizedBox(width: 4),
              CountUpText(
                rating,
                decimals: 1,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Rating',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _statCount(int value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              CountUpText(
                value.toDouble(),
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _statText(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: AppColors.border);

  Widget _reviewCard(String name, int rating, String comment, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: GoogleFonts.sora(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              Text(time,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.inkFaint)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(comment,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.inkSoft, height: 1.45)),
        ],
      ),
    );
  }
}

/// Certification status chip — verified (indigo), pending (amber), rejected (red).
class _CertificationChip extends StatelessWidget {
  final String status;

  const _CertificationChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (status) {
      'verified' => (
          AppColors.success,
          Icons.verified_rounded,
          'Federation Verified'
        ),
      'rejected' => (
          AppColors.danger,
          Icons.gpp_bad_rounded,
          'Not Certified'
        ),
      _ => (
          AppColors.warning,
          Icons.hourglass_top_rounded,
          'Certification Pending'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ).animate(delay: 180.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 400.ms,
        );
  }
}
