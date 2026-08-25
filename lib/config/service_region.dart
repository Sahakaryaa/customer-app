import 'package:latlong2/latlong.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// SERVICE REGION CONFIG — single source of truth for all geographic data.
/// ────────────────────────────────────────────────────────────────────────────
/// The platform operates across the Godavari belt of Andhra Pradesh:
/// Anaparthi, Surampalem, Rajahmundry, Kakinada and surrounding towns.
///
/// Every coordinate below was resolved against OpenStreetMap/Nominatim
/// (verified Aug 2026). To relocate the platform to another district later,
/// edit ONLY this file — screens, mock data and services derive from here.
/// ────────────────────────────────────────────────────────────────────────────
class ServiceRegion {
  ServiceRegion._();

  // ── Region identity ──
  static const String displayName = 'Godavari Region';
  static const String stateName = 'Andhra Pradesh';
  static const String supportPhone = '+91 883 274 5555';
  static const String federationName =
      'East Godavari Labour Cooperative Federation';

  /// Default center: Anaparthi town centre (East Godavari district).
  /// Strictly a last-resort fallback when no GPS/cache is available;
  /// screens always prefer the device's real position first.
  static const LatLng defaultCenter = LatLng(16.9215, 81.9640);

  /// Default camera zoom for discovery maps.
  static const double defaultZoom = 14.2;

  /// Component accessors for contexts that need plain const doubles
  /// (e.g. const model constructors).
  static const double defaultCenterLat = 16.9215;
  static const double defaultCenterLng = 81.9640;

  // ── Real OSM-verified town coordinates (Nominatim) ──
  static const LatLng anaparthi = LatLng(16.9215, 81.9640);
  static const LatLng surampalem = LatLng(17.1069, 82.0660);
  static const LatLng rajahmundry = LatLng(17.0050, 81.7805);
  static const LatLng kakinada = LatLng(16.9437, 82.2351);
  static const LatLng mandapeta = LatLng(16.8635, 81.9301);
  static const LatLng ramachandrapuram = LatLng(17.2237, 81.6702);
  static const LatLng kothapeta = LatLng(16.7168, 81.8966);
  static const LatLng samarlakota = LatLng(17.0509, 82.1711);
  static const LatLng peddapuram = LatLng(17.0757, 82.1433);
  static const LatLng dwarapudi = LatLng(16.9302, 81.9287);
}
