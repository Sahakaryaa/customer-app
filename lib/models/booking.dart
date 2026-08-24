/// Booking model matching the MongoDB booking document schema.
/// Status flows: requested → matched → in_progress → completed → rated
class Booking {
  final String id;
  final String customerId;
  final String? workerId;
  final String? workerName;
  final String serviceType;
  final BookingStatus status;
  final double latitude;
  final double longitude;
  final DateTime? scheduledTime;
  final bool isEmergency;
  final double price;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.customerId,
    this.workerId,
    this.workerName,
    required this.serviceType,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.scheduledTime,
    this.isEmergency = false,
    this.price = 0.0,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
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

    return Booking(
      id: json['_id'] as String? ?? json['id'] as String,
      customerId: json['customer_id'] as String,
      workerId: json['worker_id'] as String?,
      workerName: json['worker_name'] as String?,
      serviceType: json['service_type'] as String,
      status: BookingStatus.fromString(json['status'] as String),
      latitude: lat,
      longitude: lng,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      isEmergency: json['is_emergency'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'worker_id': workerId,
      'worker_name': workerName,
      'service_type': serviceType,
      'status': status.value,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'scheduled_time': scheduledTime?.toIso8601String(),
      'is_emergency': isEmergency,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Booking status enum matching the backend state machine.
enum BookingStatus {
  requested('requested', 'Requested', 0),
  matched('matched', 'Worker Matched', 1),
  inProgress('in_progress', 'In Progress', 2),
  completed('completed', 'Completed', 3),
  rated('rated', 'Rated', 4);

  const BookingStatus(this.value, this.label, this.stepIndex);

  final String value;
  final String label;
  final int stepIndex;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => BookingStatus.requested,
    );
  }
}
