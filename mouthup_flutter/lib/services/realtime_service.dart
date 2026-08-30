import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

typedef RealtimeHandler = void Function(String event, dynamic data);

/// WebSocket client for live feed, DMs, notifications, and profile updates.
class RealtimeService {
  io.Socket? _socket;
  final _handlers = <String, List<RealtimeHandler>>{};
  String? _token;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;

  static String get socketUrl {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return base;
  }

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    _token = accessToken;
    _manualDisconnect = false;
    _reconnectAttempt = 0;
    _connectInternal();
  }

  void _connectInternal() {
    final token = _token;
    if (token == null || token.isEmpty) return;

    _reconnectTimer?.cancel();
    _socket?.dispose();

    _socket = io.io(
      '$socketUrl/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _reconnectAttempt = 0;
      _dispatch('connect', null);
    });

    _socket!.onDisconnect((_) {
      _dispatch('disconnect', null);
      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onConnectError((_) {
      if (!_manualDisconnect) _scheduleReconnect();
    });

    for (final event in [
      'dm:new',
      'notification:new',
      'feed:new',
      'feed:updated',
      'feed:removed',
      'profile:updated',
      'follow:new',
      'pong',
    ]) {
      _socket!.on(event, (data) => _dispatch(event, data));
    }
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _token == null) return;
    _reconnectTimer?.cancel();
    final seconds = 2 << _reconnectAttempt.clamp(0, 4);
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), _connectInternal);
  }

  void _dispatch(String event, dynamic data) {
    for (final h in _handlers[event] ?? []) {
      h(event, data);
    }
  }

  void disconnect() {
    _manualDisconnect = true;
    _token = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, RealtimeHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void off(String event, RealtimeHandler handler) {
    _handlers[event]?.remove(handler);
  }

  void joinDm(String peer) {
    _socket?.emit('dm:join', {'peer': peer});
  }

  void setCity(String? city) {
    _socket?.emit('city:join', {'city': city});
  }

  void ping() {
    _socket?.emit('ping');
  }
}
