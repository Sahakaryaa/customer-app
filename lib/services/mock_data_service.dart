import '../models/worker.dart';
import '../models/booking.dart';

/// Mock data provider for development without a backend.
/// Returns realistic demo data for the customer app.
/// Replace with real API calls by toggling `useMockData` in the providers.
class MockDataService {

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

  // Demo city center (Hyderabad, India — common SIH demo location)
  static const double _baseLat = 17.385;
  static const double _baseLng = 78.4867;

  /// Simulated nearby workers around the demo city center.
  static List<Worker> getMockWorkers({String? serviceType}) {
    final allWorkers = [
      Worker(
        id: 'w1',
        userId: 'u1',
        name: 'Ramesh Kumar',
        federationName: 'Telangana Labour Cooperative',
        skills: ['electrician', 'plumber'],
        certificationStatus: 'verified',
        latitude: _baseLat + 0.005,
        longitude: _baseLng + 0.003,
        ratingAvg: 4.8,
        totalRatings: 124,
        availability: 'online',
        distanceMeters: 850,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w2',
        userId: 'u2',
        name: 'Sunita Devi',
        federationName: 'Telangana Labour Cooperative',
        skills: ['cleaner', 'caregiver'],
        certificationStatus: 'verified',
        latitude: _baseLat - 0.002,
        longitude: _baseLng + 0.006,
        ratingAvg: 4.9,
        totalRatings: 89,
        availability: 'online',
        distanceMeters: 1200,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w3',
        userId: 'u3',
        name: 'Venkat Rao',
        federationName: 'AP Workers Federation',
        skills: ['carpenter', 'painter'],
        certificationStatus: 'verified',
        latitude: _baseLat + 0.008,
        longitude: _baseLng - 0.004,
        ratingAvg: 4.6,
        totalRatings: 67,
        availability: 'online',
        distanceMeters: 1800,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w4',
        userId: 'u4',
        name: 'Lakshmi Narayana',
        federationName: 'Telangana Labour Cooperative',
        skills: ['electrician'],
        certificationStatus: 'verified',
        latitude: _baseLat - 0.006,
        longitude: _baseLng - 0.002,
        ratingAvg: 4.7,
        totalRatings: 201,
        availability: 'online',
        distanceMeters: 2100,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w5',
        userId: 'u5',
        name: 'Meera Bai',
        federationName: 'AP Workers Federation',
        skills: ['cleaner'],
        certificationStatus: 'verified',
        latitude: _baseLat + 0.003,
        longitude: _baseLng + 0.009,
        ratingAvg: 4.5,
        totalRatings: 45,
        availability: 'online',
        distanceMeters: 2800,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w6',
        userId: 'u6',
        name: 'Ajay Singh',
        federationName: 'Telangana Labour Cooperative',
        skills: ['plumber', 'carpenter'],
        certificationStatus: 'verified',
        latitude: _baseLat - 0.009,
        longitude: _baseLng + 0.001,
        ratingAvg: 4.3,
        totalRatings: 33,
        availability: 'online',
        distanceMeters: 3200,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w7',
        userId: 'u7',
        name: 'Priya Sharma',
        federationName: 'AP Workers Federation',
        skills: ['caregiver'],
        certificationStatus: 'verified',
        latitude: _baseLat + 0.012,
        longitude: _baseLng - 0.007,
        ratingAvg: 4.9,
        totalRatings: 156,
        availability: 'online',
        distanceMeters: 3800,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w8',
        userId: 'u8',
        name: 'Ganesh Reddy',
        federationName: 'Telangana Labour Cooperative',
        skills: ['driver'],
        certificationStatus: 'verified',
        latitude: _baseLat - 0.004,
        longitude: _baseLng + 0.012,
        ratingAvg: 4.4,
        totalRatings: 78,
        availability: 'online',
        distanceMeters: 4100,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w9',
        userId: 'u9',
        name: 'Ravi Teja',
        federationName: 'Telangana Labour Cooperative',
        skills: ['painter', 'gardener'],
        certificationStatus: 'verified',
        latitude: _baseLat + 0.015,
        longitude: _baseLng + 0.008,
        ratingAvg: 4.2,
        totalRatings: 29,
        availability: 'online',
        distanceMeters: 5500,
        profilePhotoUrl: null,
      ),
      Worker(
        id: 'w10',
        userId: 'u10',
        name: 'Kavitha M',
        federationName: 'AP Workers Federation',
        skills: ['gardener', 'cleaner'],
        certificationStatus: 'pending',
        latitude: _baseLat - 0.011,
        longitude: _baseLng - 0.009,
        ratingAvg: 0.0,
        totalRatings: 0,
        availability: 'online',
        distanceMeters: 6200,
        profilePhotoUrl: null,
      ),
    ];

    if (serviceType != null) {
      return allWorkers
          .where((w) => w.skills.contains(serviceType))
          .toList();
    }
    return allWorkers;
  }

  /// Simulated booking history for the demo user.
  static List<Booking> getMockBookingHistory() {
    return [
      Booking(
        id: 'b1',
        customerId: 'demo_customer',
        workerId: 'w1',
        workerName: 'Ramesh Kumar',
        serviceType: 'electrician',
        status: BookingStatus.rated,
        latitude: _baseLat,
        longitude: _baseLng,
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
        price: 350,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Booking(
        id: 'b3',
        customerId: 'demo_customer',
        workerId: 'w3',
        workerName: 'Venkat Rao',
        serviceType: 'carpenter',
        status: BookingStatus.rated,
        latitude: _baseLat,
        longitude: _baseLng,
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

  /// Get estimated price for a service type.
  static String getEstimatedPrice(String serviceType) {
    final prices = servicePrices[serviceType];
    if (prices == null) return '₹200 – ₹800';
    return '₹${prices['min']} – ₹${prices['max']}';
  }

  /// Simulated worker reviews
  static List<Map<String, dynamic>> getMockReviews() => [
        {
          'customer_name': 'Amit Verma',
          'rating': 5,
          'comment': 'Prompt arrival and diagnosed the circuit issue immediately. Transparent cooperative pricing.',
          'time': '2 days ago',
        },
        {
          'customer_name': 'Pooja Reddy',
          'rating': 5,
          'comment': 'Very polite and thorough with the repairs. Great to see social security contribution included.',
          'time': '1 week ago',
        },
      ];
}
