import 'package:latlong2/latlong.dart';

/// Predefined representative cooperative cluster in Delhi NCR for demo/real GPS switching.
class CooperativeLocation {
  final String id;
  final String areaName;
  final String subDistrict;
  final LatLng coordinates;
  final int activeWorkers;
  final String federationHub;

  const CooperativeLocation({
    required this.id,
    required this.areaName,
    required this.subDistrict,
    required this.coordinates,
    required this.activeWorkers,
    required this.federationHub,
  });

  static const List<CooperativeLocation> clusters = [
    CooperativeLocation(
      id: 'cp',
      areaName: 'Connaught Place',
      subDistrict: 'Central Delhi (HQ)',
      coordinates: LatLng(28.6315, 77.2167),
      activeWorkers: 18,
      federationHub: 'Delhi Central Cooperative Hub',
    ),
    CooperativeLocation(
      id: 'saket',
      areaName: 'Saket / Hauz Khas',
      subDistrict: 'South Delhi District',
      coordinates: LatLng(28.5244, 77.2066),
      activeWorkers: 14,
      federationHub: 'South Delhi Labour Cooperative Federation',
    ),
    CooperativeLocation(
      id: 'karol_bagh',
      areaName: 'Karol Bagh / Patel Nagar',
      subDistrict: 'West Delhi District',
      coordinates: LatLng(28.6514, 77.1907),
      activeWorkers: 12,
      federationHub: 'West Delhi Artisans Guild',
    ),
    CooperativeLocation(
      id: 'civil_lines',
      areaName: 'Civil Lines / DU North',
      subDistrict: 'North Delhi District',
      coordinates: LatLng(28.6812, 77.2228),
      activeWorkers: 10,
      federationHub: 'North NCR Workers Society',
    ),
    CooperativeLocation(
      id: 'noida',
      areaName: 'Sector 18 / Atta Market',
      subDistrict: 'Gautam Buddha Nagar (Noida)',
      coordinates: LatLng(28.5708, 77.3271),
      activeWorkers: 16,
      federationHub: 'Noida Industrial Cooperative Federation',
    ),
    CooperativeLocation(
      id: 'gurugram',
      areaName: 'Cyber Hub / DLF Phase 2',
      subDistrict: 'Gurugram Central',
      coordinates: LatLng(28.4950, 77.0895),
      activeWorkers: 15,
      federationHub: 'Gurugram Labour Welfare Society',
    ),
  ];
}
