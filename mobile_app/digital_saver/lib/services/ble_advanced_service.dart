import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:digital_saver/models/health_models.dart';

/// Advanced BLE Service for smartwatch communication
class BleAdvancedService extends ChangeNotifier {
  static final BleAdvancedService _instance = BleAdvancedService._internal();
  factory BleAdvancedService() => _instance;
  BleAdvancedService._internal();

  // BLE UUIDs
  static const String healthServiceUuid = '1816';
  static const String heartRateCharUuid = '2A37';
  static const String bloodPressureCharUuid = '2A35';
  static const String alertCharUuid = '2A3F';
  static const String deviceInfoServiceUuid = '180A';
  static const String batteryServiceUuid = '180F';
  static const String batteryCharUuid = '2A19';

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<List<int>>? _bpSubscription;
  StreamSubscription<List<int>>? _alertSubscription;
  StreamSubscription<List<int>>? _batterySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  bool _isScanning = false;
  bool _isConnected = false;
  int _connectionState = 0; // 0=disconnected, 1=connecting, 2=connected
  int _batteryLevel = 100;
  int _signalStrength = 0;
  DateTime? _lastSync;
  String _firmwareVersion = '1.0.0';
  WatchStatus _watchStatus = WatchStatus.disconnected;

  // Real-time data streams
  final _healthDataController = StreamController<HealthMetrics>.broadcast();
  final _alertController = StreamController<HealthAlert>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  Stream<HealthMetrics> get healthDataStream => _healthDataController.stream;
  Stream<HealthAlert> get alertStream => _alertController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  int get connectionState => _connectionState;
  int get batteryLevel => _batteryLevel;
  int get signalStrength => _signalStrength;
  DateTime? get lastSync => _lastSync;
  String get firmwareVersion => _firmwareVersion;
  WatchStatus get watchStatus => _watchStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Start scanning for nearby devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
    void Function(BluetoothDevice)? onDeviceFound,
  }) async {
    _isScanning = true;
    _connectionState = 1;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: timeout);

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Look for Digital Saver devices
          final name = result.device.platformName;
          if (name.contains('DigitalSaver') || 
              name.contains('DS-WATCH') ||
              name.contains('HealthWatch')) {
            onDeviceFound?.call(result.device);
          }
        }
      });

      // Auto-stop scan after timeout
      Future.delayed(timeout, () {
        if (_isScanning) {
          stopScan();
        }
      });
    } catch (e) {
      debugPrint('Scan error: $e');
      _isScanning = false;
      _connectionState = 0;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to device
  Future<bool> connect(BluetoothDevice device) async {
    _connectionState = 1;
    _watchStatus = WatchStatus.syncing;
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 20));
      _connectedDevice = device;
      
      // Discover services
      await _discoverServicesAndSubscribe(device);
      
      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) {
        _isConnected = state == BluetoothConnectionState.connected;
        if (!_isConnected) {
          _watchStatus = WatchStatus.disconnected;
          _connectionController.add(false);
        }
        notifyListeners();
      });

      _isConnected = true;
      _connectionState = 2;
      _watchStatus = WatchStatus.active;
      _lastSync = DateTime.now();
      _connectionController.add(true);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      _connectionState = 0;
      _watchStatus = WatchStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> _discoverServicesAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();
    
    for (BluetoothService service in services) {
      final serviceUuid = service.uuid.toString().toLowerCase();
      
      for (BluetoothCharacteristic char in service.characteristics) {
        final charUuid = char.uuid.toString().toLowerCase();
        
        // Heart Rate Characteristic
        if (charUuid.contains(heartRateCharUuid)) {
          await char.setNotifyValue(true);
          _heartRateSubscription = char.lastValueStream.listen(_handleHeartRate);
        }
        
        // Blood Pressure Characteristic
        if (charUuid.contains(bloodPressureCharUuid)) {
          await char.setNotifyValue(true);
          _bpSubscription = char.lastValueStream.listen(_handleBloodPressure);
        }
        
        // Alert Characteristic
        if (charUuid.contains(alertCharUuid)) {
          await char.setNotifyValue(true);
          _alertSubscription = char.lastValueStream.listen(_handleAlert);
        }
        
        // Battery Characteristic
        if (charUuid.contains(batteryCharUuid)) {
          await char.setNotifyValue(true);
          _batterySubscription = char.lastValueStream.listen(_handleBattery);
        }
      }
    }
  }

  void _handleHeartRate(List<int> data) {
    if (data.length < 6) return;
    
    final heartRate = HeartRateData(
      currentBPM: data[1],
      averageBPM: data.length > 6 ? data[6] : data[1],
      minBPM: data.length > 7 ? data[7] : data[1] - 10,
      maxBPM: data.length > 8 ? data[8] : data[1] + 10,
      hrv: data.length > 9 ? data[9].toDouble() : 50.0,
      sdnn: data.length > 10 ? data[10].toDouble() : 30.0,
      rrIntervals: [],
      status: _determineHRStatus(data[1]),
      confidence: data.length > 3 ? data[3].toDouble() : 80.0,
      hrvAnalysis: [],
      afibProbability: data.length > 11 ? data[11].toDouble() : 0.0,
    );
    
    _lastSync = DateTime.now();
    notifyListeners();
  }

  void _handleBloodPressure(List<int> data) {
    if (data.length < 5) return;
    
    final bp = BloodPressureData(
      systolic: data[1],
      diastolic: data[2],
      meanArterialPressure: data[3],
      pulsePressure: (data[1] - data[2]).toDouble(),
      augmentationIndex: data.length > 4 ? data[4].toDouble() : 30.0,
      pulseWaveVelocity: data.length > 5 ? data[5].toDouble() : 8.0,
      pulseWave: [],
      category: _categorizeBP(data[1], data[2]),
      confidence: data.length > 6 ? data[6].toDouble() : 70.0,
    );
    
    _lastSync = DateTime.now();
    notifyListeners();
  }

  void _handleAlert(List<int> data) {
    if (data.length < 4) return;
    
    final alert = HealthAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AlertType.values[data[1] - 1] ?? AlertType.manual,
      severity: AlertSeverity.values[data[2] - 1] ?? AlertSeverity.warning,
      timestamp: DateTime.now(),
      message: _getAlertMessage(data[1]),
      value: data.length > 3 ? data[3].toDouble() : null,
    );
    
    _alertController.add(alert);
    
    // Also update watch status
    if (data[1] == 1) {
      _watchStatus = WatchStatus.error;
    }
    
    notifyListeners();
  }

  void _handleBattery(List<int> data) {
    if (data.isEmpty) return;
    _batteryLevel = data[0];
    notifyListeners();
  }

  HeartRateStatus _determineHRStatus(int bpm) {
    if (bpm < 50 || bpm > 150) return HeartRateStatus.critical;
    if (bpm < 60 || bpm > 100) return HeartRateStatus.warning;
    return HeartRateStatus.normal;
  }

  BpCategory _categorizeBP(int sys, int dia) {
    if (sys >= 180 || dia >= 120) return BpCategory.crisis;
    if (sys >= 140 || dia >= 90) return BpCategory.hypertension2;
    if (sys >= 130 || dia >= 80) return BpCategory.hypertension1;
    if (sys >= 120) return BpCategory.elevated;
    if (sys < 90 || dia < 60) return BpCategory.hypotension;
    return BpCategory.normal;
  }

  String _getAlertMessage(int type) {
    switch (type) {
      case 1: return 'Fall detected! Possible loss of consciousness';
      case 2: return 'Irregular heartbeat (Arrhythmia) detected';
      case 3: return 'High AFib probability detected';
      case 4: return 'High blood pressure detected';
      case 5: return 'Low blood pressure detected';
      case 6: return 'Fast heart rate (Tachycardia) detected';
      case 7: return 'Slow heart rate (Bradycardia) detected';
      case 8: return 'Low oxygen saturation detected';
      case 9: return 'Watch battery low';
      case 10: return 'Watch disconnected';
      default: return 'Emergency alert triggered';
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await _heartRateSubscription?.cancel();
    await _bpSubscription?.cancel();
    await _alertSubscription?.cancel();
    await _batterySubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    
    _connectedDevice = null;
    _isConnected = false;
    _connectionState = 0;
    _watchStatus = WatchStatus.disconnected;
    _connectionController.add(false);
    notifyListeners();
  }

  /// Reconnect to last device
  Future<bool> reconnect() async {
    if (_connectedDevice != null) {
      return await connect(_connectedDevice!);
    }
    return false;
  }

  /// Write data to device
  Future<bool> writeCharacteristic(String serviceUuid, String charUuid, Uint8List data) async {
    if (!_isConnected || _connectedDevice == null) return false;
    
    try {
      final services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().contains(serviceUuid)) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().contains(charUuid)) {
              await char.write(data);
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Write error: $e');
    }
    return false;
  }

  /// Trigger emergency alert on watch
  Future<void> triggerWatchAlert(AlertType type) async {
    final data = Uint8List.fromList([0x03, type.index + 1, 2, 0, 0, 0, 0]);
    await writeCharacteristic(healthServiceUuid, alertCharUuid, data);
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _bpSubscription?.cancel();
    _alertSubscription?.cancel();
    _batterySubscription?.cancel();
    _connectionSubscription?.cancel();
    _healthDataController.close();
    _alertController.close();
    _connectionController.close();
    super.dispose();
  }
}
