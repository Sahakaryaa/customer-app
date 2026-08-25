import '../models/worker.dart';
import '../models/booking.dart';

/// Mock data provider for development without a backend.
/// Demo data is centered on Delhi NCR — consistent with the cooperative
/// location clusters in models/location_data.dart.
class MockDataService {
  /// Delhi NCR demo center (Connaught Place area) per DESIGN_SPEC.
  static const double _baseLat = 28.61;
  static const double _baseLng = 77.21;

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

  /// Simulated nearby workers around the Delhi NCR demo center.
  static List<Worker> getMockWorkers({String? serviceType}) {
    final allWorkers = [
      Worker(
        id: 'w1',
        userId: 'u1',
        name: 'Ramesh Kumar',
        federationName: 'Delhi Central Cooperative Hub',
        skills: ['electrician', 'plumber'],
        serviceType: 'electrician',
        certificationStatus: 'verified',
        latitude: _baseLat + 0.005,
        longitude: _baseLng + 0.003,
        ratingAvg: 4.8,
        totalRatings: 124,
        isOnline: true,
        distanceMeters: 850,
      ),
      Worker(
        id: 'w2',
        userId: 'u2',
        name: 'Sunita Devi',
        federationName: 'South Delhi Labour Cooperative Federation',
        skills: ['cleaner', 'caregiver'],
        serviceType: 'cleaner',
        certificationStatus: 'verified',
        latitude: _baseLat - 0.002,
        longitude: _baseLng + 0.006,
        ratingAvg: 4.9,
        totalRatings: 89,
        isOnline: true,
        distanceMeters: 1200,
      ),
      Worker(
        id: 'w3',
        userId: 'u3',
        name: 'Venkat Rao',
        federationName: 'West Delhi Artisans Guild',
        skills: ['carpenter', 'painter'],
        serviceType: 'carpenter',
        certificationStatus: 'verified',
        latitude: _baseLat + 0.008,
        longitude: _baseLng - 0.004,
        ratingAvg: 4.6,
        totalRatings: 67,
        isOnline: true,
        distanceMeters: 1800,
      ),
      Worker(
        id: 'w4',
        userId: 'u4',
        name: 'Lakshmi Narayan',
        federationName: 'Delhi Central Cooperative Hub',
        skills: ['electrician'],
        serviceType: 'electrician',
        certificationStatus: 'verified',
        latitude: _baseLat - 0.006,
        longitude: _baseLng - 0.002,
        ratingAvg: 4.7,
        totalRatings: 201,
        isOnline: true,
        distanceMeters: 2100,
      ),
      Worker(
        id: 'w5',
        userId: 'u5',
        name: 'Meera Bai',
        federationName: 'North NCR Workers Society',
        skills: ['cleaner'],
        serviceType: 'cleaner',
        certificationStatus: 'verified',
        latitude: _baseLat + 0.003,
        longitude: _baseLng + 0.009,
        ratingAvg: 4.5,
        totalRatings: 45,
        isOnline: true,
        distanceMeters: 2800,
      ),
      Worker(
        id: 'w6',
        userId: 'u6',
        name: 'Ajay Singh',
        federationName: 'West Delhi Artisans Guild',
        skills: ['plumber', 'carpenter'],
        serviceType: 'plumber',
        certificationStatus: 'verified',
        latitude: _baseLat - 0.009,
        longitude: _baseLng + 0.001,
        ratingAvg: 4.3,
        totalRatings: 33,
        isOnline: true,
        distanceMeters: 3200,
      ),
      Worker(
        id: 'w7',
        userId: 'u7',
        name: 'Priya Sharma',
        federationName: 'South Delhi Labour Cooperative Federation',
        skills: ['caregiver'],
        serviceType: 'caregiver',
        certificationStatus: 'verified',
        latitude: _baseLat + 0.012,
        longitude: _baseLng - 0.007,
        ratingAvg: 4.9,
        totalRatings: 156,
        isOnline: true,
        distanceMeters: 3800,
      ),
      Worker(
        id: 'w8',
        userId: 'u8',
        name: 'Ganesh Reddy',
        federationName: 'Noida Industrial Cooperative Federation',
        skills: ['driver'],
        serviceType: 'driver',
        certificationStatus: 'verified',
        latitude: _baseLat - 0.004,
        longitude: _baseLng + 0.012,
        ratingAvg: 4.4,
        totalRatings: 78,
        isOnline: true,
        distanceMeters: 4100,
      ),
      Worker(
        id: 'w9',
        userId: 'u9',
        name: 'Ravi Teja',
        federationName: 'Delhi Central Cooperative Hub',
        skills: ['painter', 'gardener'],
        serviceType: 'painter',
        certificationStatus: 'verified',
        latitude: _baseLat + 0.015,
        longitude: _baseLng + 0.008,
        ratingAvg: 4.2,
        totalRatings: 29,
        isOnline: true,
        distanceMeters: 5500,
      ),
      Worker(
        id: 'w10',
        userId: 'u10',
        name: 'Kavitha M',
        federationName: 'Gurugram Labour Welfare Society',
        skills: ['gardener', 'cleaner'],
        serviceType: 'gardener',
        certificationStatus: 'pending',
        latitude: _baseLat - 0.011,
        longitude: _baseLng - 0.009,
        ratingAvg: 0.0,
        totalRatings: 0,
        isOnline: true,
        distanceMeters: 6200,
      ),
    ];

    if (serviceType != null) {
      return allWorkers.where((w) => w.skills.contains(serviceType)).toList();
    }
    return allWorkers;
  }

  /// Simulated booking history for the demo user (contract statuses).
  static List<Booking> getMockBookingHistory() {
    return [
      Booking(
        id: 'b1',
        customerId: 'demo_customer',
        workerId: 'w1',
        workerName: 'Ramesh Kumar',
        serviceType: 'electrician',
        status: BookingStatus.completed,
        latitude: _baseLat,
        longitude: _baseLng,
        address: 'Connaught Place, New Delhi',
        price: 450,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Booking(
        id: 'b2',
        customerId: 'demo_customer',
        workerId: 'w2',
        workerName: 'Sunita Devi',
        serviceType: 'cleaner',
        status: BookingStatus.completed,
        latitude: _baseLat,
        longitude: _baseLng,
        address: 'Hauz Khas, South Delhi',
        price: 350,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Booking(
        id: 'b3',
        customerId: 'demo_customer',
        workerId: 'w3',
        workerName: 'Venkat Rao',
        serviceType: 'carpenter',
        status: BookingStatus.completed,
        latitude: _baseLat,
        longitude: _baseLng,
        address: 'Karol Bagh, West Delhi',
        price: 800,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];
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
