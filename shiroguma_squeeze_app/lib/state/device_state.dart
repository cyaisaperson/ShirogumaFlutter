import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/app_settings.dart';
import '../services/ble_service.dart';

enum DeviceConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error;

  String get label {
    return switch (this) {
      DeviceConnectionStatus.disconnected => 'Disconnected',
      DeviceConnectionStatus.scanning => 'Scanning',
      DeviceConnectionStatus.connecting => 'Connecting',
      DeviceConnectionStatus.connected => 'Connected',
      DeviceConnectionStatus.reconnecting => 'Reconnecting',
      DeviceConnectionStatus.error => 'Error',
    };
  }
}

class DeviceState extends ChangeNotifier {
  DeviceState();

  DeviceConnectionStatus _status = DeviceConnectionStatus.disconnected;
  String? _connectedDeviceName;
  double? _latestPressure;
  int? _batteryPercent;
  DateTime? _lastReceivedAt;
  String? _errorMessage;
  BleService? _bleService;

  DeviceConnectionStatus get status => _status;
  String? get connectedDeviceName => _connectedDeviceName;
  double? get latestPressure => _latestPressure;
  int? get batteryPercent => _batteryPercent;
  DateTime? get lastReceivedAt => _lastReceivedAt;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == DeviceConnectionStatus.connected;

  Future<void> connect(AppSettings settings) async {
    if (_status == DeviceConnectionStatus.scanning ||
        _status == DeviceConnectionStatus.connecting ||
        _status == DeviceConnectionStatus.connected) {
      return;
    }
    _setStatus(DeviceConnectionStatus.scanning);
    _errorMessage = null;
    final service = BleService(
      deviceName: settings.preferredDeviceName,
      serviceUuid: settings.serviceUuid,
      pressureCharacteristicUuid: settings.characteristicUuid,
      batteryCharacteristicUuid: settings.batteryCharacteristicUuid,
    );
    _bleService = service;
    try {
      _setStatus(DeviceConnectionStatus.connecting);
      await service.connect(
        onPressure: (pressure) {
          _latestPressure = pressure;
          _lastReceivedAt = DateTime.now();
          notifyListeners();
        },
        onBattery: (batteryPercent) {
          _batteryPercent = batteryPercent;
          _lastReceivedAt = DateTime.now();
          notifyListeners();
        },
        onConnectionState: (state) {
          if (state == BluetoothConnectionState.connected) {
            _connectedDeviceName = settings.preferredDeviceName;
            _setStatus(DeviceConnectionStatus.connected);
          } else if (state == BluetoothConnectionState.disconnected) {
            _connectedDeviceName = null;
            _setStatus(DeviceConnectionStatus.disconnected);
          }
        },
      );
      _connectedDeviceName = settings.preferredDeviceName;
      _setStatus(DeviceConnectionStatus.connected);
    } catch (error) {
      _errorMessage = error.toString();
      _connectedDeviceName = null;
      _setStatus(DeviceConnectionStatus.error);
    }
  }

  Future<void> disconnect() async {
    await _bleService?.disconnect();
    _bleService = null;
    _connectedDeviceName = null;
    _setStatus(DeviceConnectionStatus.disconnected);
  }

  void _setStatus(DeviceConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _bleService?.disconnect();
    super.dispose();
  }
}
