import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_models.dart';

// Temperature data class for BLE
class _TemperatureData {
  double temperature;
  int confidence;
  _TemperatureData({this.temperature = 0, this.confidence = 0});
}

// Accelerometer data class for BLE parsing
class _AccelRawData {
  double x, y, z;
  bool fallDetected;
  _AccelRawData({this.x = 0, this.y = 0, this.z = 0, this.fallDetected = false});
}

// Standard Bluetooth UUIDs for health devices
const String kHeartRateServiceUUID = '180d';
const String kBloodPressureServiceUUID = '1810';
const String kOxygenServiceUUID = '1816';
const String kBatteryServiceUUID = '180f';
const String kDeviceInfoServiceUUID = '180a';

// Custom service UUID
const String kServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String kHRCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String kBPCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a9';
const String kO2CharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
const String kStepsCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26ab';
const String kAccelCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26ac';
const String kTempCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26ae';

// Keywords for smartwatch detection - more inclusive
const List<String> kSmartwatchKeywords = [
  'watch', 'band', 'fitness', 'tracker', 'wearable', 'smart', 'aktivita',
  'mi', 'xiaomi', 'redmi', 'huawei', 'samsung', 'garmin', 'fitbit', 'amazfit',
  'polar', 'honor', 'oppo', 'realme', 'oneplus', 'haylou', 'zebl', 'hawiwi',
  'apple', 'watch', 'stratos', 'tread', 'pace', 'ignite', 'charge', 'versa',
  'galaxy', 'gear', 'vivo', 'lite', 'pro', 'ultra', 'max', 'plus',
];

enum BleState { disconnected, scanning, connecting, connected, error }

class DiscoveredDevice {
  final BluetoothDevice device;
  final String name;
  final int? rssi;
  final bool isSmartwatch;
  final List<String> services;

  DiscoveredDevice({
    required this.device,
    required this.name,
    this.rssi,
    this.isSmartwatch = false,
    this.services = const [],
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
  _TemperatureData _temperature = _TemperatureData();

  StreamSubscription? _scanSub;
  StreamSubscription? _hrSub;
  StreamSubscription? _bpSub;
  StreamSubscription? _o2Sub;
  StreamSubscription? _batterySub;
  StreamSubscription? _tempSub;
  StreamSubscription? _stepsSub;
  StreamSubscription? _accelSub;

  // Demo mode
  bool _demoMode = false;
  Timer? _demoTimer;
  int _batteryLevel = 0;

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
  double get temperature => _temperature.temperature;
  int get temperatureConfidence => _temperature.confidence;
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

  bool _isSmartwatch(String name, List<ScanResult> results) {
    final lowerName = name.toLowerCase();
    
    // Check name
    for (final keyword in kSmartwatchKeywords) {
      if (lowerName.contains(keyword)) return true;
    }
    
    // Check services
    for (final r in results) {
      for (final uuid in r.advertisementData.serviceUuids) {
        final s = uuid.toString().toLowerCase();
        if (s.contains('180d') || s.contains('1810') || s.contains('1816')) {
          return true;
        }
      }
    }
    
    return false;
  }

  Future<void> startScan() async {
    if (_state == BleState.scanning) return;

    _discoveredDevices = [];
    _setState(BleState.scanning);

    try {
      // Request Bluetooth permissions
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first;
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown';
          
          if (name == 'Unknown') continue;
          
          final isSw = _isSmartwatch(name, results);
          
          // Add if smartwatch OR has health services
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.device.remoteId.str == r.device.remoteId.str
          );
          
          if (existingIndex == -1) {
            _discoveredDevices.add(DiscoveredDevice(
              device: r.device,
              name: name,
              rssi: r.rssi,
              isSmartwatch: isSw,
            ));
            notifyListeners();
          }
        }
      });

