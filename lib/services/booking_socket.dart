import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/booking.dart';
import 'api_client.dart';

/// Realtime status payload per contract:
/// {booking_id, old_status, new_status, timestamp}
class StatusUpdate {
  final String bookingId;
  final BookingStatus newStatus;
  final BookingStatus? oldStatus;
  final DateTime? timestamp;

  const StatusUpdate({
    required this.bookingId,
    required this.newStatus,
    this.oldStatus,
    this.timestamp,
  });
}

/// Worker location payload per contract:
/// {booking_id, worker_id, lat, lng, ts}
class WorkerPing {
  final String bookingId;
  final String? workerId;
  final double lat;
  final double lng;
  final DateTime? ts;

  const WorkerPing({
    required this.bookingId,
    required this.lat,
    required this.lng,
    this.workerId,
    this.ts,
  });
}

/// Riverpod provider for the realtime service.
final bookingSocketProvider = Provider<BookingRealtimeService>((ref) {
  final service = BookingRealtimeService(apiClient: ref.watch(apiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Live booking session over Socket.IO (namespace default, path /socket.io).
///
/// Contract events:
///   emit   `join_booking` {booking_id}
///   listen `status_update`   {booking_id, old_status, new_status, timestamp}
///   listen `location_update` {booking_id, worker_id, lat, lng, ts}
///
/// When the socket is disconnected, falls back to polling
/// GET /bookings/{id} every 5 seconds until the socket recovers.
class BookingRealtimeService {
  final ApiClient _api;
  io.Socket? _socket;
  Timer? _pollTimer;

  BookingRealtimeService({required ApiClient apiClient}) : _api = apiClient;

  final _statusController = StreamController<StatusUpdate>.broadcast();
  final _locationController = StreamController<WorkerPing>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  bool _connected = false;
  String? _activeBookingId;

  bool get isConnected => _connected;
  String? get activeBookingId => _activeBookingId;

  Stream<StatusUpdate> get statusStream => _statusController.stream;
  Stream<WorkerPing> get locationStream => _locationController.stream;

  /// Emits true/false as socket connection state changes.
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Connect + join the booking room. Safe to call repeatedly.
  void connect(String bookingId) {
    if (_activeBookingId == bookingId && _socket != null) return;
    disconnect();

    _activeBookingId = bookingId;

    try {
      _socket = io.io(
        kApiBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .enableReconnection()
            .setReconnectionDelay(1500)
            .build(),
      );

      _socket!.onConnect((_) {
        _setConnected(true);
        _socket!.emit('join_booking', {'booking_id': bookingId});
        _stopPolling(); // socket live — polling not needed
      });

      _socket!.onDisconnect((_) => _setConnected(false));
      _socket!.onConnectError((_) => _setConnected(false));

      _socket!.on('status_update', (data) {
        final json = _asMap(data);
        if (json == null) return;
        final id = json['booking_id']?.toString();
        if (id != null && id != bookingId) return;
        final statusVal = json['new_status']?.toString();
        if (statusVal == null) return;
        _statusController.add(StatusUpdate(
          bookingId: id ?? bookingId,
          newStatus: BookingStatus.fromString(statusVal),
          oldStatus: json['old_status']?.toString() != null
              ? BookingStatus.fromString(json['old_status'].toString())
              : null,
          timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
        ));
      });

      _socket!.on('location_update', (data) {
        final json = _asMap(data);
        if (json == null) return;
        final id = json['booking_id']?.toString();
        if (id != null && id != bookingId) return;
        final lat = (json['lat'] as num?)?.toDouble();
        final lng = (json['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;
        _locationController.add(WorkerPing(
          bookingId: id ?? bookingId,
          workerId: json['worker_id']?.toString(),
          lat: lat,
          lng: lng,
          ts: DateTime.tryParse(json['ts']?.toString() ?? ''),
        ));
      });
    } catch (_) {
      _setConnected(false);
    }

    // Defensive: start polling immediately in case the handshake stalls.
    _startPollingIfDisconnected();
  }

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  void _setConnected(bool connected) {
    if (_connected == connected) return;
    _connected = connected;
    if (!_connectionController.isClosed) {
      _connectionController.add(connected);
    }
    if (connected) {
      _stopPolling();
    } else {
      _startPollingIfDisconnected();
    }
  }

  /// Fallback: poll GET /bookings/{id} every 5s while the socket is down.
  void _startPollingIfDisconnected() {
    if (_pollTimer != null || _activeBookingId == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final id = _activeBookingId;
      if (id == null || _connected || _statusController.isClosed) return;
      try {
        final booking = await _api.getBooking(id);
        if (!_statusController.isClosed) {
          _statusController.add(StatusUpdate(
            bookingId: id,
            newStatus: booking.status,
            timestamp: DateTime.now(),
          ));
        }
      } catch (_) {
        // keep retrying silently; banner already shows reconnecting state
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Tear down socket + timers for the current session.
  void disconnect() {
    _stopPolling();
    try {
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _activeBookingId = null;
    if (_connected) {
      _connected = false;
      if (!_connectionController.isClosed) _connectionController.add(false);
    }
  }

  /// Full dispose when the provider tree dies.
  void dispose() {
    disconnect();
    _statusController.close();
    _locationController.close();
    _connectionController.close();
  }
}

/// Haversine distance in km between two coordinates.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _deg2rad(double deg) => deg * (math.pi / 180.0);

/// Initial bearing from point 1 → point 2, in degrees [0, 360).
double bearingDegrees(double lat1, double lng1, double lat2, double lng2) {
  final lat1r = _deg2rad(lat1);
  final lat2r = _deg2rad(lat2);
  final dLng = _deg2rad(lng2 - lng1);
  final y = math.sin(dLng) * math.cos(lat2r);
  final x = math.cos(lat1r) * math.sin(lat2r) -
      math.sin(lat1r) * math.cos(lat2r) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Interpolate along [points] at fraction t ∈ [0,1].
LatLng interpolateAlong(List<LatLng> points, double t) {
  if (points.isEmpty) return const LatLng(28.61, 77.21);
  if (points.length == 1) return points.first;
  final clamped = t.clamp(0.0, 1.0);
  final scaled = clamped * (points.length - 1);
  final idx = scaled.floor().clamp(0, points.length - 2);
  final frac = scaled - idx;
  final a = points[idx];
  final b = points[idx + 1];
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * frac,
    a.longitude + (b.longitude - a.longitude) * frac,
  );
}
