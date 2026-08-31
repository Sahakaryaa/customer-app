import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/support_assistant.dart';
import '../../widgets/app_tiles.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/skeleton_box.dart';

/// Home — Luxe redesign: greeting header with AvatarBadge, floating search
/// pill, category chips, top-rated carousel, nearby mini-map card and
/// recent bookings with StatusChips (tap → tracking).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fix: listener drives the clear (X) button visibility reactively.
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(locationServiceProvider)
          .resolveAndApply(ref, context: context); // GPS chain per spec
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final trimmed = query.trim();
    ref.read(selectedServiceProvider.notifier).state = null;
    ref.read(emergencyModeProvider.notifier).state = false;
    ref.read(workerSearchQueryProvider.notifier).state =
        trimmed.isEmpty ? null : trimmed;
    context.push(
      trimmed.isEmpty ? '/workers' : '/workers?search=${Uri.encodeComponent(trimmed)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Customer';
    final activeLocation = ref.watch(userLocationStateProvider);
    final isApproximate = ref.watch(locationIsApproximateProvider);
    final workersAsync = ref.watch(nearbyWorkersProvider(activeLocation.coordinates));
    final historyAsync = ref.watch(bookingHistoryProvider);

    // Compute recent list ONCE per build (fix for double mock-history call).
    final List<Booking> recentBookings =
        (historyAsync.valueOrNull ?? const []).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      // SahaKarya Assist — floating support assistant entry point.
      floatingActionButton: SupportAssistantFAB(userName: userName),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(nearbyWorkersProvider(activeLocation.coordinates));
          ref.invalidate(bookingHistoryProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Greeting header ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.darkGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => LocationService.showLocationPickerModal(
                                        context, ref),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.22),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_rounded,
                                              color: AppColors.amber, size: 15),
                                          const SizedBox(width: 6),
                                          ConstrainedBox(
                                            constraints:
                                                const BoxConstraints(
                                                    maxWidth: 220),
                                            child: Text(
                                              activeLocation.areaName,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white60,
                                              size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Hello, $userName',
                                    style: GoogleFonts.sora(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cooperative services. Fair dignity.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: .75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: AvatarBadge(name: userName, size: 48),
                            ).animate().scale(
                                  begin: const Offset(0.6, 0.6),
                                  end: const Offset(1, 1),
                                  curve: Curves.easeOutCubic,
                                  duration: 300.ms,
                                ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Floating rounded search pill ──
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          borderRadius: 24,
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: _onSearch,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: AppColors.ink),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    hintText:
                                        'Search electrician, plumber, cleaner…',
                                    hintStyle: GoogleFonts.inter(
                                        fontSize: 13.5, color: AppColors.inkFaint),
                                  ),
                                ),
                              ),
                              // Clear (X) now driven by the text controller listener.
                              if (_searchController.text.isNotEmpty) ...[
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _searchController.clear();
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: AppColors.inkFaint),
                                ),
                                const SizedBox(width: 8),
                              ],
                              GestureDetector(
                                onTap: () => _onSearch(_searchController.text),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fade(duration: 350.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Non-blocking approximate-location banner ──
            if (isApproximate)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 17, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Using approximate location — tap to refine',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => LocationService.showLocationPickerModal(
                              context, ref),
                          child: Text(
                            'Update',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fade(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0),
              ),

            // ── Emergency fast-track ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(selectedServiceProvider.notifier).state = null;
                    ref.read(workerSearchQueryProvider.notifier).state = null;
                    ref.read(emergencyModeProvider.notifier).state = true;
                    context.push('/workers?emergency=true');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.flash_on_rounded,
                              color: AppColors.amber, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Fast-Track Dispatch',
                                style: GoogleFonts.sora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Nearest verified partner prioritised first',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(delay: 80.ms)
                  .fade(duration: 380.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            ),

            // ── Category chips (horizontal scroll w/ icons) ──
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Services', subtitle: '8 trades available'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: MockDataService.serviceCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = MockDataService.serviceCategories[index];
                    final mesh =
                        AppColors.meshGradients[index % AppColors.meshGradients.length];
                    return SizedBox(
                      width: 86,
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        borderRadius: 18,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: mesh,
                              ),
                            ),
                            child: Icon(
                              ServiceCategoryIcons.forId(cat['id']!),
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                            .animate(delay: (100 + index * 40).ms)
                            .fade(duration: 280.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Top-rated workers carousel ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Top Rated Near You',
                actionLabel: 'See all',
                onAction: () {
                  ref.read(selectedServiceProvider.notifier).state = null;
                  ref.read(workerSearchQueryProvider.notifier).state = null;
                  ref.read(emergencyModeProvider.notifier).state = false;
                  context.push('/workers');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: workersAsync.when(
                loading: () => SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => SkeletonBox(
                      width: 230,
                      height: 160,
                      borderRadius: 20,
                    ),
                  ),
                ),
                error: (err, _) => _workersErrorBanner(err),
                data: (workers) {
                  final featured =
                      workers.where((w) => w.isOnline).take(6).toList();
                  if (featured.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final w = featured[index];
                        return _FeaturedWorkerCard(
                          name: w.name,
                          rating: w.ratingAvg,
                          jobs: w.totalRatings,
                          distance: w.distanceFormatted,
                          skill: w.skills.isNotEmpty ? w.skills.first : 'worker',
                          verified: w.isVerified,
                          heroTag: 'worker-avatar-${w.id}',
                          onTap: () => context.push('/workers/${w.id}'),
                        )
                            .animate(delay: (index * 60).ms)
                            .fade(duration: 320.ms)
                            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Nearby preview mini-map ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GestureDetector(
                  onTap: () => context.push('/workers'),
                  child: Container(
                    height: 170,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: activeLocation.coordinates,
                            initialZoom: 13.2,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            AppTiles.voyager(),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: activeLocation.coordinates,
                                  width: 44,
                                  height: 44,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.warning,
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.warning
                                              .withValues(alpha: 0.45),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.person_pin_circle_rounded,
                                        color: Colors.white,
                                        size: 22),
                                  ),
                                ),
                              ],
                            ),
                            AppTiles.attribution(),
                          ],
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            borderRadius: 14,
                            opacity: 0.95,
                            tintColor: Colors.white,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.map_rounded,
                                    size: 15, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Explore nearby partners',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 13, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(delay: 120.ms)
                  .fade(duration: 380.ms)
                  .slideY(begin: 0.15, end: 0),
            ),

            // ── Recent bookings ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent Bookings',
                actionLabel: 'View all',
                onAction: () => context.push('/history'),
              ),
            ),
            historyAsync.when(
              loading: () => SliverToBoxAdapter(
                child: Column(
                  children: [
                    SkeletonBox(height: 84, borderRadius: 20),
                    const SizedBox(height: 10),
                    SkeletonBox(height: 84, borderRadius: 20),
                  ],
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: _historyErrorBanner(err, () {
                  ref.invalidate(bookingHistoryProvider);
                }),
              ),
              data: (bookings) {
                final recent = recentBookings;
                if (recent.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = recent[index];
                        return _RecentBookingTile(
                          booking: booking,
                          onTap: () => context
                              .push('/booking/${booking.id}/tracking'),
                        )
                            .animate(delay: (index * 60).ms)
                            .fade(duration: 320.ms)
                            .slideY(begin: 0.15, end: 0);
                      },
                      childCount: recent.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _workersErrorBanner(Object err) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 20, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't load nearby workers.",
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.ink),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(nearbyWorkersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyErrorBanner(Object err, VoidCallback retry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off_rounded,
                size: 20, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't load your bookings.",
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink),
              ),
            ),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Compact Hero-ready featured worker card.
class _FeaturedWorkerCard extends StatelessWidget {
  final String name;
  final double rating;
  final int jobs;
  final String distance;
  final String skill;
  final bool verified;
  final String heroTag;
  final VoidCallback onTap;

  const _FeaturedWorkerCard({
    required this.name,
    required this.rating,
    required this.jobs,
    required this.distance,
    required this.skill,
    required this.verified,
    required this.heroTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against empty/whitespace names — `e[0]` on an empty word throws RangeError.
    final initials = name
        .trim()
        .split(RegExp(r'\\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: heroTag,
                child: Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${skill[0].toUpperCase()}${skill.substring(1)}${verified ? " • Verified" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 15, color: AppColors.warning),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(' ($jobs jobs)',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.inkSoft)),
              const Spacer(),
              if (distance.isNotEmpty)
                Text(
                  distance,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Recent booking row with StatusChip + tracking navigation.
class _RecentBookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _RecentBookingTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 20,
        child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.primaryLight.withValues(alpha: 0.18),
              ]),
            ),
            child: Icon(
              ServiceCategoryIcons.forId(booking.serviceType),
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.workerName ?? 
                      booking.serviceType[0].toUpperCase() +
                          booking.serviceType.substring(1),
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${booking.price.toStringAsFixed(0)} • Tap to view tracking',
                  style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          StatusChip(status: booking.status, dense: true),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.inkFaint, size: 20),
        ],
      ),
      ),
    );
  }
}

/// Shared service icon mapping.
class ServiceCategoryIcons {
  ServiceCategoryIcons._();

  static IconData forId(String id) {
    return switch (id) {
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
}