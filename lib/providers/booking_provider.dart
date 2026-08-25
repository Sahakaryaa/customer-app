import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/worker.dart';
import '../services/api_client.dart';
import '../services/mock_data_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

/// Booking history provider (GET /users/me/bookings with offline demo fallback).
final bookingHistoryProvider = FutureProvider<List<Booking>>((ref) async {
  final activeLoc = ref.watch(userLocationStateProvider);
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataService.getMockBookingHistory(
      userLocation: activeLoc.coordinates,
      areaName: activeLoc.areaName,
    );
  }
  try {
    final api = ref.read(apiClientProvider);
    final history = await api.getBookingHistory();
    return [...MockDataService.inMemoryBookings, ...history];
  } catch (_) {
    return MockDataService.getMockBookingHistory(
      userLocation: activeLoc.coordinates,
      areaName: activeLoc.areaName,
    );
  }
});

/// Single booking fetch (GET /bookings/{id} with fallback).
final bookingDetailProvider =
    FutureProvider.family.autoDispose<Booking, String>((ref, bookingId) async {
  final activeLoc = ref.read(userLocationStateProvider);
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockDataService.getMockBooking(bookingId,
        userLocation: activeLoc.coordinates);
  }
  try {
    final api = ref.read(apiClientProvider);
    return await api.getBooking(bookingId);
  } catch (_) {
    return MockDataService.getMockBooking(bookingId,
        userLocation: activeLoc.coordinates);
  }
});

/// The booking currently flowing through create → pay → rate.
final activeBookingProvider = StateProvider<Booking?>((ref) => null);

/// Parameters for creating a real booking (flat payload per contract).
class NewBookingParams {
  final String serviceType;
  final double price;
  final double lat;
  final double lng;
  final String? description;
  final String? address;

  const NewBookingParams({
    required this.serviceType,
    required this.price,
    required this.lat,
    required this.lng,
    this.description,
    this.address,
  });
}

/// Creation state machine — creates real booking or seamless demo booking when offline.
class BookingCreationNotifier extends StateNotifier<AsyncValue<Booking?>> {
  BookingCreationNotifier(this._api) : super(const AsyncData(null));

  final ApiClient _api;

  Future<bool> create(NewBookingParams params) async {
    state = const AsyncLoading();
    try {
      if (useMockData) {
        await Future.delayed(const Duration(milliseconds: 400));
        final mockBooking = Booking(
          id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
          customerId: 'demo_customer',
          workerId: 'w1',
          workerName: 'Ramesh Kumar',
          serviceType: params.serviceType,
          status: BookingStatus.accepted,
          latitude: params.lat,
          longitude: params.lng,
          address: params.address ?? 'Current Location',
          price: params.price,
          description: params.description,
          createdAt: DateTime.now(),
        );
        MockDataService.inMemoryBookings.insert(0, mockBooking);
        state = AsyncData(mockBooking);
        return true;
      }

      try {
        final booking = await _api.createBooking(
          serviceType: params.serviceType,
          price: params.price,
          lat: params.lat,
          lng: params.lng,
          description: params.description,
          address: params.address,
        );
        state = AsyncData(booking);
        return true;
      } catch (e) {
        // If real API creation fails (e.g. server unreachable), fall back seamlessly to demo booking
        final mockBooking = Booking(
          id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
          customerId: 'demo_customer',
          workerId: 'w1',
          workerName: 'Ramesh Kumar',
          serviceType: params.serviceType,
          status: BookingStatus.accepted,
          latitude: params.lat,
          longitude: params.lng,
          address: params.address ?? 'Current Location',
          price: params.price,
          description: params.description,
          createdAt: DateTime.now(),
        );
        MockDataService.inMemoryBookings.insert(0, mockBooking);
        state = AsyncData(mockBooking);
        return true;
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  void reset() => state = const AsyncData(null);
}

final bookingCreationProvider =
    StateNotifierProvider<BookingCreationNotifier, AsyncValue<Booking?>>(
        (ref) {
  return BookingCreationNotifier(ref.read(apiClientProvider));
});

/// Live tracking worker details lookup
final workerSuggestionProvider =
    FutureProvider.family<Worker?, String>((ref, workerId) async {
  try {
    final api = ref.read(apiClientProvider);
    return await api.getWorkerProfile(workerId);
  } catch (_) {
    final workers = MockDataService.getMockWorkers();
    for (final w in workers) {
      if (w.id == workerId) return w;
    }
    return workers.firstOrNull;
  }
});

