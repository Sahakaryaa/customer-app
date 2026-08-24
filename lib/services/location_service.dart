import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_data.dart';
import '../theme/app_colors.dart';

/// Active selected user location provider across the app.
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

/// Wraps Geolocator with fast timeouts, predefined cluster fallbacks, and dialog UI.
class LocationService {
  final Ref? ref;

  LocationService([this.ref]);

  static const defaultLocation = LatLng(28.6315, 77.2167);

  /// Check and request location permissions with a fast 2.5s timeout.
  Future<LatLng> getCurrentLocation({bool fallbackToDefault = true}) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (!serviceEnabled) {
        return fallbackToDefault ? defaultLocation : throw const LocationServiceException('GPS disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return fallbackToDefault ? defaultLocation : throw const LocationServiceException('Permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => Position(
          latitude: defaultLocation.latitude,
          longitude: defaultLocation.longitude,
          timestamp: DateTime.now(),
          accuracy: 100,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      if (fallbackToDefault) return defaultLocation;
      throw const LocationServiceException('Unable to acquire GPS');
    }
  }

  /// Formats coordinate pairs into clean readable location labels.
  String getApproximateArea(LatLng coords) {
    if (coords.latitude > 28.66) return 'Civil Lines, North Delhi';
    if (coords.latitude < 28.54 && coords.longitude < 77.25) return 'Saket, South Delhi';
    if (coords.longitude > 77.30) return 'Sector 18, Noida';
    if (coords.longitude < 77.12) return 'Karol Bagh, West Delhi';
    if (coords.latitude < 28.51 && coords.longitude < 77.10) return 'Cyber Hub, Gurugram';
    return 'Connaught Place, Central Delhi';
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
  ConsumerState<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  bool _isDetectingGps = false;

  Future<void> _detectGps() async {
    setState(() => _isDetectingGps = true);
    try {
      final locService = ref.read(locationServiceProvider);
      final coords = await locService.getCurrentLocation();
      final area = locService.getApproximateArea(coords);
      ref.read(userLocationStateProvider.notifier).setCustomCoordinates(
            coords,
            area,
            'Live GPS Detection (${coords.latitude.toStringAsFixed(3)}, ${coords.longitude.toStringAsFixed(3)})',
          );
      if (mounted) {
        setState(() => _isDetectingGps = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Location updated to $area', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: AppColors.teal,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
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
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Service Location',
                        style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      Text(
                        'Cooperative federation hubs across Delhi NCR',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Live GPS Auto-detect Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: InkWell(
              onTap: _detectGps,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.teal.withValues(alpha: 0.12), AppColors.teal.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: _isDetectingGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
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
                              color: AppColors.teal,
                            ),
                          ),
                          Text(
                            'Auto-detect coordinates and nearest cooperative hub',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.teal, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // Cluster List
          Expanded(
            child: ListView.separated(
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
                      color: isSelected ? AppColors.teal.withValues(alpha: 0.08) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.teal : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.teal
                                : AppColors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: isSelected ? Colors.white : AppColors.teal,
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
                                  Text(
                                    cluster.areaName,
                                    style: GoogleFonts.sora(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? AppColors.teal : AppColors.ink,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cluster.subDistrict,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: AppColors.gold, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cluster.activeWorkers} Verified Workers Nearby',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.inkMuted),
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
