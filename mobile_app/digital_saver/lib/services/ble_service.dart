import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:digital_saver/models/health_data.dart';

class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Service UUIDs
  static final String healthServiceUuid = '1816';
  static final String heartRateCharUuid = '2A37';
  static final String bloodPressureCharUuid = '2A35';
  static final String alertCharUuid = '2A3F';
  static final String deviceInfoServiceUuid = '180A';

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<List<int>>? _bpSubscription;
  StreamSubscription<List<int>>? _alertSubscription;

  bool _isScanning = false;
  bool _isConnected = false;
  HealthData? _latestHealthData;
  BloodPressureData? _latestBpData;
  int _connectionState = 0; // 0=disconnected, 1=connecting, 2=connected

  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  HealthData? get latestHealthData => _latestHealthData;
  BloodPressureData? get latestBpData => _latestBpData;
  int get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Scan for nearby devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Look for Digital Saver device
          if (result.device.platformName.contains('DigitalSaver') ||
              result.device.platformName.contains('DS-WATCH')) {
            connectToDevice(result.device);
            break;
          }
        }
      });
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _connectionState = 1;
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // Discover services
      final services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().contains(healthServiceUuid)) {
          await _subscribeToHealthService(service);
        }
      }

      _isConnected = true;
      _connectionState = 2;
    } catch (e) {
      debugPrint('Connection error: $e');
      _connectionState = 0;
    }
    notifyListeners();
  }

  Future<void> _subscribeToHealthService(BluetoothService service) async {
    for (BluetoothCharacteristic char in service.characteristics) {
      final uuidStr = char.uuid.toString();
      
      if (uuidStr.contains(heartRateCharUuid)) {
        await char.setNotifyValue(true);
        _heartRateSubscription = char.lastValueStream.listen((data) {
          _handleHeartRateData(data);
        });
      }
      
      if (uuidStr.contains(bloodPressureCharUuid)) {
        await char.setNotifyValue(true);
        _bpSubscription = char.lastValueStream.listen((data) {
          _handleBpData(data);
        });
      }
      
      if (uuidStr.contains(alertCharUuid)) {
        await char.setNotifyValue(true);
        _alertSubscription = char.lastValueStream.listen((data) {
          _handleAlertData(data);
        });
      }
    }
  }

  void _handleHeartRateData(List<int> data) {
    if (data.isEmpty) return;
    
    try {
      _latestHealthData = HealthData.fromPacket(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Heart rate parse error: $e');
    }
  }

  void _handleBpData(List<int> data) {
    if (data.isEmpty) return;
    
    try {
      _latestBpData = BloodPressureData.fromPacket(data);
      notifyListeners();
    } catch (e) {
      debugPrint('BP parse error: $e');
    }
  }

  void _handleAlertData(List<int> data) {
    if (data.isEmpty) return;
    
    try {
      final alert = AlertData.fromPacket(data);
      // Emit alert through a callback or stream
      _onAlertReceived?.add(alert);
      notifyListeners();
    } catch (e) {
      debugPrint('Alert parse error: $e');
    }
  }

  StreamController<AlertData>? _alertController;
  Stream<AlertData>? _onAlertReceived;
  
  Stream<AlertData> get alertStream {
    _alertController ??= StreamController<AlertData>.broadcast();
    _onAlertReceived = _alertController!.stream;
    return _alertController!.stream;
  }

  void triggerEmergencyAlert(AlertData alert) {
    _alertController?.add(alert);
  }

  Future<void> disconnect() async {
    await _heartRateSubscription?.cancel();
    await _bpSubscription?.cancel();
    await _alertSubscription?.cancel();
    await _connectedDevice?.disconnect();
    
    _connectedDevice = null;
    _isConnected = false;
    _connectionState = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _bpSubscription?.cancel();
    _alertSubscription?.cancel();
    _alertController?.close();
    super.dispose();
  }
}
