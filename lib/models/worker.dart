import 'package:latlong2/latlong.dart';

/// Worker model matching API_CONTRACT.md WorkerResponse exactly:
/// {id, name, phone, skills, service_type, rating, total_jobs, lat, lng,
///  is_online, certification, federation_id}
class Worker {
  final String id;
  final String userId;
  final String? phone;
  final String name;
  final String? federationName;
  final List<String> skills;
  final String? serviceType;
  final String certificationStatus; // "pending" | "verified" | "rejected"
  final double latitude;
  final double longitude;
  final double ratingAvg;
  final int totalRatings; // contract: total_jobs
  final bool isOnline;
  final double? distanceMeters; // from $geoNear (nearby queries)
  final String? profilePhotoUrl;

  const Worker({
    required this.id,
    required this.userId,
    this.phone,
    required this.name,
    this.federationName,
    required this.skills,
    this.serviceType,
    required this.certificationStatus,
    required this.latitude,
    required this.longitude,
    this.ratingAvg = 0.0,
    this.totalRatings = 0,
    this.isOnline = false,
    this.distanceMeters,
    this.profilePhotoUrl,
  });

  bool get isVerified => certificationStatus == 'verified';
  bool get isRejected => certificationStatus == 'rejected';
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
    // Contract: flat `lat` / `lng`. Legacy nested GeoJSON + latitude/longitude
    // remain as harmless fallbacks.
    double lat = 0.0;
    double lng = 0.0;

    if (json['lat'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num?)?.toDouble() ?? 0.0;
    } else if (json['latitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    } else if (json['location'] is Map) {
      final loc = json['location'] as Map<String, dynamic>;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    // Contract: `is_online` bool; legacy availability string tolerated.
    final online = json['is_online'];
    final availability = json['availability'] as String?;
    final isOnline =
        online is bool ? online : (availability == 'online' || online == true);

    // Certification: contract "verified"|"pending"|"rejected";
    // legacy "certification_status" key tolerated.
    final cert =
        json['certification'] as String? ?? json['certification_status'];

    final skills = List<String>.from(json['skills'] as List? ?? []);
    final serviceType = json['service_type'] as String?;
    if (serviceType != null && !skills.contains(serviceType)) {
      skills.insert(0, serviceType);
    }

    return Worker(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      phone: json['phone']?.toString(),
      name: json['name'] as String? ?? 'Worker',
      federationName:
          json['federation_name'] as String? ?? json['federation_id'] as String?,
      skills: skills,
      serviceType: serviceType,
      certificationStatus: cert as String? ?? 'pending',
      latitude: lat,
      longitude: lng,
      ratingAvg: ((json['rating'] ?? json['rating_avg']) as num?)
              ?.toDouble() ??
          0.0,
      totalRatings:
          ((json['total_jobs'] ?? json['total_ratings']) as num?)?.toInt() ?? 0,
      isOnline: isOnline,
      distanceMeters: (json['distance_m'] as num?)?.toDouble(),
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'skills': skills,
      'service_type': serviceType,
      'rating': ratingAvg,
      'total_jobs': totalRatings,
      'lat': latitude,
      'lng': longitude,
      'is_online': isOnline,
      'certification': certificationStatus,
    };
  }
}
