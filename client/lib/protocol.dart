import 'dart:typed_data';

/// Padora UDP packet v1 (6 bytes).
class PadoraProtocol {
  static const int magic = 0x57; // 'W'
  static const int version = 1;
  static const int defaultPort = 21780;

  static const int buttonUp = 1;
  static const int buttonDown = 2;
  static const int buttonLeft = 3;
  static const int buttonRight = 4;
  static const int buttonConfirm = 10;
  static const int buttonCancel = 11;
  static const int buttonSub = 12;
  static const int buttonF4 = 20;
  static const int buttonF11 = 21;

  static Uint8List packet(int buttonId, bool pressed, int sequence) {
    final data = Uint8List(6);
    data[0] = magic;
    data[1] = version;
    data[2] = buttonId;
    data[3] = pressed ? 1 : 0;
    data[4] = sequence & 0xff;
    data[5] = (sequence >> 8) & 0xff;
    return data;
  }
}
