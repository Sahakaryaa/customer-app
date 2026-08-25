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
      coordinates: coords,
      activeWorkers: 15,
      federationHub: 'Live GPS Location',
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
        LocationSource.cachedDefault => 'Approximate (Delhi NCR)',
      };
}

/// Wraps Geolocator with the DESIGN_SPEC chain:
/// WhenInUse permission (+ friendly explainer sheet) → live GPS →
/// lastKnownPosition → cached default Delhi NCR center (28.61, 77.21)
/// with a non-blocking "approximate location" banner.
class LocationService {
  final Ref? ref;
  bool _explainerShownThisSession = false;

  LocationService([this.ref]);

  /// Cached default: Delhi NCR center per spec.
  static const defaultLocation = LatLng(28.61, 77.21);

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

    // 5) Cached default Delhi NCR center.
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

  /// Nearest-cluster area resolution — deterministic, no unreachable branches.
  /// Replaces the buggy ordered-if chain where the Saket rule swallowed
  /// Gurugram coordinates before the Gurugram rule could fire.
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
    return '${nearest.areaName}, ${nearest.subDistrict}';
  }

  double _squaredDistanceKm(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = (a.longitude - b.longitude) * 0.86; // cos(~28°) correction
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
              'SahaKarya uses your location only to show verified workers '
              'and service partners nearby. You can keep using the app with '
              'an approximate Delhi NCR location if you prefer.',
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

  Future<void> _detectGps() async {
    setState(() => _isDetectingGps = true);
    final messenger = ScaffoldMessenger.of(context); // capture BEFORE pop
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
        // Use the pre-pop captured messenger → no crash after pop.
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Location updated to ${result.areaLabel}',
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                        'Select Service Location',
                        style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                      Text(
                        'Cooperative federation hubs across Delhi NCR',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                            'Use Current GPS Location',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Auto-detect coordinates and nearest cooperative hub',
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
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: CooperativeLocation.clusters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cluster = CooperativeLocation.clusters[index];
                final isSelected = activeLocation.id == cluster.id;

                return InkWell(
                  onTap: () {
                    ref.read(userLocationStateProvider.notifier).setLocation(cluster);
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
                        color: isSelected ? AppColors.primary : AppColors.border,
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
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cluster.subDistrict,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded,
                                      color: AppColors.warning, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cluster.activeWorkers} Verified Workers Nearby',
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

