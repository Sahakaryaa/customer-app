import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/worker.dart';
import '../services/api_client.dart';
import '../services/mock_data_service.dart';
import 'auth_provider.dart';

/// Booking history provider (GET /users/me/bookings).
final bookingHistoryProvider = FutureProvider<List<Booking>>((ref) async {
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockDataService.getMockBookingHistory();
  }
  final api = ref.read(apiClientProvider);
  return api.getBookingHistory();
});

/// Single booking fetch (GET /bookings/{id}).
final bookingDetailProvider =
    FutureProvider.family.autoDispose<Booking, String>((ref, bookingId) async {
  final api = ref.read(apiClientProvider);
  return api.getBooking(bookingId);
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

/// Creation state machine — never silently succeeds; errors are surfaced.
class BookingCreationNotifier extends StateNotifier<AsyncValue<Booking?>> {
  BookingCreationNotifier(this._api) : super(const AsyncData(null));

  final ApiClient _api;

  Future<bool> create(NewBookingParams params) async {
    state = const AsyncLoading();
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
      state = AsyncError(e, StackTrace.current);
      return false;
    } finally {
      // keep last state; screens read it via valueOrNull / hasError
    }
  }

  void reset() => state = const AsyncData(null);
}

final bookingCreationProvider =
    StateNotifierProvider<BookingCreationNotifier, AsyncValue<Booking?>>(
        (ref) {
  return BookingCreationNotifier(ref.read(apiClientProvider));
});

/// Live tracking status stream for a booking — Socket.IO `status_update`
/// events with automatic polling fallback handled by [BookingRealtimeService].
/// (See services/booking_socket.dart.)
///
/// Kept as a thin alias so screens can watch statuses reactively.
final workerSuggestionProvider =
    FutureProvider.family<Worker?, String>((ref, workerId) async {
  try {
    final api = ref.read(apiClientProvider);
    return await api.getWorkerProfile(workerId);
  } catch (_) {
    return null;
  }
});