      // Stop after timeout
      await Future.delayed(const Duration(seconds: 15));
      if (_state == BleState.scanning) {
        await stopScan();
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
    _device = device;
    _setState(BleState.connecting);
    
    try {
      await device.connect(timeout: const Duration(seconds: 20));
      _setState(BleState.connected);
      await _discoverServices(device);
    } catch (e) {
      _errorMessage = 'Connection failed: ${e.toString()}';
      _setState(BleState.error);
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      
      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        
        // Heart Rate Service
        if (serviceUuid.contains('180d')) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().contains('2a37')) {
              await char.setNotifyValue(true);
              _hrSub = char.onValueReceived.listen(_parseHeartRate);
              break;
            }
          }
        }
        
        // Blood Pressure Service
        if (serviceUuid.contains('1810')) {
          for (final char in service.characteristics) {
            final uuid = char.uuid.toString().toLowerCase();
            if (uuid.contains('2a35') || uuid.contains('2a36')) {
              await char.setNotifyValue(true);
              _bpSub = char.onValueReceived.listen(_parseBloodPressure);
              break;
            }
          }
        }
        
        // SpO2 Service
        if (serviceUuid.contains('1816')) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().contains('2a5f')) {
              await char.setNotifyValue(true);
              _o2Sub = char.onValueReceived.listen(_parseOxygen);
              break;
            }
          }
        }
        
        // Battery Service
        if (serviceUuid.contains('180f')) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().contains('2a19')) {
              await char.setNotifyValue(true);
              _batterySub = char.onValueReceived.listen(_parseBattery);
              break;
            }
          }
        }
        
        // Temperature Service (custom)
        if (serviceUuid.contains(kServiceUUID)) {
          for (final char in service.characteristics) {
            final uuidLower = char.uuid.toString().toLowerCase();
            if (uuidLower.contains('beb5483e-36e1-4688-b7f5-ea07361b26ae')) {
              await char.setNotifyValue(true);
              _tempSub = char.onValueReceived.listen(_parseTemperature);
              break;
            }
          }
        }
        
        // Steps/Activity Service (custom)
        if (serviceUuid.contains(kServiceUUID)) {
          for (final char in service.characteristics) {
            final uuidLower = char.uuid.toString().toLowerCase();
            if (uuidLower.contains('beb5483e-36e1-4688-b7f5-ea07361b26ab')) {
              await char.setNotifyValue(true);
              _stepsSub = char.onValueReceived.listen(_parseSteps);
              break;
            }
          }
        }
        
        // Accelerometer Service (custom)
        if (serviceUuid.contains(kServiceUUID)) {
          for (final char in service.characteristics) {
            final uuidLower = char.uuid.toString().toLowerCase();
            if (uuidLower.contains('beb5483e-36e1-4688-b7f5-ea07361b26ac')) {
              await char.setNotifyValue(true);
              _accelSub = char.onValueReceived.listen(_parseAccelerometer);
              break;
            }
          }
        }
      }
      
      // Start demo data if no real services found
      if (_hrSub == null && _bpSub == null && _o2Sub == null) {
        _startSimulatedData();
      }
    } catch (e) {
      _errorMessage = 'Service discovery failed';
      // Continue with simulated data
      _startSimulatedData();
    }
  }

  void _startSimulatedData() {
    _demoMode = true;
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final now = DateTime.now();
      _heartRate = HeartRateData(
        bpm: 70 + (now.second % 12),
        confidence: 90,
        hrv: 42,
        sdnn: 55,
        pnn50: 25,
        afibProbability: 3,
        status: 0,
      );
      _bloodPressure = BloodPressureData(
        systolic: 120 + (now.second % 6),
        diastolic: 78 + (now.second % 4),
        map: 92,
        pulsePressure: 42,
        augmentationIndex: 15,
        pulseWaveVelocity: 6.2,
        confidence: 85,
      );
      _oxygen = OxygenData(
        spO2: 97,
        perfusionIndex: 7,
        respirationRate: 16,
        confidence: 90,
      );
      _activity = ActivityData(
        steps: 5800 + now.hour * 120,
        calories: 285,
        distanceKm: 3.9,
        activeMinutes: 38,
        hourlySteps: List.generate(24, (i) => i < now.hour ? (150 + i * 25) : 0),
      );
      // Simulated temperature (normal body temperature)
      _temperature = _TemperatureData(
        temperature: 36.5 + (now.second % 10) * 0.01,  // Slight variation
        confidence: 85,
      );
      // Simulated accelerometer data (standing still)
      _accel = AccelData(
        x: 0.0,
        y: 0.0,
        z: 1.0,  // ~1g when standing still
        fallDetected: false,
        locSuspected: false,
      );
      notifyListeners();
    });
  }

  void _parseBattery(List<int> data) {
    if (data.isEmpty) return;
    _batteryLevel = data[0].clamp(0, 100);
    notifyListeners();
  }

  void _parseHeartRate(List<int> data) {
    if (data.isEmpty) return;
    
    // First byte is flags
    final flags = data[0];
    
    // Check minimum length for 8-bit HR
    if (data.length < 2) return;
    final is16Bit = (flags & 0x01) != 0;
    
    int bpm;
    if (is16Bit && data.length >= 3) {
      bpm = data[1] | (data[2] << 8);
    } else {
      bpm = data[1];
    }
    
    _heartRate = HeartRateData(
      bpm: bpm,
      confidence: 92,
      hrv: 45,
      sdnn: 52,
      pnn50: 28,
      afibProbability: 5,
      status: 0,
    );
    notifyListeners();
  }

  void _parseBloodPressure(List<int> data) {
    // IEEE 11073 format requires at least 7 bytes
    if (data.length < 7) return;
    
    final systolic = data.length > 2 ? (data[1] | (data[2] << 8)) : 0;
    final diastolic = data.length > 6 ? (data[5] | (data[6] << 8)) : 0;
    
    _bloodPressure = BloodPressureData(
      systolic: systolic,
      diastolic: diastolic,
      map: (systolic + 2 * diastolic) ~/ 3,
      pulsePressure: systolic - diastolic,
      confidence: 85,
    );
    notifyListeners();
  }

  void _parseOxygen(List<int> data) {
    if (data.length < 2) return;
    
    _oxygen = OxygenData(
      spO2: data[1].clamp(0, 100),  // Ensure SpO2 is in valid range
      perfusionIndex: data.length > 2 ? data[2] : 8,
      respirationRate: data.length > 3 ? data[3] : 16,
      confidence: 90,
    );
    notifyListeners();
  }


  void _parseTemperature(List<int> data) {
    if (data.length < 2) return;

    // Temperature data format from watch:
    // data[0]: flags/status
    // data[1..2] or data[1]: temperature value (in 0.1 degrees Celsius)
    // Example: 365 = 36.5°C
    int tempRaw;
    if (data.length >= 3) {
      tempRaw = data[1] | (data[2] << 8);
    } else {
      tempRaw = data[1];
    }
    
    // Convert from 0.1°C to °C
    double tempCelsius = tempRaw / 10.0;
    
    _temperature = _TemperatureData(
      temperature: tempCelsius,
      confidence: data.length > 3 ? data[3] : 85,
    );
    notifyListeners();
  }

  void _parseSteps(List<int> data) {
    if (data.length < 4) return;

    // Steps data format from watch:
    // data[0-3]: steps (32-bit integer)
    int steps = data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
    
    // Update activity data with steps
    final now = DateTime.now();
    final hourlySteps = List<int>.from(_activity.hourlySteps);
    if (now.hour < hourlySteps.length) {
      hourlySteps[now.hour] = steps;
    }
    
    _activity = ActivityData(
      steps: steps,
      calories: _activity.calories,
      distanceKm: _activity.distanceKm,
      activeMinutes: _activity.activeMinutes,
      hourlySteps: hourlySteps,
    );
    notifyListeners();
  }

  void _parseAccelerometer(List<int> data) {
    if (data.length < 7) return;

    // Accelerometer data format from watch:
    // data[0-2]: x axis (16-bit signed integer, little endian)
    // data[3-5]: y axis (16-bit signed integer, little endian)
    // data[6-8]: z axis (16-bit signed integer, little endian)
    // data[9]: fall detection flag
    int xRaw = data[0] | (data[1] << 8);
    int yRaw = data[2] | (data[3] << 8);
    int zRaw = data[4] | (data[5] << 8);
    
    // Convert to signed values (handle negative numbers)
    int x = xRaw > 32767 ? xRaw - 65536 : xRaw;
    int y = yRaw > 32767 ? yRaw - 65536 : yRaw;
    int z = zRaw > 32767 ? zRaw - 65536 : zRaw;
    
    // Convert raw values to G (assuming ±2g range, 16-bit ADC)
    double xG = x / 16384.0;
    double yG = y / 16384.0;
    double zG = z / 16384.0;
    
    // Fall detection flag (bit 0)
    bool fallDetected = (data.length > 6 && (data[6] & 0x01) != 0);
    
    // Detect fall based on acceleration magnitude (threshold: ~3g for fall)
    double magnitude = (xG * xG + yG * yG + zG * zG);
    if (magnitude > 9.0 || magnitude < 1.0) {  // >3g or <1g (free fall)
      fallDetected = true;
    }
    
    _accel = AccelData(
      x: xG,
      y: yG,
      z: zG,
      fallDetected: fallDetected,
      locSuspected: fallDetected,  // If fall detected, LOC is suspected
    );
    notifyListeners();
  }

  void enableDemoMode() {
    _demoMode = true;
    _batteryLevel = 85;
    _temperature = _TemperatureData(temperature: 36.6, confidence: 85);
    _setState(BleState.connected);
    _startSimulatedData();
  }

  Future<void> disconnect() async {
    _demoTimer?.cancel();
    _demoMode = false;
    _batteryLevel = 0;
    _temperature = _TemperatureData();
    _accel = AccelData();
    _hrSub?.cancel();
    _bpSub?.cancel();
    _o2Sub?.cancel();
    _batterySub?.cancel();
    _tempSub?.cancel();
    _stepsSub?.cancel();
    _accelSub?.cancel();
    _hrSub = null;
    _bpSub = null;
    _o2Sub = null;
    _batterySub = null;
    _tempSub = null;
    _stepsSub = null;
    _accelSub = null;
    
    final device = _device;
    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        // Ignore disconnect errors
      }
      _device = null;
    }
    
    _heartRate = HeartRateData();
    _bloodPressure = BloodPressureData();
    _oxygen = OxygenData();
    _activity = ActivityData(hourlySteps: List.filled(24, 0));
    
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
    _batterySub?.cancel();
    _tempSub?.cancel();
    _stepsSub?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }
}
