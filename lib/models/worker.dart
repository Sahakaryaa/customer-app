import 'package:latlong2/latlong.dart';

/// Worker model as seen by the customer app.
/// Includes distance (from $geoNear) and cooperative verification status.
class Worker {
  final String id;
  final String userId;
  final String name;
  final String? federationName;
  final List<String> skills;
  final String certificationStatus; // "pending" | "verified"
  final double latitude;
  final double longitude;
  final double ratingAvg;
  final int totalRatings;
  final String availability; // "online" | "offline"
  final double? distanceMeters; // from $geoNear
  final String? profilePhotoUrl;

  const Worker({
    required this.id,
    required this.userId,
    required this.name,
    this.federationName,
    required this.skills,
    required this.certificationStatus,
    required this.latitude,
    required this.longitude,
    this.ratingAvg = 0.0,
    this.totalRatings = 0,
    this.availability = 'offline',
    this.distanceMeters,
    this.profilePhotoUrl,
  });

  bool get isVerified => certificationStatus == 'verified';
  bool get isOnline => availability == 'online';
  double get rating => ratingAvg;
  LatLng get location => LatLng(latitude, longitude);

  /// Distance formatted for display (e.g., "1.2 km" or "800 m").
  String get distanceFormatted {
    if (distanceMeters == null) return '';
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters!.round()} m';
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    // Handle both nested location format and flat lat/lng
    double lat = 0.0;
    double lng = 0.0;
    if (json['location'] != null) {
      final coords = json['location']['coordinates'] as List;
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return Worker(
      id: json['_id'] as String? ?? json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Worker',
      federationName: json['federation_name'] as String?,
      skills: List<String>.from(json['skills'] as List? ?? []),
      certificationStatus:
          json['certification_status'] as String? ?? 'pending',
      latitude: lat,
      longitude: lng,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      availability: json['availability'] as String? ?? 'offline',
      distanceMeters: (json['distance_m'] as num?)?.toDouble(),
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'federation_name': federationName,
      'skills': skills,
      'certification_status': certificationStatus,
      'latitude': latitude,
      'longitude': longitude,
      'rating_avg': ratingAvg,
      'total_ratings': totalRatings,
      'availability': availability,
      'distance_m': distanceMeters,
      'profile_photo_url': profilePhotoUrl,
    };
  }
}
