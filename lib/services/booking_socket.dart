import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/service_region.dart';
import '../models/booking.dart';
import 'api_client.dart';

/// One chat message exchanged inside a booking room
/// (customer ↔ worker, mirrored after Uber/Rapido trip chat).
class ChatMessage {
  final String bookingId;
  final String senderRole; // 'customer' | 'worker'
  final String text;
  final DateTime? ts;

  const ChatMessage({
    required this.bookingId,
    required this.senderRole,
    required this.text,
    this.ts,
  });
}

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
  final _chatController = StreamController<ChatMessage>.broadcast();

  bool _connected = false;
  String? _activeBookingId;

  /// Demo-mode simulation state (reset per booking).
  double? _simStartLat;
  double? _simStartLng;
  double _simProgress = 0.0;
  int _simTick = 0;

  bool get isConnected => _connected;
  String? get activeBookingId => _activeBookingId;

  Stream<StatusUpdate> get statusStream => _statusController.stream;
  Stream<WorkerPing> get locationStream => _locationController.stream;

  /// Emits true/false as socket connection state changes.
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Emits incoming chat messages for the active booking room.
  Stream<ChatMessage> get chatStream => _chatController.stream;

  /// Connect + join the booking room. Safe to call repeatedly.
  /// The JWT travels in the handshake auth payload — the server refuses
  /// unauthenticated sockets, so we resolve the token before connecting.
  void connect(String bookingId) {
    if (_activeBookingId == bookingId && _socket != null) return;
    disconnect();

    _activeBookingId = bookingId;

    try {
      _api.getToken().then((token) {
        if (_activeBookingId != bookingId || _socket != null) return;
        _openSocket(bookingId, token);
      });
    } catch (_) {
      _setConnected(false);
    }

    // Defensive: start polling immediately in case the handshake stalls.
    _startPollingIfDisconnected();
  }

  void _openSocket(String bookingId, String? token) {
    try {
      _socket = io.io(
        kApiBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .setAuth({'token': token})
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

      // Customer ↔ worker trip chat, relayed by the backend booking room.
      _socket!.on('chat_message', (data) {
        final json = _asMap(data);
        if (json == null) return;
        final id = json['booking_id']?.toString();
        if (id != null && id != bookingId) return;
        final text = json['message']?.toString() ??
            json['text']?.toString() ??
            '';
        if (text.isEmpty) return;
        _chatController.add(ChatMessage(
          bookingId: id ?? bookingId,
          senderRole: json['sender_role']?.toString() ?? 'worker',
          text: text,
          ts: DateTime.tryParse(json['ts']?.toString() ?? '') ??
              DateTime.now(),
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

  /// Send a chat message into the active booking room.
  /// Returns false when the socket is down (caller should fall back to
  /// the local demo simulation so chat still works offline).
  bool sendChatMessage(String text, {String senderRole = 'customer'}) {
    final bookingId = _activeBookingId;
    final trimmed = text.trim();
    if (_socket == null || !_connected || bookingId == null) return false;
    _socket!.emit('chat_message', {
      'booking_id': bookingId,
      'message': trimmed,
      'sender_role': senderRole,
      'ts': DateTime.now().toIso8601String(),
    });
    return true;
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

  /// Fallback: poll GET /bookings/{id} every 5s while the socket is down, or run live demo simulation.
  void _startPollingIfDisconnected() {
    if (_pollTimer != null || _activeBookingId == null) return;

    // Reset per-session simulation state.
    _simStartLat = null;
    _simStartLng = null;
    _simProgress = 0.0;
    _simTick = 0;

    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      final id = _activeBookingId;
      if (id == null || _statusController.isClosed) return;

      if (_connected) {
        _stopPolling();
        return;
      }

      _simTick++;

      // In offline / demo mode, simulate live worker connection & movement
      try {
        final booking = await _api.getBooking(id);
        if (!_statusController.isClosed) {
          _statusController.add(StatusUpdate(
            bookingId: id,
            newStatus: booking.status,
            timestamp: DateTime.now(),
          ));
        }
        // Real backend reachable: seed sim target from the booking's actual
        // service address so any simulated motion stays geographically sane.
        if (booking.latitude != 0 || booking.longitude != 0) {
          _simTargetLat = booking.latitude;
          _simTargetLng = booking.longitude;
        }
      } catch (_) {
        // Backend offline -> run live demo simulation.
        // The simulated worker converges on the CUSTOMER'S CURRENT LOCATION
        // (never a hardcoded city — fixes map-jumping bug).
        final targetLat = _simTargetLat;
        final targetLng = _simTargetLng;

        // First tick without a known target: wait for the UI to provide one
        // via [setSimulationTarget] before emitting pings.
        if (targetLat == null || targetLng == null) return;

        // Start ~1.1km NE of the customer so the approach reads naturally.
        _simStartLat ??= targetLat + 0.0072;
        _simStartLng ??= targetLng + 0.0068;

        if (_simTick >= 2 && !_connectionController.isClosed) {
          _connectionController.add(true);
        }

        _simProgress = math.min(1.0, _simProgress + 0.06);
        final ease = Curves.easeInOut.transform(_simProgress);
        final currentLat =
            _simStartLat! + (targetLat - _simStartLat!) * ease;
        final currentLng =
            _simStartLng! + (targetLng - _simStartLng!) * ease;

        if (!_locationController.isClosed) {
          _locationController.add(WorkerPing(
            bookingId: id,
            workerId: 'w1',
            lat: currentLat,
            lng: currentLng,
            ts: DateTime.now(),
          ));
        }

        // Timeline simulation
        if (!_statusController.isClosed) {
          BookingStatus simulatedStatus;
          if (_simTick < 3) {
            simulatedStatus = BookingStatus.accepted;
          } else if (_simTick < 10) {
            simulatedStatus = BookingStatus.enRoute;
          } else if (_simTick < 14) {
            simulatedStatus = BookingStatus.arrived;
          } else if (_simTick < 18) {
            simulatedStatus = BookingStatus.started;
          } else {
            simulatedStatus = BookingStatus.completed;
          }

          _statusController.add(StatusUpdate(
            bookingId: id,
            newStatus: simulatedStatus,
            timestamp: DateTime.now(),
          ));
        }
      }
    });
  }

  /// Demo-mode convergence target. The tracking screen sets this from the
  /// user's active location so offline simulations stay around the user.
  double? _simTargetLat;
  double? _simTargetLng;

  void setSimulationTarget(LatLng customerLocation) {
    _simTargetLat = customerLocation.latitude;
    _simTargetLng = customerLocation.longitude;
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
    _simStartLat = null;
    _simStartLng = null;
    _simProgress = 0.0;
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
    _chatController.close();
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
  if (points.isEmpty) return ServiceRegion.defaultCenter;
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
