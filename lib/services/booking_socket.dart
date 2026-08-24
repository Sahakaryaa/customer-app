import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/booking.dart';

/// WebSocket base URL (matches the REST API host).
const String _wsBaseUrl = 'ws://10.0.2.2:8000';

/// Provider for the booking socket service.
final bookingSocketProvider = Provider<BookingSocketService>((ref) {
  return BookingSocketService();
});

/// Manages a WebSocket connection for live booking status updates.
/// Connects to /ws/bookings/{booking_id} and streams status changes.
class BookingSocketService {
  WebSocketChannel? _channel;
  StreamController<BookingStatus>? _controller;

  /// Connect to the booking status WebSocket and return a stream of status updates.
  Stream<BookingStatus> connect(String bookingId) {
    _controller = StreamController<BookingStatus>.broadcast();

    try {
      final uri = Uri.parse('$_wsBaseUrl/ws/bookings/$bookingId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final status = BookingStatus.fromString(json['status'] as String);
            _controller?.add(status);
          } catch (_) {
            // Ignore malformed messages
          }
        },
        onError: (error) {
          _controller?.addError(error);
        },
        onDone: () {
          _controller?.close();
        },
      );
    } catch (e) {
      _controller?.addError(e);
      _controller?.close();
    }

    return _controller!.stream;
  }

  /// Disconnect from the current WebSocket.
  void disconnect() {
    _channel?.sink.close();
    _controller?.close();
    _channel = null;
    _controller = null;
  }
}
