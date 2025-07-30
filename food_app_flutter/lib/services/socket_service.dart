import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('https://food-app-cweu.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('✅ Socket connected');
    });

    socket.onConnectError((data) {
      print('❗ Connect error: $data');
    });

    socket.onError((data) {
      print('❌ Socket error: $data');
    });

    socket.onDisconnect((_) {
      print('🔌 Socket disconnected');
    });

    socket.on('order:update', (data) {
      print('📦 Order updated: $data');
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
