import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

typedef RealtimeHandler = void Function(String event, dynamic data);

/// WebSocket client for live DMs and notifications.
class RealtimeService {
  io.Socket? _socket;
  final _handlers = <String, List<RealtimeHandler>>{};

  static String get socketUrl {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return base;
  }

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    disconnect();
    _socket = io.io(
      '$socketUrl/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});

    for (final event in ['dm:new', 'notification:new', 'pong']) {
      _socket!.on(event, (data) {
        for (final h in _handlers[event] ?? []) {
          h(event, data);
        }
      });
    }
  }

  void disconnect() {
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
}
