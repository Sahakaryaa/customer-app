import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_data.dart';
import '../theme/app_colors.dart';

/// Whether the current location is an approximate fallback (not live GPS).
final locationIsApproximateProvider = StateProvider<bool>((ref) => false);

/// Active selected user location across the app.
final userLocationStateProvider =
    StateNotifierProvider<UserLocationNotifier, CooperativeLocation>((ref) {
  return UserLocationNotifier();
});

class UserLocationNotifier extends StateNotifier<CooperativeLocation> {
  UserLocationNotifier() : super(CooperativeLocation.clusters.first);

  void setLocation(CooperativeLocation loc) {
    state = loc;
  }

  void setCustomCoordinates(LatLng coords, String name, String subDistrict) {
    state = CooperativeLocation(
      id: 'custom_gps',
      areaName: name,
      subDistrict: subDistrict,
      city: 'Current GPS',
      coordinates: coords,
      activeWorkers: 18,
      federationHub: 'Local Cooperative Network',
    );
  }
}

/// Provider for the location service helper.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref);
});

enum LocationSource { liveGps, lastKnown, cachedDefault }

/// Result of the resolution chain.
class LocationResult {
  final LatLng coords;
  final LocationSource source;
  final String areaLabel;

  const LocationResult({
    required this.coords,
    required this.source,
    required this.areaLabel,
  });

  bool get isApproximate => source != LocationSource.liveGps;

  String get sourceLabel => switch (source) {
        LocationSource.liveGps => 'Live GPS',
        LocationSource.lastKnown => 'Last known position',
        LocationSource.cachedDefault => 'Approximate Hub',
      };
}

/// Wraps Geolocator with the DESIGN_SPEC chain:
/// WhenInUse permission (+ friendly explainer sheet) → live GPS →
/// lastKnownPosition → cached default location
/// with a non-blocking "approximate location" banner.
class LocationService {
  final Ref? ref;
  bool _explainerShownThisSession = false;

  LocationService([this.ref]);

  /// Default starting location (Bengaluru Indiranagar or nearest cluster).
  static const defaultLocation = LatLng(12.9716, 77.6412);

  /// Full chain. Never throws when [fallbackToDefault] is true.
  Future<LocationResult> resolveLocation({
    bool fallbackToDefault = true,
    bool showExplainer = true,
    BuildContext? context,
  }) async {
    LocationPermission permission = LocationPermission.denied;

    // 1) Permission — with a one-time friendly explainer bottom sheet.
    try {
      permission = await Geolocator.checkPermission();
      if ((permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) &&
          showExplainer &&
          !_explainerShownThisSession &&
          context != null &&
          context.mounted) {
        await _showExplainerSheet(context);
        _explainerShownThisSession = true;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {
      permission = LocationPermission.denied;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _fallback();
    }

    // 2) Location service enabled?
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _fallback();
    } catch (_) {
      return _fallback();
    }

    // 3) Live GPS attempt.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return _result(position.latitude, position.longitude,
          LocationSource.liveGps);
    } catch (_) {
      // fall through
    }

