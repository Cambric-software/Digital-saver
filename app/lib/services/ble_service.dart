import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_models.dart';

const String kServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String kHRCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String kBPCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a9';
const String kO2CharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
const String kAccelCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26ab';
const String kDeviceName = 'DigitalSaver';
const String kBatteryCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26ac';

// Keywords that indicate a smartwatch or fitness wearable
const List<String> kSmartwatchKeywords = [
  'watch', 'band', 'fitness', 'tracker', 'wearable', 'smart',
  'mi', 'huawei', 'samsung', 'garmin', 'fitbit', 'amazfit',
  'polar', 'xiaomi', 'honor', 'oppo', 'realme', 'oneplus',
  'digital', 'saver', 'esp32', 'health', 'heart', 'pulse',
  'health', 'medical', 'oximeter', 'bp', 'blood'
];

// Manufacturer IDs for common smartwatch/fitness brands
const List<int> kSmartwatchManufacturerIds = [
  0x004C, // Apple
  0x00E0, // Samsung
  0x0075, // Samsung (alternative)
  0x027A, // Xiaomi
  0x038F, // Xiaomi (alternative)
  0x0087, // Huawei
  0x009E, // Huawei (alternative)
  0x00D2, // Xiaomi (Mi Band)
  0x02E5, // Amazfit
  0x001D, // Garmin
  0x0059, // fitbit
];

enum BleState { disconnected, scanning, connecting, connected, error }

class DiscoveredDevice {
  final BluetoothDevice device;
  final String name;
  final int? rssi;
  final bool isSmartwatch;

  DiscoveredDevice({
    required this.device,
    required this.name,
    this.rssi,
    this.isSmartwatch = false,
  });
}

class BleService extends ChangeNotifier {
  BluetoothDevice? _device;
  BleState _state = BleState.disconnected;
  String _errorMessage = '';

  HeartRateData _heartRate = HeartRateData();
  BloodPressureData _bloodPressure = BloodPressureData();
  OxygenData _oxygen = OxygenData();
  AccelData _accel = AccelData();
  ActivityData _activity = ActivityData(hourlySteps: List.filled(24, 0));

  StreamSubscription? _scanSub;
  StreamSubscription? _hrSub;
  StreamSubscription? _bpSub;
  StreamSubscription? _o2Sub;
  StreamSubscription? _accelSub;

  // Demo mode: simulate data when no device is connected
  bool _demoMode = false;
  Timer? _demoTimer;

  // Watch battery level (0-100)
  int _batteryLevel = 0;
  DateTime? _lastBatteryUpdate;

  // Discovered devices list
  List<DiscoveredDevice> _discoveredDevices = [];

  BleState get state => _state;
  String get errorMessage => _errorMessage;
  HeartRateData get heartRate => _heartRate;
  BloodPressureData get bloodPressure => _bloodPressure;
  OxygenData get oxygen => _oxygen;
  AccelData get accel => _accel;
  ActivityData get activity => _activity;
  bool get isConnected => _state == BleState.connected;
  bool get demoMode => _demoMode;
  int get batteryLevel => _batteryLevel;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;

  int get healthScore {
    int score = 100;
    if (_heartRate.bpm > 0) {
      if (_heartRate.bpm < 60 || _heartRate.bpm > 100) score -= 15;
      if (_heartRate.afibProbability > 50) score -= 20;
    }
    if (_bloodPressure.systolic > 0) {
      if (_bloodPressure.systolic >= 140 || _bloodPressure.diastolic >= 90) score -= 20;
      else if (_bloodPressure.systolic >= 130) score -= 10;
    }
    if (_oxygen.spO2 > 0) {
      if (_oxygen.spO2 < 90) score -= 25;
      else if (_oxygen.spO2 < 95) score -= 10;
    }
    return score.clamp(0, 100);
  }

  // Check if a device is likely a smartwatch based on name and manufacturer data
  bool _isLikelySmartwatch(ScanResult result) {
    final name = result.device.platformName.toLowerCase();
    final manufacturerData = result.advertisementData.manufacturerData;

    // Check if name contains smartwatch keywords
    for (final keyword in kSmartwatchKeywords) {
      if (name.contains(keyword)) {
        return true;
      }
    }

    // Check manufacturer data for smartwatch brands
    for (final entry in manufacturerData.entries) {
      if (kSmartwatchManufacturerIds.contains(entry.key)) {
        return true;
      }
    }

    // Check for our specific service UUID (Digital Saver custom)
    if (result.advertisementData.serviceUuids.contains(Guid(kServiceUUID))) {
      return true;
    }

    // Check for heart rate service (common in smartwatches)
    if (result.advertisementData.serviceUuids.any((uuid) => 
        uuid.toString().toLowerCase().contains('180d'))) {
      return true;
    }

    return false;
  }

  Future<void> startScan() async {
    if (_state == BleState.scanning || _state == BleState.connected) return;
    
    _discoveredDevices = [];
    _setState(BleState.scanning);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
      
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty 
              ? r.device.platformName 
              : 'Unknown Device';
          
          final isSmartwatch = _isLikelySmartwatch(r);
          
          // Only add if not already in list and is likely a smartwatch
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.device.remoteId.str == r.device.remoteId.str
          );
          
