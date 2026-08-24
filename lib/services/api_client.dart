import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../models/worker.dart';
import '../models/booking.dart';

/// Base URL for the backend API.
/// Change this when the real backend is deployed.
const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost

/// Secure storage for JWT token.
const _storage = FlutterSecureStorage();
const _tokenKey = 'jwt_token';

/// Riverpod provider for the API client.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// HTTP API client wrapping Dio with JWT auth interceptor.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // JWT auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
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

  // ──────────── Auth ────────────

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
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  // ──────────── Workers ────────────

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
    return list.map((e) => Worker.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Worker> getWorkerProfile(String workerId) async {
    final response = await _dio.get('/workers/$workerId');
    return Worker.fromJson(response.data as Map<String, dynamic>);
  }

  // ──────────── Bookings ────────────

  Future<Booking> createBooking({
    required String serviceType,
    required double lat,
    required double lng,
    DateTime? scheduledTime,
    bool isEmergency = false,
  }) async {
    final response = await _dio.post('/bookings', data: {
      'service_type': serviceType,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
      if (scheduledTime != null)
        'scheduled_time': scheduledTime.toIso8601String(),
      'is_emergency': isEmergency,
    });
    return Booking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Booking> getBooking(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId');
    return Booking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> rateBooking({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post('/bookings/$bookingId/rate', data: {
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
  }

  Future<List<Booking>> getBookingHistory() async {
    final response = await _dio.get('/users/me/bookings');
    final list = response.data as List;
    return list
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────── User ────────────

  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
