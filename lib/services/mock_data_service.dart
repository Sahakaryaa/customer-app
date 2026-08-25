import 'package:latlong2/latlong.dart';
import '../models/worker.dart';
import '../models/booking.dart';
import '../models/location_data.dart';
import 'booking_socket.dart' show haversineKm;

/// Mock data provider for development and seamless demo mode.
/// Generates realistic cooperative workers around the user's active GPS/mock location.
class MockDataService {
  /// Default center if none provided (Bengaluru Indiranagar).
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.6412;

  /// In-memory storage for bookings created during the active demo session.
  static final List<Booking> inMemoryBookings = [];

  /// Service categories available on the platform.
  static const List<Map<String, String>> serviceCategories = [
    {'id': 'electrician', 'label': 'Electrician', 'icon': 'bolt'},
    {'id': 'plumber', 'label': 'Plumber', 'icon': 'plumbing'},
    {'id': 'carpenter', 'label': 'Carpenter', 'icon': 'carpenter'},
    {'id': 'painter', 'label': 'Painter', 'icon': 'format_paint'},
    {'id': 'cleaner', 'label': 'Cleaner', 'icon': 'cleaning_services'},
    {'id': 'caregiver', 'label': 'Caregiver', 'icon': 'health_and_safety'},
    {'id': 'driver', 'label': 'Driver', 'icon': 'directions_car'},
    {'id': 'gardener', 'label': 'Gardener', 'icon': 'grass'},
  ];

