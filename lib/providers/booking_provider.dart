import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../services/api_client.dart';
import '../services/booking_socket.dart';
import '../services/mock_data_service.dart';
import 'auth_provider.dart';

/// Live booking status stream — uses WebSocket in real mode, simulated in mock mode.
final bookingStatusProvider =
    StreamProvider.family<BookingStatus, String>((ref, bookingId) {
  if (useMockData) {
    // Simulate booking status progression for demo
    return _simulateBookingProgress();
  }

  final socket = ref.read(bookingSocketProvider);
  ref.onDispose(() => socket.disconnect());
  return socket.connect(bookingId);
});

/// Simulates a booking going through all status stages for demo purposes.
Stream<BookingStatus> _simulateBookingProgress() async* {
  yield BookingStatus.requested;
  await Future.delayed(const Duration(seconds: 3));
  yield BookingStatus.matched;
  await Future.delayed(const Duration(seconds: 5));
  yield BookingStatus.inProgress;
  await Future.delayed(const Duration(seconds: 8));
  yield BookingStatus.completed;
}

/// Create a new booking.
final createBookingProvider = FutureProvider.family
    .autoDispose<Booking, Map<String, dynamic>>((ref, params) async {
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 800));
    return Booking(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'demo_customer',
      workerId: params['worker_id'] as String?,
      workerName: params['worker_name'] as String?,
      serviceType: params['service_type'] as String,
      status: BookingStatus.requested,
      latitude: params['lat'] as double,
      longitude: params['lng'] as double,
      scheduledTime: params['scheduled_time'] as DateTime?,
      isEmergency: params['is_emergency'] as bool? ?? false,
      price: params['price'] as double? ?? 0.0,
      createdAt: DateTime.now(),
    );
  }

  final api = ref.read(apiClientProvider);
  return api.createBooking(
    serviceType: params['service_type'] as String,
    lat: params['lat'] as double,
    lng: params['lng'] as double,
    scheduledTime: params['scheduled_time'] as DateTime?,
    isEmergency: params['is_emergency'] as bool? ?? false,
  );
});

/// Booking history provider.
final bookingHistoryProvider = FutureProvider<List<Booking>>((ref) async {
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockDataService.getMockBookingHistory();
  }

  final api = ref.read(apiClientProvider);
  return api.getBookingHistory();
});

/// Currently active booking (in-progress tracking).
final activeBookingProvider = StateProvider<Booking?>((ref) => null);
