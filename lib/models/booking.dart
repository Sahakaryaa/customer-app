/// Booking model matching API_CONTRACT.md BookingResponse exactly:
/// {id, service_type, description, price, lat, lng, address, status,
///  customer_id, worker_id, customer_name, worker_name, rating, created_at}
class Booking {
  final String id;
  final String customerId;
  final String? customerName;
  final String? workerId;
  final String? workerName;
  final String serviceType;
  final String? description;
  final double price;
  final double latitude;
  final double longitude;
  final String? address;
  final BookingStatus status;
  final int? rating;
  final DateTime? scheduledTime; // legacy field, tolerated
  final bool isEmergency; // legacy field, tolerated
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.customerId,
    this.customerName,
    this.workerId,
    this.workerName,
    required this.serviceType,
    this.description,
    this.price = 0.0,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.status,
    this.rating,
    this.scheduledTime,
    this.isEmergency = false,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
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

    return Booking(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] as String?,
      workerId: json['worker_id']?.toString(),
      workerName: json['worker_name'] as String?,
      serviceType: json['service_type'] as String? ?? 'service',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      latitude: lat,
      longitude: lng,
      address: json['address'] as String?,
      status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
      rating: (json['rating'] as num?)?.toInt(),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.tryParse(json['scheduled_time'] as String)
          : null,
      isEmergency: json['is_emergency'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String) ??
              DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'worker_id': workerId,
      'service_type': serviceType,
      'price': price,
      'lat': latitude,
      'lng': longitude,
      'address': address,
      'status': status.value,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Whether the booking can still be cancelled by the customer.
  bool get cancellable =>
      status == BookingStatus.pending || status == BookingStatus.accepted;

  /// Whether the flow should continue to live tracking.
  bool get isActive =>
      status == BookingStatus.pending ||
      status == BookingStatus.accepted ||
      status == BookingStatus.enRoute ||
      status == BookingStatus.arrived ||
      status == BookingStatus.started;

  /// Whether the booking can be rated now.
  bool get rateable => status == BookingStatus.completed && rating == null;
}

/// Booking status enum matching the backend state machine exactly.
enum BookingStatus {
  pending('pending', 'Pending', 0),
  accepted('accepted', 'Accepted', 1),
  declined('declined', 'Declined', 1),
  enRoute('en_route', 'En Route', 2),
  arrived('arrived', 'Arrived', 3),
  started('started', 'Started', 4),
  completed('completed', 'Completed', 5),
  cancelled('cancelled', 'Cancelled', 1);

  const BookingStatus(this.value, this.label, this.stepIndex);

  final String value;
  final String label;
  final int stepIndex;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}
