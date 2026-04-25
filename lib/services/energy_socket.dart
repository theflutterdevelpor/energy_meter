import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  String? _currentToken;

  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(false);

  bool get connected => connectionStatus.value;

  void connect(String token) {
    if (socket != null && socket!.connected && _currentToken == token) {
      debugPrint('✅ Socket already connected');
      return;
    }

    if (_currentToken != null && _currentToken != token) {
      disconnect();
    }

    _currentToken = token;
    debugPrint("🔄 Connecting to socket...");

    try {
      socket = IO.io(
        'http://3.231.62.206:5000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .setExtraHeaders({'access_token': token})
            .enableReconnection()
            .enableAutoConnect()
            .build(),
      );

      socket!.connect();

      socket!.onConnect((_) {
        connectionStatus.value = true;
        debugPrint('🟢 Socket connected: ${socket!.id}');
      });

      socket!.onDisconnect((_) {
        connectionStatus.value = false;
        debugPrint('🔴 Socket disconnected');
      });

      socket!.onConnectError((e) {
        connectionStatus.value = false;
        debugPrint('❌ Socket connection error: $e');
      });

      socket!.onError((e) {
        debugPrint('❌ Socket error: $e');
      });
    } catch (e) {
      debugPrint('❌ Exception in socket connection: $e');
    }
  }

  void disconnect() {
    socket?.clearListeners();
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    _currentToken = null;
    connectionStatus.value = false;
    debugPrint('🔌 Socket disconnected and disposed');
  }

  void on(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  void off(String event) {
    socket?.off(event);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  void onAny() {
    socket?.onAny((event, data) {
      debugPrint('📡 SOCKET EVENT => $event');
      debugPrint('📦 DATA => $data');
    });
  }
}