    // 4) Last known position.
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return _result(last.latitude, last.longitude, LocationSource.lastKnown);
      }
    } catch (_) {
      // fall through
    }

    // 5) Cached default location.
    return _fallback();
  }

  LocationResult _fallback() {
    final result = LocationResult(
      coords: defaultLocation,
      source: LocationSource.cachedDefault,
      areaLabel: getApproximateArea(defaultLocation),
    );
    return result;
  }

  LocationResult _result(double lat, double lng, LocationSource source) {
    final coords = LatLng(lat, lng);
    return LocationResult(
      coords: coords,
      source: source,
      areaLabel: getApproximateArea(coords),
    );
  }

  /// Resolve AND push into app-wide state, updating the approximate banner flag.
  Future<LocationResult> resolveAndApply(WidgetRef ref,
      {BuildContext? context}) async {
    final result = await resolveLocation(context: context);
    ref.read(userLocationStateProvider.notifier).setCustomCoordinates(
          result.coords,
          result.areaLabel,
          'Live GPS (${result.coords.latitude.toStringAsFixed(3)}, '
              '${result.coords.longitude.toStringAsFixed(3)})',
        );
    ref.read(locationIsApproximateProvider.notifier).state =
        result.isApproximate;
    return result;
  }

  /// Nearest-cluster area resolution across nationwide hubs.
  String getApproximateArea(LatLng coords) {
    CooperativeLocation nearest = CooperativeLocation.clusters.first;
    double best = double.infinity;
    for (final c in CooperativeLocation.clusters) {
      final d = _squaredDistanceKm(coords, c.coordinates);
      if (d < best) {
        best = d;
        nearest = c;
      }
    }
    // If within ~40km of a cluster, show the cluster area and city
    if (best < 0.15) {
      return '${nearest.areaName}, ${nearest.city}';
    }
    return '${nearest.city} (${coords.latitude.toStringAsFixed(2)}, ${coords.longitude.toStringAsFixed(2)})';
  }

  double _squaredDistanceKm(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = (a.longitude - b.longitude) * 0.86;
    return dLat * dLat + dLng * dLng;
  }

  /// One-time friendly permission explainer (rounded top-28 modal per spec).
  Future<void> _showExplainerSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primaryLight.withValues(alpha: 0.22),
                ]),
              ),
              child:
                  const Icon(Icons.my_location_rounded, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Find workers near you',
              style: GoogleFonts.sora(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SahaKarya uses your location to discover verified cooperative workers '
              'and service partners near you in real time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.inkSoft,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the interactive cooperative region switcher modal.
  static void showLocationPickerModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LocationPickerSheet(),
    );
  }
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  bool _isDetectingGps = false;
  String _selectedCity = 'All';

  Future<void> _detectGps() async {
    setState(() => _isDetectingGps = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final locService = ref.read(locationServiceProvider);
      final result = await locService.resolveLocation(showExplainer: false);
      ref.read(userLocationStateProvider.notifier).setCustomCoordinates(
            result.coords,
            result.areaLabel,
            '${result.sourceLabel} '
                '(${result.coords.latitude.toStringAsFixed(3)}, '
                '${result.coords.longitude.toStringAsFixed(3)})',
          );
      ref.read(locationIsApproximateProvider.notifier).state =
          result.isApproximate;
      if (mounted) {
        setState(() => _isDetectingGps = false);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Location set to ${result.areaLabel}',
                      style: GoogleFonts.inter()),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = ref.watch(userLocationStateProvider);
    final filteredClusters = _selectedCity == 'All'
        ? CooperativeLocation.clusters
        : CooperativeLocation.clusters
            .where((c) => c.city == _selectedCity)
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Service Hub',
                        style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                      Text(
                        'Cooperative federation hubs across India',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── GPS button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: InkWell(
              onTap: _detectGps,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.primaryLight.withValues(alpha: 0.06),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isDetectingGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.my_location_rounded,
                              color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use My Live GPS Location',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Auto-detect device coordinates and nearest workers',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── City filter chips ──
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: CooperativeLocation.availableCities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final city = CooperativeLocation.availableCities[index];
                final isSelected = _selectedCity == city;
                return ChoiceChip(
                  label: Text(city),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceAlt,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _selectedCity = city);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // ── List of clusters ──
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: filteredClusters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cluster = filteredClusters[index];
                final isSelected = activeLocation.id == cluster.id;

                return InkWell(
                  onTap: () {
                    ref
                        .read(userLocationStateProvider.notifier)
                        .setLocation(cluster);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.07)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cluster.areaName,
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cluster.city,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cluster.subDistrict} • ${cluster.federationHub}',
                                style: GoogleFonts.inter(
                                    fontSize: 11.5, color: AppColors.inkSoft),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded,
                                      color: AppColors.warning, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cluster.activeWorkers} Verified Workers Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.inkFaint),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom exception for location errors.
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

