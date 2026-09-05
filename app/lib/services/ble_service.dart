import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/health_models.dart';
import 'app_lock.dart';
import 'local_store.dart';
import 'veyro_protocol.dart';

enum BleState { disconnected, scanning, connecting, connected, error }

class DiscoveredDevice {
  final BluetoothDevice device;
  final String name;
  final int? rssi;
  final bool isVeyro;

  DiscoveredDevice({
    required this.device,
    required this.name,
    this.rssi,
    this.isVeyro = false,
  });
}

class WatchInfo {
  final String fw;
  final bool paired;
  final int samples;
  final int freeKb;
  final int battery;

  WatchInfo({
    this.fw = '',
    this.paired = false,
    this.samples = 0,
    this.freeKb = 0,
    this.battery = 0,
  });
}

class BleService extends ChangeNotifier {
  BluetoothDevice? _device;
  BleState _state = BleState.disconnected;
  String _errorMessage = '';
  List<DiscoveredDevice> _discoveredDevices = [];

  HeartRateData _heartRate = HeartRateData();
  BloodPressureData _bloodPressure = BloodPressureData();
  OxygenData _oxygen = OxygenData();
  ActivityData _activity = ActivityData(hourlySteps: List.filled(24, 0));
  AccelData _accel = AccelData();

  StreamSubscription? _scanSub;
  StreamSubscription? _liveSub;
  StreamSubscription? _histSub;
  BluetoothCharacteristic? _cmd;
  BluetoothCharacteristic? _info;

  bool _demoMode = false;
  Timer? _demoTimer;
  int _batteryLevel = 0;
  WatchInfo _watchInfo = WatchInfo();
  bool _syncingMemory = false;
  int _memoryRows = 0;
  AppLock? _lock;

  void attachLock(AppLock lock) => _lock = lock;

  BleState get state => _state;
  String get errorMessage => _errorMessage;
  HeartRateData get heartRate => _heartRate;
  BloodPressureData get bloodPressure => _bloodPressure;
  OxygenData get oxygen => _oxygen;
  AccelData get accel => _accel;
  ActivityData get activity => _activity;
  bool get isConnected => _state == BleState.connected;
  bool get demoMode => _demoMode;
  double get temperature => 0;
  int get batteryLevel => _batteryLevel;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;
  WatchInfo get watchInfo => _watchInfo;
  bool get syncingMemory => _syncingMemory;
  int get memoryRows => _memoryRows;

  int get healthScore {
    int score = 100;
    if (_heartRate.bpm > 0) {
      if (_heartRate.bpm < 50 || _heartRate.bpm > 110) score -= 10;
    }
    if (_oxygen.spO2 > 0 && _oxygen.spO2 < 92) score -= 15;
    if (_accel.fallDetected) score -= 20;
    return score.clamp(0, 100);
  }

