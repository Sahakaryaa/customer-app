import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../widgets/worker_card.dart';
import '../../services/location_service.dart';
import '../../models/worker.dart';
import '../../widgets/app_tiles.dart';
import '../../widgets/empty_state.dart';

/// Worker discovery — list/map toggle over nearby verified cooperative
/// workers. Emergency mode actually re-ranks results (online → nearest →
/// top-rated) instead of only changing text.
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedServiceProvider.notifier).state = widget.serviceType;
      ref.read(workerSearchQueryProvider.notifier).state = widget.searchQuery;
      // Emergency flag drives real sorting/filtering in the provider.
      ref.read(emergencyModeProvider.notifier).state = widget.isEmergency;
    });
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
        backgroundColor: Colors.white,
        title: Text(
          widget.isEmergency
              ? 'Emergency Dispatch'
              : activeService != null
                  ? '${_capitalizeFirst(activeService)}s Nearby'
                  : activeSearch != null && activeSearch.isNotEmpty
                      ? 'Results for "$activeSearch"'
                      : 'Workers Nearby',
          style: GoogleFonts.sora(fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
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
          if (widget.isEmergency ||
              activeService != null ||
              (activeSearch != null && activeSearch.isNotEmpty))
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: widget.isEmergency
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.06),
              child: Row(
                children: [
                  Icon(
                    widget.isEmergency
                        ? Icons.flash_on_rounded
                        : activeSearch != null && activeSearch.isNotEmpty
                            ? Icons.search_rounded
                            : Icons.filter_alt_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEmergency
                          ? 'Emergency priority — closest online partners first near ${activeLocation.areaName}'
                          : activeSearch != null && activeSearch.isNotEmpty
                              ? 'Searching: "$activeSearch"'
                              : 'Filter: ${_capitalizeFirst(activeService!)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(selectedServiceProvider.notifier).state = null;
                      ref.read(workerSearchQueryProvider.notifier).state =
                          null;
                      ref.read(emergencyModeProvider.notifier).state = false;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close_rounded,
                              size: 13, color: AppColors.primary),
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
              error: (err, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Connection problem',
                subtitle: 'We could not reach the cooperative network. '
                    'Please check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () =>
                    ref.invalidate(nearbyWorkersProvider(userLocation)),
              ),
              data: (workers) {
                if (workers.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No workers found',
                    subtitle:
                        'Try another service category or clear your search to widen the net.',
                    actionLabel: 'View all categories',
                    onAction: () {
                      ref.read(selectedServiceProvider.notifier).state = null;
                      ref.read(workerSearchQueryProvider.notifier).state =
                          null;
                      ref.read(emergencyModeProvider.notifier).state = false;
                    },
                  );
                }

                if (_isMapView) {
                  return _buildMapView(workers, userLocation);
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(nearbyWorkersProvider(userLocation)),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return WorkerCard(
                        key: ValueKey(worker.id),
                        worker: worker,
                        index: index,
                        onTap: () => context.push('/workers/${worker.id}'),
                      );
                    },
                  ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15,
                color: isActive ? Colors.white : AppColors.inkSoft),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.inkSoft,
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
            initialZoom: 14.2,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            AppTiles.voyager(),
            MarkerLayer(
              markers: [
                // Gold customer pin per spec.
                Marker(
                  point: userLocation,
                  width: 52,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning,
                      border:
                          Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_pin_circle_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
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
                        _mapController.move(LatLng(lat, lng), 15);
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Pulsing halo for online workers.
                            if (worker.isOnline)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.amber
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppColors.primary,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.handyman_rounded,
                                  size: 19,
                                  color: isSelected
                                      ? AppColors.ink
                                      : AppColors.primary,
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
            AppTiles.attribution(),
          ],
        ),

        Positioned(
          top: 14,
          right: 14,
          child: FloatingActionButton.small(
            heroTag: 'recenter_discovery',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 4,
            child: const Icon(Icons.my_location_rounded),
            onPressed: () => _mapController.move(userLocation, 14.6),
          ),
        ),

        if (_selectedWorker != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          _selectedWorker!.name
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join(),
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedWorker!.name,
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedWorker!.ratingAvg.toStringAsFixed(1)} ★ · ${_selectedWorker!.skills.join(', ')}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.inkSoft,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            foregroundColor: AppColors.primary,
                            side:
                                const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text('View Profile'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final worker = _selectedWorker!;
                            // Empty skills array would make .first throw StateError.
                            final skill = worker.skills.isNotEmpty
                                ? worker.skills.first
                                : '';
                            context.push(
                                '/booking/new?worker=${worker.id}&service=$skill');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGradient.colors.first,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text('Book Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fade(duration: 220.ms)
                .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
          ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
