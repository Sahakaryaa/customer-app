import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../widgets/cooperative_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/glass_card.dart';
import '../../services/mock_data_service.dart';

/// Full worker profile screen — skills, rating, federation, book now.
/// Refined with Hero avatar transition, GlassCard stats, and micro-animations per 08-flutter-immersive-ui-skill.md.
class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;

  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerProfileProvider(workerId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: workerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (worker) {
          return CustomScrollView(
            slivers: [
              // Header with worker avatar and name
              SliverAppBar(
                expandedHeight: 270,
                pinned: true,
                backgroundColor: AppColors.teal,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.tealGradient,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 36),
                          // Hero Avatar for seamless spatial continuity
                          Hero(
                            tag: 'worker-avatar-${worker.id}',
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(worker.name),
                                  style: GoogleFonts.sora(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            worker.name,
                            style: GoogleFonts.sora(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (worker.isVerified) const CooperativeBadge(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Glassmorphism 2.0 Stats row overlay
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        _buildStat(
                          worker.ratingAvg.toStringAsFixed(1),
                          'Rating',
                          Icons.star_rounded,
                          AppColors.gold,
                        ),
                        _buildDivider(),
                        _buildStat(
                          '${worker.totalRatings}',
                          'Reviews',
                          Icons.reviews_rounded,
                          AppColors.teal,
                        ),
                        _buildDivider(),
                        _buildStat(
                          worker.distanceFormatted.isEmpty ? 'N/A' : worker.distanceFormatted,
                          'Away',
                          Icons.location_on_rounded,
                          AppColors.orange,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                ),
              ),

              // Federation info
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.federationName ?? 'Delhi Central Labour Federation',
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified Member • Fair Wage Guaranteed',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ),

              // Skills section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Services Offered',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
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
                          color: AppColors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          skill[0].toUpperCase() + skill.substring(1),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Reviews section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Reviews',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${worker.totalRatings} verified reviews',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  MockDataService.getMockReviews().map((review) {
                    return _buildReviewCard(
                      review['customer_name'] as String,
                      review['rating'] as int,
                      review['comment'] as String,
                      review['time'] as String,
                    );
                  }).toList(),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: PrimaryButton(
          label: 'Book Service with ${workerAsync.valueOrNull?.name ?? 'Worker'}',
          icon: Icons.calendar_today_rounded,
          onPressed: () {
            final worker = workerAsync.valueOrNull;
            if (worker != null) {
              final service = worker.skills.isNotEmpty ? worker.skills.first : 'electrician';
              context.push(
                '/book?service=$service&workerId=${worker.id}&workerName=${Uri.encodeComponent(worker.name)}',
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStat(
      String value, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.sora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }

  Widget _buildReviewCard(
      String name, int rating, String comment, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  )),
              Text(time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          RatingBarIndicator(
            rating: rating.toDouble(),
            itemSize: 14,
            itemBuilder: (_, __) =>
                const Icon(Icons.star_rounded, color: AppColors.gold),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkLight, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'W';
  }
}
