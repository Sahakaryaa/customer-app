import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../models/worker.dart';
import '../models/booking.dart';

/// Base URL for the backend API (override with --dart-define=API_BASE_URL=...).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// Secure storage for JWT token.
const _storage = FlutterSecureStorage();
const _tokenKey = 'jwt_token';

/// Riverpod provider for the API client.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Thrown when rating an already-rated booking (backend 409).
class BookingAlreadyRatedException implements Exception {
  const BookingAlreadyRatedException();
  @override
  String toString() => 'This booking has already been rated.';
}

/// HTTP API client wrapping Dio with JWT auth interceptor.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // JWT auth interceptor — Bearer token attached to every request.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // 401 → clear token (session expired)
        if (error.response?.statusCode == 401) {
          _storage.delete(key: _tokenKey);
        }
        handler.next(error);
      },
    ));
  }

  // ──────────── Token Management ────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Human-friendly message from a Dio error.
  static String friendlyError(Object error) {
    if (error is BookingAlreadyRatedException) return error.toString();
    if (error is DioException) {
      final code = error.response?.statusCode;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Is the server reachable?';
        case DioExceptionType.connectionError:
          return 'Cannot reach the server. Check your connection.';
        default:
          break;
      }
      if (code != null) {
        if (code >= 500) return 'Server error ($code). Try again shortly.';
        final data = error.response?.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
        return 'Request failed ($code).';
      }
      return error.message ?? 'Unexpected network error.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// True when [error] is a transport-level failure (server unreachable /
  /// offline) as opposed to an HTTP rejection like 401/400. Only transport
  /// failures may fall back to demo mode.
  static bool isConnectionError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }

  // ──────────── Auth ────────────

  /// POST /auth/register {name, phone, password} → TokenResponse
  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'name': name,
      'password': password,
      'role': 'customer',
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// POST /auth/login {phone, password} → TokenResponse
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// GET /auth/me (Bearer) → UserResponse
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return User.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // ──────────── Workers ────────────

  /// GET /workers/nearby?lat&lng&service_type&max_distance_km → [WorkerResponse]
  Future<List<Worker>> getNearbyWorkers({
    required double lat,
    required double lng,
    String? serviceType,
  }) async {
    final response = await _dio.get('/workers/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      if (serviceType != null) 'service_type': serviceType,
    });
    final list = response.data as List;
    return list
        .map((e) => Worker.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /workers/{worker_id} → WorkerResponse (flat lat/lng)
  Future<Worker> getWorkerProfile(String workerId) async {
    final response = await _dio.get('/workers/$workerId');
    return Worker.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  // ──────────── Bookings ────────────

  /// POST /bookings — FLAT payload per contract:
  /// {service_type, description?, price, lat, lng, address?, worker_id?}
  /// When [workerId] is set (direct hire) the backend pins the booking to
  /// that specific worker instead of auto-matching.
  Future<Booking> createBooking({
    required String serviceType,
    required double price,
    required double lat,
    required double lng,
    String? description,
    String? address,
    String? workerId,
  }) async {
    final response = await _dio.post('/bookings', data: {
      'service_type': serviceType,
      'price': price,
      'lat': lat,
      'lng': lng,
      if (workerId != null && workerId.isNotEmpty) 'worker_id': workerId,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
    });
    return Booking.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// GET /bookings/{booking_id} → BookingResponse
  Future<Booking> getBooking(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId');
    return Booking.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// PATCH /bookings/{booking_id}/status {status}
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await _dio.patch('/bookings/$bookingId/status', data: {'status': status});
  }

  /// POST /bookings/{booking_id}/rate {rating, comment?}
  /// Throws [BookingAlreadyRatedException] on 409.
  Future<void> rateBooking({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post('/bookings/$bookingId/rate', data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const BookingAlreadyRatedException();
      }
      rethrow;
    }
  }

  /// GET /users/me/bookings → [BookingResponse]
  Future<List<Booking>> getBookingHistory() async {
    final response = await _dio.get('/users/me/bookings');
    final list = response.data as List;
    return list
        .map((e) => Booking.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
