import 'package:latlong2/latlong.dart';
import '../config/service_region.dart';

export '../config/service_region.dart';

/// Cooperative service hubs across the Godavari service region.
///
/// Coordinates are real OSM-verified positions (see [ServiceRegion]).
/// [availableCities] drives the city filter chips in the location picker;
/// 'All' + region name are always present.
class CooperativeLocation {
  final String id;
  final String areaName;
  final String subDistrict;
  final String city;
  final LatLng coordinates;
  final int activeWorkers;
  final String federationHub;

  const CooperativeLocation({
    required this.id,
    required this.areaName,
    required this.subDistrict,
    required this.city,
    required this.coordinates,
    required this.activeWorkers,
    required this.federationHub,
  });

  /// Cities offered in pickers. 'All' shows every hub; the region entry is
  /// the default filter so first-run users see their own area immediately.
  static const List<String> availableCities = [
    'All',
    ServiceRegion.displayName,
    'Anaparthi',
    'Rajahmundry',
    'Kakinada',
  ];

  static const List<CooperativeLocation> clusters = [
    // ── Anaparthi cluster (default / HQ) ──
    CooperativeLocation(
      id: 'anp_town',
      areaName: 'Anaparthi Town',
      subDistrict: 'Anaparthi Mandal (HQ)',
      city: 'Anaparthi',
      coordinates: ServiceRegion.anaparthi,
      activeWorkers: 24,
      federationHub: 'East Godavari Labour Co-op Federation',
    ),
    CooperativeLocation(
      id: 'anp_dwarapudi',
      areaName: 'Dwarapudi / Arthamuru',
      subDistrict: 'Mandapeta Revenue Circle',
      city: 'Anaparthi',
      coordinates: ServiceRegion.dwarapudi,
      activeWorkers: 15,
      federationHub: 'Godavari Artisans Guild',
    ),
    CooperativeLocation(
      id: 'anp_kothapeta',
      areaName: 'Kothapeta / Ravulapalem',
      subDistrict: 'Kothapeta Mandal',
      city: 'Anaparthi',
      coordinates: ServiceRegion.kothapeta,
      activeWorkers: 17,
      federationHub: 'Delta Services Cooperative',
    ),

    // ── Rajahmundry cluster ──
    CooperativeLocation(
      id: 'rjy_core',
      areaName: 'Rajamahendravaram Central',
      subDistrict: 'Rajahmundry Urban',
      city: 'Rajahmundry',
      coordinates: ServiceRegion.rajahmundry,
      activeWorkers: 31,
      federationHub: 'Rajahmundry Trades Cooperative',
    ),
    CooperativeLocation(
      id: 'rjy_dowleswaram',
      areaName: 'Dowleswaram / Cotton Barrage',
      subDistrict: 'Rajahmundry Rural',
      city: 'Rajahmundry',
      coordinates: LatLng(17.0004, 81.7902),
      activeWorkers: 14,
      federationHub: 'Barrage Township Society',
    ),

    // ── Kakinada cluster ──
    CooperativeLocation(
      id: 'kak_core',
      areaName: 'Kakinada City',
      subDistrict: 'Kakinada Urban',
      city: 'Kakinada',
      coordinates: ServiceRegion.kakinada,
      activeWorkers: 28,
      federationHub: 'Kakinada Port Workers Guild',
    ),
    CooperativeLocation(
      id: 'kak_samarlakota',
      areaName: 'Samarlakota / Peddapuram',
      subDistrict: 'Kakinada Rural Belt',
      city: 'Kakinada',
      coordinates: ServiceRegion.samarlakota,
      activeWorkers: 12,
      federationHub: 'Uppada Road Services Society',
    ),

    // ── Surampalem / Gandepalle cluster ──
    CooperativeLocation(
      id: 'sur_village',
      areaName: 'Surampalem',
      subDistrict: 'Gandepalle Mandal',
      city: 'Rajahmundry',
      coordinates: ServiceRegion.surampalem,
      activeWorkers: 11,
      federationHub: 'Gandepalle Village Cooperative',
    ),
    CooperativeLocation(
      id: 'sur_korukonda',
      areaName: 'Korukonda / Biccavolu',
      subDistrict: 'Gandepalle–Biccavolu Belt',
      city: 'Rajahmundry',
      coordinates: LatLng(17.0810, 81.9650),
      activeWorkers: 9,
      federationHub: 'Korukonda Artisan Circle',
    ),

    // ── Northern towns ──
    CooperativeLocation(
      id: 'rmp_town',
      areaName: 'Ramachandrapuram',
      subDistrict: 'Ramachandrapuram Mandal',
      city: 'Kakinada',
      coordinates: ServiceRegion.ramachandrapuram,
      activeWorkers: 13,
      federationHub: 'Ramachandrapuram Labour Society',
    ),
    CooperativeLocation(
      id: 'mdp_town',
      areaName: 'Mandapeta',
      subDistrict: 'Mandapeta Mandal',
      city: 'Anaparthi',
      coordinates: ServiceRegion.mandapeta,
      activeWorkers: 16,
      federationHub: 'Mandapeta Trades Guild',
    ),
  ];
}
