import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/service_category_tile.dart';
import '../../services/location_service.dart';
import '../../widgets/cooperative_badge.dart';

/// Main home screen — service category grid, interactive search, live location cluster selector,
/// pulsing emergency CTA, and recent booking history cards.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      ref.read(selectedServiceProvider.notifier).state = null;
      ref.read(workerSearchQueryProvider.notifier).state = trimmed;
      context.push('/workers?search=${Uri.encodeComponent(trimmed)}');
    } else {
      ref.read(selectedServiceProvider.notifier).state = null;
      ref.read(workerSearchQueryProvider.notifier).state = null;
      context.push('/workers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Customer';
    final activeLocation = ref.watch(userLocationStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Top header with greeting & Live Location Cluster Pill
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Selector Bar
                      GestureDetector(
                        onTap: () => LocationService.showLocationPickerModal(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.gold,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 210),
                                child: Text(
                                  activeLocation.areaName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top bar with profile (no subpixel overflow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName',
                                  style: GoogleFonts.sora(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cooperative Services, Fair Dignity.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Interactive Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppColors.teal, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: _onSearch,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.ink,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  hintText:
                                      'Search electrician, plumber, cleaner...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.inkLight),
                              ),
                            GestureDetector(
                              onTap: () => _onSearch(_searchController.text),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: AppColors.teal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Emergency booking banner with breathing pulse animation
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    ref.read(selectedServiceProvider.notifier).state = null;
                    ref.read(workerSearchQueryProvider.notifier).state = null;
                    context.push('/workers?emergency=true');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Booking',
                                style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nearest verified worker dispatched in ~5 mins',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Services',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '8 Categories Available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service category grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = MockDataService.serviceCategories[index];
                  return ServiceCategoryTile(
                    label: category['label']!,
                    icon: ServiceCategoryTile.getIconForService(
                        category['id']!),
                    onTap: () {
                      ref.read(selectedServiceProvider.notifier).state =
                          category['id'];
                      ref.read(workerSearchQueryProvider.notifier).state = null;
                      context.push('/workers?service=${category['id']}');
                    },
                  );
                },
                childCount: MockDataService.serviceCategories.length,
              ),
            ),
          ),

          // Section: Cooperative Federation Trust Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Cooperative Governance',
                                style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                              const CooperativeBadge(isCompact: true),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'NCCT affiliated • 1% of every job funds partner healthcare & pensions',
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
              ),
            ),
          ),

          // Recent bookings header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Bookings',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/history'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent bookings horizontal list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 156,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: MockDataService.getMockBookingHistory().take(3).length,
                itemBuilder: (context, index) {
                  final booking =
                      MockDataService.getMockBookingHistory().take(3).toList()[index];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12, bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  ServiceCategoryTile.getIconForService(
                                      booking.serviceType),
                                  size: 18,
                                  color: AppColors.teal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  booking.serviceType[0].toUpperCase() +
                                      booking.serviceType.substring(1),
                                  style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          booking.workerName ?? 'Assigned Partner',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.inkLight,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${booking.price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                booking.status.name,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