  /// Find nearest cooperative hub name for contextual branding.
  static String _resolveFederationName(double lat, double lng) {
    CooperativeLocation nearest = CooperativeLocation.clusters.first;
    double bestDist = double.infinity;
    for (final c in CooperativeLocation.clusters) {
      final dLat = lat - c.coordinates.latitude;
      final dLng = lng - c.coordinates.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        nearest = c;
      }
    }
    return nearest.federationHub;
  }

  /// Simulated nearby workers around the user's active coordinates.
  static List<Worker> getMockWorkers({String? serviceType, LatLng? centerLocation}) {
    final baseLat = centerLocation?.latitude ?? defaultLat;
    final baseLng = centerLocation?.longitude ?? defaultLng;
    final fedName = _resolveFederationName(baseLat, baseLng);

    // Realistic offsets producing 400m to 4.5km distances around the active center
    final workerTemplates = [
      (
        id: 'w1',
        name: 'Ramesh Kumar',
        skills: ['electrician', 'plumber'],
        primary: 'electrician',
        status: 'verified',
        dLat: 0.0045,
        dLng: 0.0032,
        rating: 4.8,
        total: 124,
        online: true,
      ),
      (
        id: 'w2',
        name: 'Sunita Devi',
        skills: ['cleaner', 'caregiver'],
        primary: 'cleaner',
        status: 'verified',
        dLat: -0.0035,
        dLng: 0.0058,
        rating: 4.9,
        total: 89,
        online: true,
      ),
      (
        id: 'w3',
        name: 'Venkat Rao',
        skills: ['carpenter', 'painter'],
        primary: 'carpenter',
        status: 'verified',
        dLat: 0.0072,
        dLng: -0.0041,
        rating: 4.6,
        total: 67,
        online: true,
      ),
      (
        id: 'w4',
        name: 'Lakshmi Narayan',
        skills: ['electrician'],
        primary: 'electrician',
        status: 'verified',
        dLat: -0.0061,
        dLng: -0.0028,
        rating: 4.7,
        total: 201,
        online: true,
      ),
      (
        id: 'w5',
        name: 'Meera Bai',
        skills: ['cleaner'],
        primary: 'cleaner',
        status: 'verified',
        dLat: 0.0028,
        dLng: 0.0084,
        rating: 4.5,
        total: 45,
        online: true,
      ),
      (
        id: 'w6',
        name: 'Ajay Singh',
        skills: ['plumber', 'carpenter'],
        primary: 'plumber',
        status: 'verified',
        dLat: -0.0085,
        dLng: 0.0019,
        rating: 4.3,
        total: 33,
        online: true,
      ),
      (
        id: 'w7',
        name: 'Priya Sharma',
        skills: ['caregiver'],
        primary: 'caregiver',
        status: 'verified',
        dLat: 0.0112,
        dLng: -0.0065,
        rating: 4.9,
        total: 156,
        online: true,
      ),
      (
        id: 'w8',
        name: 'Ganesh Reddy',
        skills: ['driver'],
        primary: 'driver',
        status: 'verified',
        dLat: -0.0042,
        dLng: 0.0118,
        rating: 4.4,
        total: 78,
        online: true,
      ),
      (
        id: 'w9',
        name: 'Ravi Teja',
        skills: ['painter', 'gardener'],
        primary: 'painter',
        status: 'verified',
        dLat: 0.0135,
        dLng: 0.0075,
        rating: 4.2,
        total: 29,
        online: true,
      ),
      (
        id: 'w10',
        name: 'Kavitha M',
        skills: ['gardener', 'cleaner'],
        primary: 'gardener',
        status: 'verified',
        dLat: -0.0102,
        dLng: -0.0085,
        rating: 4.6,
        total: 22,
        online: true,
      ),
    ];

    final allWorkers = workerTemplates.map((t) {
      final wLat = baseLat + t.dLat;
      final wLng = baseLng + t.dLng;
      final distKm = haversineKm(baseLat, baseLng, wLat, wLng);
      final distMeters = distKm * 1000;

      return Worker(
        id: t.id,
        userId: 'u_${t.id}',
        name: t.name,
        federationName: fedName,
        skills: t.skills,
        serviceType: t.primary,
        certificationStatus: t.status,
        latitude: wLat,
        longitude: wLng,
        ratingAvg: t.rating,
        totalRatings: t.total,
        isOnline: t.online,
        distanceMeters: distMeters,
      );
    }).toList();

    if (serviceType != null && serviceType.isNotEmpty) {
      return allWorkers.where((w) => w.skills.contains(serviceType)).toList();
    }
    return allWorkers;
  }

  /// Simulated booking history for the demo user including any created in-session.
  static List<Booking> getMockBookingHistory({LatLng? userLocation, String? areaName}) {
    final baseLat = userLocation?.latitude ?? defaultLat;
    final baseLng = userLocation?.longitude ?? defaultLng;
    final area = areaName ?? 'Nearby Cooperative Hub';

    final defaultPastBookings = [
      Booking(
        id: 'b_sample_1',
        customerId: 'demo_customer',
        workerId: 'w1',
        workerName: 'Ramesh Kumar',
        serviceType: 'electrician',
        status: BookingStatus.completed,
        latitude: baseLat + 0.002,
        longitude: baseLng + 0.001,
        address: '$area, Main Street',
        price: 450.0,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Booking(
        id: 'b_sample_2',
        customerId: 'demo_customer',
        workerId: 'w2',
        workerName: 'Sunita Devi',
        serviceType: 'cleaner',
        status: BookingStatus.completed,
        latitude: baseLat - 0.001,
        longitude: baseLng + 0.002,
        address: '$area, Sector Block',
        price: 350.0,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Booking(
        id: 'b_sample_3',
        customerId: 'demo_customer',
        workerId: 'w3',
        workerName: 'Venkat Rao',
        serviceType: 'carpenter',
        status: BookingStatus.completed,
        latitude: baseLat + 0.004,
        longitude: baseLng - 0.002,
        address: '$area, Artisans Hub',
        price: 800.0,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];

    // Newly created bookings appear first
    return [...inMemoryBookings, ...defaultPastBookings];
  }

  /// Single mock booking lookup by id
  static Booking getMockBooking(String id, {LatLng? userLocation}) {
    // Check in-memory first
    final inMemory = inMemoryBookings.where((b) => b.id == id);
    if (inMemory.isNotEmpty) return inMemory.first;

    final history = getMockBookingHistory(userLocation: userLocation);
    for (final b in history) {
      if (b.id == id) return b;
    }

    // Default fallback booking
    final lat = userLocation?.latitude ?? defaultLat;
    final lng = userLocation?.longitude ?? defaultLng;
    return Booking(
      id: id,
      customerId: 'demo_customer',
      workerId: 'w1',
      workerName: 'Ramesh Kumar',
      serviceType: 'electrician',
      status: BookingStatus.accepted,
      latitude: lat,
      longitude: lng,
      address: 'Current Service Address',
      price: 450.0,
      createdAt: DateTime.now(),
    );
  }

  /// Simulated service price ranges.
  static Map<String, Map<String, int>> get servicePrices => {
        'electrician': {'min': 200, 'max': 800},
        'plumber': {'min': 250, 'max': 900},
        'carpenter': {'min': 400, 'max': 1500},
        'painter': {'min': 500, 'max': 2000},
        'cleaner': {'min': 200, 'max': 600},
        'caregiver': {'min': 300, 'max': 1000},
        'driver': {'min': 150, 'max': 500},
        'gardener': {'min': 200, 'max': 700},
      };

  /// Base booking price per service type (flat, stored on the backend).
  static double basePrice(String serviceType) {
    switch (serviceType) {
      case 'electrician':
        return 450.0;
      case 'plumber':
        return 400.0;
      case 'carpenter':
        return 550.0;
      case 'cleaner':
        return 350.0;
      case 'painter':
        return 650.0;
      case 'caregiver':
        return 500.0;
      case 'gardener':
        return 300.0;
      case 'driver':
        return 250.0;
      default:
        return 450.0;
    }
  }

  /// Simulated worker reviews
  static List<Map<String, dynamic>> getMockReviews() => [
        {
          'customer_name': 'Amit Verma',
          'rating': 5,
          'comment':
              'Prompt arrival and diagnosed the circuit issue immediately. Transparent cooperative pricing.',
          'time': '2 days ago',
        },
        {
          'customer_name': 'Pooja Sharma',
          'rating': 5,
          'comment':
              'Very polite and thorough with the repairs. Great to see social security contribution included.',
          'time': '1 week ago',
        },
      ];
}

