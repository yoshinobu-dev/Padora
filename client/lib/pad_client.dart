import 'dart:io';

import 'protocol.dart';

class PadClient {
  RawDatagramSocket? _socket;
  InternetAddress? _host;
  int _sequence = 0;

  bool get isReady => _socket != null && _host != null;

  Future<void> connect(String hostIp, {int port = PadoraProtocol.defaultPort}) async {
    await dispose();
    _host = InternetAddress(hostIp);
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;
    _port = port;
  }

  int _port = PadoraProtocol.defaultPort;

  void send(int buttonId, bool pressed) {
    final socket = _socket;
    final host = _host;
    if (socket == null || host == null) {
      return;
    }

    _sequence = (_sequence + 1) & 0xffff;
    final packet = PadoraProtocol.packet(buttonId, pressed, _sequence);
    socket.send(packet, host, _port);
  }

  Future<void> dispose() async {
    _socket?.close();
    _socket = null;
    _host = null;
  }
}