          if (existingIndex == -1 && isSmartwatch) {
            _discoveredDevices.add(DiscoveredDevice(
              device: r.device,
              name: name,
              rssi: r.rssi,
              isSmartwatch: true,
            ));
            notifyListeners();
          }
        }
      });

      // Timeout
      await Future.delayed(const Duration(seconds: 20));
      if (_state == BleState.scanning) {
        await FlutterBluePlus.stopScan();
        _setState(BleState.disconnected);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BleState.error);
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (_state == BleState.scanning) {
      _setState(BleState.disconnected);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    await _connectToDevice(device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    _setState(BleState.connecting);
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _setState(BleState.connected);
      await _discoverServices(device);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BleState.error);
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid == Guid(kServiceUUID)) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == kHRCharUUID) {
            await char.setNotifyValue(true);
            _hrSub = char.onValueReceived.listen(_parseHeartRate);
          } else if (uuid == kBPCharUUID) {
            await char.setNotifyValue(true);
            _bpSub = char.onValueReceived.listen(_parseBloodPressure);
          } else if (uuid == kO2CharUUID) {
            await char.setNotifyValue(true);
            _o2Sub = char.onValueReceived.listen(_parseOxygen);
          } else if (uuid == kAccelCharUUID) {
            await char.setNotifyValue(true);
            _accelSub = char.onValueReceived.listen(_parseAccel);
          } else if (uuid == kBatteryCharUUID) {
            await char.setNotifyValue(true);
            _batterySub = char.onValueReceived.listen(_parseBattery);
          }
        }
      }
    }
  }

  StreamSubscription? _batterySub;

  void _parseBattery(List<int> data) {
    if (data.isNotEmpty) {
      _batteryLevel = data[0].clamp(0, 100);
      _lastBatteryUpdate = DateTime.now();
      notifyListeners();
    }
  }

  void _parseHeartRate(List<int> data) {
    if (data.length < 6) return;
    _heartRate = HeartRateData(
      bpm: data[0],
      confidence: data[1],
      hrv: data[2],
      afibProbability: data[3],
      status: data[4],
      rrIntervals: data.length > 6 ? data.sublist(6).map((v) => v).toList() : [],
    );
    notifyListeners();
  }

  void _parseBloodPressure(List<int> data) {
    if (data.length < 5) return;
    _bloodPressure = BloodPressureData(
      systolic: data[0],
      diastolic: data[1],
      map: data[2],
      pulsePressure: data[3],
      confidence: data[4],
    );
    notifyListeners();
  }

  void _parseOxygen(List<int> data) {
    if (data.length < 4) return;
    _oxygen = OxygenData(
      spO2: data[0],
      perfusionIndex: data[1],
      respirationRate: data[2],
      confidence: data[3],
    );
    notifyListeners();
  }

  void _parseAccel(List<int> data) {
    if (data.length < 4) return;
    final bytes = Uint8List.fromList(data);
    final bd = ByteData.sublistView(bytes);
    _accel = AccelData(
      x: bd.getInt16(0, Endian.little) / 16384.0,
      y: bd.getInt16(2, Endian.little) / 16384.0,
      z: bd.getInt16(4, Endian.little) / 16384.0,
      fallDetected: data.length > 6 ? data[6] == 1 : false,
      locSuspected: data.length > 7 ? data[7] == 1 : false,
    );
    if (_accel.fallDetected) {
      notifyListeners();
    }
  }

  void enableDemoMode() {
    _demoMode = true;
    _batteryLevel = 85;
    _setState(BleState.connected);
    _startDemoData();
  }

  void _startDemoData() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now();
      _heartRate = HeartRateData(
        bpm: 68 + (DateTime.now().second % 10),
        confidence: 92,
        hrv: 45 + (now.second % 20),
        sdnn: 52,
        pnn50: 28,
        afibProbability: 5,
        status: 0,
      );
      _bloodPressure = BloodPressureData(
        systolic: 118 + (now.second % 8),
        diastolic: 76 + (now.second % 5),
        map: 90,
        pulsePressure: 42,
        augmentationIndex: 18,
        pulseWaveVelocity: 6.5,
        confidence: 80,
      );
      _oxygen = OxygenData(
        spO2: 97 + (now.second % 3 == 0 ? 1 : 0),
        perfusionIndex: 8,
        respirationRate: 16,
        confidence: 85,
      );
      _activity = ActivityData(
        steps: 6248 + now.hour * 100,
        calories: 312,
        distanceKm: 4.2,
        activeMinutes: 42,
        hourlySteps: List.generate(24, (i) => i < now.hour ? (200 + i * 30) : 0),
      );
      notifyListeners();
    });
  }

  Future<void> disconnect() async {
    _demoTimer?.cancel();
    _demoMode = false;
    _batteryLevel = 0;
    _scanSub?.cancel();
    _hrSub?.cancel();
    _bpSub?.cancel();
    _o2Sub?.cancel();
    _accelSub?.cancel();
    _batterySub?.cancel();
    await _device?.disconnect();
    _device = null;
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
    _hrSub?.cancel();
    _bpSub?.cancel();
    _o2Sub?.cancel();
    _accelSub?.cancel();
    _batterySub?.cancel();
    super.dispose();
  }
}
