import 'package:latlong2/latlong.dart';

/// Predefined representative cooperative clusters across India for demo/GPS switching.
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

  static const List<String> availableCities = [
    'All',
    'Bengaluru',
    'Delhi NCR',
    'Mumbai',
    'Hyderabad',
    'Pune',
    'Chennai',
    'Kolkata',
  ];

  static const List<CooperativeLocation> clusters = [
    // ── Bengaluru ──
    CooperativeLocation(
      id: 'blr_indiranagar',
      areaName: 'Indiranagar / Koramangala',
      subDistrict: 'East Bengaluru Hub',
      city: 'Bengaluru',
      coordinates: LatLng(12.9716, 77.6412),
      activeWorkers: 24,
      federationHub: 'Bengaluru Labour Cooperative Federation',
    ),
    CooperativeLocation(
      id: 'blr_hsr',
      areaName: 'HSR Layout / Bellandur',
      subDistrict: 'South East Bengaluru',
      city: 'Bengaluru',
      coordinates: LatLng(12.9121, 77.6446),
      activeWorkers: 19,
      federationHub: 'Koramangala & HSR Workers Guild',
    ),
    CooperativeLocation(
      id: 'blr_whitefield',
      areaName: 'Whitefield / ITPL',
      subDistrict: 'East Bengaluru Tech Zone',
      city: 'Bengaluru',
      coordinates: LatLng(12.9698, 77.7500),
      activeWorkers: 16,
      federationHub: 'Whitefield Artisans & Labour Society',
    ),
    CooperativeLocation(
      id: 'blr_malleshwaram',
      areaName: 'Malleshwaram / Rajajinagar',
      subDistrict: 'North-West Bengaluru',
      city: 'Bengaluru',
      coordinates: LatLng(13.0031, 77.5643),
      activeWorkers: 15,
      federationHub: 'North Bengaluru Cooperative Union',
    ),

    // ── Delhi NCR ──
    CooperativeLocation(
      id: 'del_cp',
      areaName: 'Connaught Place',
      subDistrict: 'Central Delhi (HQ)',
      city: 'Delhi NCR',
      coordinates: LatLng(28.6315, 77.2167),
      activeWorkers: 22,
      federationHub: 'Delhi Central Cooperative Hub',
    ),
    CooperativeLocation(
      id: 'del_saket',
      areaName: 'Saket / Hauz Khas',
      subDistrict: 'South Delhi District',
      city: 'Delhi NCR',
      coordinates: LatLng(28.5244, 77.2066),
      activeWorkers: 18,
      federationHub: 'South Delhi Labour Cooperative Federation',
    ),
    CooperativeLocation(
      id: 'del_karol_bagh',
      areaName: 'Karol Bagh / Patel Nagar',
      subDistrict: 'West Delhi District',
      city: 'Delhi NCR',
      coordinates: LatLng(28.6514, 77.1907),
      activeWorkers: 14,
      federationHub: 'West Delhi Artisans Guild',
    ),
    CooperativeLocation(
      id: 'del_noida',
      areaName: 'Sector 18 / Atta Market',
      subDistrict: 'Gautam Buddha Nagar (Noida)',
      city: 'Delhi NCR',
      coordinates: LatLng(28.5708, 77.3271),
      activeWorkers: 16,
      federationHub: 'Noida Industrial Cooperative Federation',
    ),
    CooperativeLocation(
      id: 'del_gurugram',
      areaName: 'Cyber Hub / DLF Phase 2',
      subDistrict: 'Gurugram Central',
      city: 'Delhi NCR',
      coordinates: LatLng(28.4950, 77.0895),
      activeWorkers: 17,
      federationHub: 'Gurugram Labour Welfare Society',
    ),

    // ── Mumbai ──
    CooperativeLocation(
      id: 'mum_bandra',
      areaName: 'Bandra West / BKC',
      subDistrict: 'Mumbai Western Suburbs',
      city: 'Mumbai',
      coordinates: LatLng(19.0596, 72.8295),
      activeWorkers: 21,
      federationHub: 'Mumbai Metropolitan Labour Guild',
    ),
    CooperativeLocation(
      id: 'mum_andheri',
      areaName: 'Andheri / Juhu',
      subDistrict: 'Western Suburbs Central',
      city: 'Mumbai',
      coordinates: LatLng(19.1136, 72.8697),
      activeWorkers: 20,
      federationHub: 'Andheri Labour Cooperative Society',
    ),
    CooperativeLocation(
      id: 'mum_dadar',
      areaName: 'Dadar / South Mumbai',
      subDistrict: 'Central Mumbai',
      city: 'Mumbai',
      coordinates: LatLng(19.0178, 72.8478),
      activeWorkers: 18,
      federationHub: 'South Mumbai Trades Union',
    ),

    // ── Hyderabad ──
    CooperativeLocation(
      id: 'hyd_hitec',
      areaName: 'HITEC City / Madhapur',
      subDistrict: 'Cyberabad Zone',
      city: 'Hyderabad',
      coordinates: LatLng(17.4483, 78.3915),
      activeWorkers: 23,
      federationHub: 'Cyberabad Labour & Artisans Guild',
    ),
    CooperativeLocation(
      id: 'hyd_banjara',
      areaName: 'Banjara Hills / Jubilee Hills',
      subDistrict: 'Central Hyderabad',
      city: 'Hyderabad',
      coordinates: LatLng(17.4156, 78.4357),
      activeWorkers: 16,
      federationHub: 'Telangana State Cooperative Federation',
    ),

    // ── Pune ──
    CooperativeLocation(
      id: 'pune_kothrud',
      areaName: 'Kothrud / Deccan',
      subDistrict: 'West Pune District',
      city: 'Pune',
      coordinates: LatLng(18.5074, 73.8077),
      activeWorkers: 17,
      federationHub: 'Pune City Labour Cooperative',
    ),
    CooperativeLocation(
      id: 'pune_hinjewadi',
      areaName: 'Hinjewadi IT Park',
      subDistrict: 'Pune Tech Zone',
      city: 'Pune',
      coordinates: LatLng(18.5913, 73.7389),
      activeWorkers: 15,
      federationHub: 'Hinjewadi Services Welfare Society',
    ),

    // ── Chennai ──
    CooperativeLocation(
      id: 'chn_tnagar',
      areaName: 'T. Nagar / Nungambakkam',
      subDistrict: 'Central Chennai',
      city: 'Chennai',
      coordinates: LatLng(13.0418, 80.2341),
      activeWorkers: 18,
      federationHub: 'Chennai Labour Cooperative Federation',
    ),

    // ── Kolkata ──
    CooperativeLocation(
      id: 'kol_saltlake',
      areaName: 'Salt Lake / Sector V',
      subDistrict: 'East Kolkata Tech Zone',
      city: 'Kolkata',
      coordinates: LatLng(22.5867, 88.4178),
      activeWorkers: 16,
      federationHub: 'Kolkata Artisans & Trades Guild',
    ),
  ];
}

