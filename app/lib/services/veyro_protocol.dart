/// BLE contract v1 — must match firmware/esp32/DigitalSaverWatch/protocol.h
class VeyroProtocol {
  static const int version = 1;
  static const String deviceName = 'Veyro';
  static const int retainDays = 60;

  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String liveUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String cmdUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26f0';
  static const String histUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a1';
  static const String infoUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a2';
}