  Future<void> _perms() async {
    if (kIsWeb) return;
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> startScan() async {
    if (_state == BleState.scanning) return;
    _discoveredDevices = [];
    _setState(BleState.scanning);
    try {
      await _perms();
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        _errorMessage = 'Turn Bluetooth on';
        _setState(BleState.error);
        return;
      }
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty ? r.device.platformName : '';
          if (name.isEmpty) continue;
          final veyro = name.toLowerCase() == 'veyro' ||
              r.advertisementData.serviceUuids.any(
                (u) => u.toString().toLowerCase().contains(VeyroProtocol.serviceUuid.substring(0, 8)),
              );
          final i = _discoveredDevices.indexWhere((d) => d.device.remoteId.str == r.device.remoteId.str);
          if (i == -1) {
            _discoveredDevices.add(DiscoveredDevice(
              device: r.device,
              name: name,
              rssi: r.rssi,
              isVeyro: veyro,
            ));
            notifyListeners();
          }
        }
      });
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BleState.error);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    if (_state == BleState.scanning) _setState(BleState.disconnected);
  }

  Future<void> connectToDevice(BluetoothDevice device, {String? pin}) async {
    await stopScan();
    _device = device;
    _setState(BleState.connecting);
    try {
      await device.connect(timeout: const Duration(seconds: 20));
      _setState(BleState.connected);
      await _wire(device, pin: pin);
    } catch (e) {
      _errorMessage = 'Connection failed';
      _setState(BleState.error);
    }
  }

  Future<void> _wire(BluetoothDevice device, {String? pin}) async {
    final services = await device.discoverServices();
    for (final s in services) {
      if (!s.uuid.toString().toLowerCase().contains('4fafc201')) continue;
      for (final c in s.characteristics) {
        final id = c.uuid.toString().toLowerCase();
        if (id.contains('26a8')) {
          await c.setNotifyValue(true);
          _liveSub = c.lastValueStream.listen(_onLive);
        } else if (id.contains('26a1')) {
          await c.setNotifyValue(true);
          _histSub = c.lastValueStream.listen(_onHist);
        } else if (id.contains('26a2')) {
          _info = c;
          await _readInfo();
        } else if (id.contains('26f0')) {
          _cmd = c;
        }
      }
    }
    await _sendCmd({'op': 'time', 'unix': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000});
    final stored = pin ?? await _lock?.watchPin();
    if (stored != null && stored.length == 6) {
      await _sendCmd({'op': 'pair', 'pin': stored});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _readInfo();
      if (_watchInfo.paired) {
        await _lock?.saveWatchPin(stored);
        await startMemorySync();
      }
    }
  }

  Future<void> _readInfo() async {
    if (_info == null) return;
    try {
      final v = await _info!.read();
      final m = jsonDecode(utf8.decode(v)) as Map<String, dynamic>;
      _watchInfo = WatchInfo(
        fw: '${m['fw'] ?? ''}',
        paired: m['paired'] == true,
        samples: (m['samples'] as num?)?.toInt() ?? 0,
        freeKb: (m['free_kb'] as num?)?.toInt() ?? 0,
        battery: (m['bat'] as num?)?.toInt() ?? 0,
      );
      if (_watchInfo.battery > 0) _batteryLevel = _watchInfo.battery;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> pairWithPin(String pin) async {
    await _sendCmd({'op': 'pair', 'pin': pin});
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _readInfo();
    if (_watchInfo.paired) {
      await _lock?.saveWatchPin(pin);
      await startMemorySync();
    } else {
      _errorMessage = 'Wrong PIN. Read the 6 digits on the watch face.';
      notifyListeners();
    }
  }

  Future<void> startMemorySync() async {
    if (_cmd == null || _syncingMemory) return;
    _syncingMemory = true;
    _memoryRows = 0;
    notifyListeners();
    await _sendCmd({'op': 'sync'});
  }

  Future<void> setWatchFace(int face) async {
    if (!isConnected || face < 0 || face > 7) return;
    await _sendCmd({'op': 'face', 'face': face});
  }

  Future<void> _sendCmd(Map<String, dynamic> body) async {
    if (_cmd == null) return;
    await _cmd!.write(utf8.encode(jsonEncode(body)), withoutResponse: false);
  }

  void _onLive(List<int> value) {
    if (value.isEmpty) return;
    try {
      final m = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
      _heartRate = HeartRateData(
        bpm: (m['hr'] as num?)?.toInt() ?? 0,
        hrv: (m['hrv'] as num?)?.toInt() ?? 0,
        confidence: 60,
      );
      _oxygen = OxygenData(spO2: (m['spo2'] as num?)?.toInt() ?? 0, confidence: 50);
      _bloodPressure = BloodPressureData(
        systolic: (m['bps'] as num?)?.toInt() ?? 0,
        diastolic: (m['bpd'] as num?)?.toInt() ?? 0,
      );
      _activity = ActivityData(steps: (m['steps'] as num?)?.toInt() ?? 0, hourlySteps: List.filled(24, 0));
      _accel = AccelData(fallDetected: m['fall'] == 1);
      _batteryLevel = (m['bat'] as num?)?.toInt() ?? _batteryLevel;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _onHist(List<int> value) async {
    if (value.isEmpty) return;
    try {
      final m = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
      if (m['done'] == 1) {
        _syncingMemory = false;
        notifyListeners();
        return;
      }
      final row = m['row']?.toString();
      if (row != null) {
        await LocalStore.ingestCsvRow(row);
        _memoryRows++;
        notifyListeners();
      }
      await _sendCmd({'op': 'next'});
    } catch (_) {
      _syncingMemory = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _liveSub?.cancel();
    await _histSub?.cancel();
    await _device?.disconnect();
    _device = null;
    _cmd = null;
    _info = null;
    _setState(BleState.disconnected);
  }

  void startDemo() {
    _demoMode = true;
    _setState(BleState.connected);
    _batteryLevel = 76;
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _heartRate = HeartRateData(bpm: 68 + DateTime.now().second % 8, hrv: 42, confidence: 80);
      _oxygen = OxygenData(spO2: 97, confidence: 70);
      notifyListeners();
    });
  }

  void enableDemoMode() => startDemo();

  void stopDemo() {
    _demoTimer?.cancel();
    _demoMode = false;
    _setState(BleState.disconnected);
  }

  void _setState(BleState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _scanSub?.cancel();
    _liveSub?.cancel();
    _histSub?.cancel();
    super.dispose();
  }
}
