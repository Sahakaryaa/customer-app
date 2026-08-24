import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../theme/app_colors.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../widgets/worker_card.dart';
import '../../services/location_service.dart';
import '../../models/worker.dart';
import '../../widgets/cooperative_badge.dart';

/// Worker discovery screen — list/map toggle showing nearby verified cooperative workers
/// with staggered card animations, interactive custom map pins, and radar pulse.
class WorkerListScreen extends ConsumerStatefulWidget {
  final String? serviceType;
  final bool isEmergency;
  final String? searchQuery;

  const WorkerListScreen({
    super.key,
    this.serviceType,
    this.isEmergency = false,
    this.searchQuery,
  });

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen>
    with SingleTickerProviderStateMixin {
  bool _isMapView = false;
  Worker? _selectedWorker;
  final MapController _mapController = MapController();
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedServiceProvider.notifier).state = widget.serviceType;
      ref.read(workerSearchQueryProvider.notifier).state = widget.searchQuery;
    });

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = ref.watch(userLocationStateProvider);
    final userLocation = activeLocation.coordinates;
    final workersAsync = ref.watch(nearbyWorkersProvider(userLocation));
    final activeService = ref.watch(selectedServiceProvider);
    final activeSearch = ref.watch(workerSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.isEmergency
              ? 'Emergency Dispatch'
              : activeService != null
                  ? '${_capitalizeFirst(activeService)}s Nearby'
                  : activeSearch != null && activeSearch.isNotEmpty
                      ? 'Results for "$activeSearch"'
                      : 'Workers Nearby',
          style: GoogleFonts.sora(fontWeight: FontWeight.w600),
        ),
        actions: [
          // List/Map toggle pill
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildToggle(Icons.view_list_rounded, 'List', !_isMapView, () {
                  setState(() {
                    _isMapView = false;
                    _selectedWorker = null;
                  });
                }),
                _buildToggle(Icons.map_rounded, 'Map', _isMapView, () {
                  setState(() => _isMapView = true);
                }),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter banner
          if (activeService != null ||
              (activeSearch != null && activeSearch.isNotEmpty) ||
              widget.isEmergency)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: widget.isEmergency
                  ? AppColors.orange.withValues(alpha: 0.1)
                  : AppColors.teal.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    widget.isEmergency
                        ? Icons.flash_on_rounded
                        : activeSearch != null
                            ? Icons.search_rounded
                            : Icons.filter_alt_rounded,
                    size: 16,
                    color: widget.isEmergency ? AppColors.orange : AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEmergency
                          ? 'Showing all available emergency workers near ${activeLocation.areaName}'
                          : activeSearch != null && activeSearch.isNotEmpty
                              ? 'Searching: "$activeSearch"'
                              : 'Filter: ${_capitalizeFirst(activeService!)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isEmergency ? AppColors.orange : AppColors.teal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeService != null ||
                      (activeSearch != null && activeSearch.isNotEmpty))
                    GestureDetector(
                      onTap: () {
                        ref.read(selectedServiceProvider.notifier).state = null;
                        ref.read(workerSearchQueryProvider.notifier).state = null;
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Show All',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.close_rounded,
                                size: 14, color: AppColors.teal),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Expanded(
            child: workersAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: 5,
                itemBuilder: (_, __) => const WorkerCardSkeleton(),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load nearby workers',
                        style: GoogleFonts.inter(color: AppColors.inkLight)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.refresh(nearbyWorkersProvider(userLocation)),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (workers) {
                if (workers.isEmpty) {
                  return _buildEmptyState();
                }

                if (_isMapView) {
                  return _buildMapView(workers, userLocation);
                }

                // Staggered animated worker list
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 250 + (index * 60).clamp(0, 450)),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - val)),
                            child: child,
                          ),
                        );
                      },
                      child: WorkerCard(
                        worker: worker,
                        onTap: () => context.push('/workers/${worker.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isActive ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<Worker> workers, LatLng userLocation) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: 14.5,
            minZoom: 11.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
              userAgentPackageName: 'com.sahakarya.customer_app',
              maxZoom: 20,
            ),

            // Markers Layer with Radar Pulse on User Pin
            MarkerLayer(
              markers: [
                // User location pulsing radar marker
                Marker(
                  point: userLocation,
                  width: 80,
                  height: 80,
                  child: AnimatedBuilder(
                    animation: _radarAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 32 + (40 * _radarAnimation.value),
                            height: 32 + (40 * _radarAnimation.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal.withValues(
                                alpha: (1.0 - _radarAnimation.value) * 0.3,
                              ),
                              border: Border.all(
                                color: AppColors.teal.withValues(
                                  alpha: (1.0 - _radarAnimation.value) * 0.6,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.my_location_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Interactive Worker Pin Badges
                ...workers.map((worker) {
                  final isSelected = _selectedWorker?.id == worker.id;
                  final lat = worker.location.latitude;
                  final lng = worker.location.longitude;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedWorker = worker);
                        _mapController.move(LatLng(lat, lng), 15.2);
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.18 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.orange
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.teal,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  worker.name
                                      .split(' ')
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .take(2)
                                      .join(),
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.teal,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 9, color: AppColors.ink),
                                    Text(
                                      worker.rating.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Floating Recenter Map Action
        Positioned(
          top: 14,
          right: 14,
          child: FloatingActionButton.small(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.teal,
            elevation: 4,
            child: const Icon(Icons.my_location_rounded),
            onPressed: () => _mapController.move(userLocation, 14.8),
          ),
        ),

        // Bottom Selected Worker Preview Sheet
        if (_selectedWorker != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                          child: Text(
                            _selectedWorker!.name
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join(),
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _selectedWorker!.name,
                                    style: GoogleFonts.sora(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const CooperativeBadge(isCompact: true),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedWorker!.skills.join(', '),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.inkLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () =>
                              setState(() => _selectedWorker = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context
                                .push('/workers/${_selectedWorker!.id}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.teal,
                              side: const BorderSide(color: AppColors.teal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('View Profile'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push(
                                '/booking/new?worker=${_selectedWorker!.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Book Now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Workers Found',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting another service type or expanding your search radius.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.inkLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(selectedServiceProvider.notifier).state = null;
                ref.read(workerSearchQueryProvider.notifier).state = null;
              },
              child: const Text('View All Categories'),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
