import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/app_settings.dart';
import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../services/ble_service.dart';
import '../services/live_squeeze_detector.dart';

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
  List<BleDiscoveredDevice> _discoveredDevices = const [];
  String? _livePatientId;
  Calibration? _liveCalibration;
  AppSettings _liveSettings = const AppSettings();
  Future<void> Function(PainEvent event)? _saveLivePainEvent;
  LiveSqueezeDetector? _liveSqueezeDetector;
  String? _liveDetectorKey;
  PainEvent? _lastRecordedLiveEvent;
  String? _liveRecordingMessage;

  DeviceConnectionStatus get status => _status;
  String? get connectedDeviceName => _connectedDeviceName;
  double? get latestPressure => _latestPressure;
  int? get batteryPercent => _batteryPercent;
  DateTime? get lastReceivedAt => _lastReceivedAt;
  String? get errorMessage => _errorMessage;
  List<BleDiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  bool get isConnected => _status == DeviceConnectionStatus.connected;
  PainEvent? get lastRecordedLiveEvent => _lastRecordedLiveEvent;
  String? get liveRecordingMessage => _liveRecordingMessage;
  String get liveSavingStatus {
    if (_liveSettings.dataMode != DataMode.liveBle) {
      return 'Blocked: SD Card mode';
    }
    if (!isConnected) {
      return 'Blocked: BLE disconnected';
    }
    if (_livePatientId == null) {
      return 'Blocked: select patient';
    }
    final calibration = _liveCalibration;
    if (calibration == null) {
      return 'Blocked: calibration required';
    }
    if (calibration.mvsPressure <= calibration.baselinePressure) {
      return 'Blocked: valid calibration required';
    }
    return 'Live saving ready';
  }

  void configureLiveDetection({
    required String? activePatientId,
    required Calibration? calibration,
    required AppSettings settings,
    required Future<void> Function(PainEvent event) onPainEvent,
  }) {
    _livePatientId = activePatientId;
    _liveCalibration = calibration;
    _liveSettings = settings;
    _saveLivePainEvent = onPainEvent;
    final detectorKey =
        '${activePatientId ?? 'none'}|${calibration?.id ?? 'none'}|'
        '${settings.dataMode.storageValue}|'
        '${settings.thresholdPercentAboveBaseline}|${settings.peakWindowSize}|'
        '${connectedDeviceName ?? settings.preferredDeviceName}';
    if (_liveDetectorKey != detectorKey) {
      _liveDetectorKey = detectorKey;
      _liveSqueezeDetector = _buildLiveSqueezeDetector();
      _liveRecordingMessage = null;
    }
  }

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
          _handleLivePressure(pressure);
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
      _errorMessage = bleErrorMessage(error, settings);
      _connectedDeviceName = null;
      _setStatus(DeviceConnectionStatus.error);
    }
  }

  Stream<List<BleDiscoveredDevice>> browseDevices(AppSettings settings) {
    _errorMessage = null;
    _setStatus(DeviceConnectionStatus.scanning);
    final service = BleService(
      deviceName: settings.preferredDeviceName,
      serviceUuid: settings.serviceUuid,
      pressureCharacteristicUuid: settings.characteristicUuid,
      batteryCharacteristicUuid: settings.batteryCharacteristicUuid,
    );
    _bleService = service;
    return service.scanNearbyDevices().map((devices) {
      _discoveredDevices = devices;
      notifyListeners();
      return devices;
    });
  }

  Future<void> stopBrowsing() async {
    await _bleService?.stopScan();
    if (_status == DeviceConnectionStatus.scanning) {
      _setStatus(DeviceConnectionStatus.disconnected);
    }
  }

  Future<void> connectToDiscoveredDevice(
    AppSettings settings,
    BleDiscoveredDevice discoveredDevice,
  ) async {
    if (_status == DeviceConnectionStatus.connecting ||
        _status == DeviceConnectionStatus.connected) {
      return;
    }
    _setStatus(DeviceConnectionStatus.connecting);
    _errorMessage = null;
    final service =
        _bleService ??
        BleService(
          deviceName: settings.preferredDeviceName,
          serviceUuid: settings.serviceUuid,
          pressureCharacteristicUuid: settings.characteristicUuid,
          batteryCharacteristicUuid: settings.batteryCharacteristicUuid,
        );
    _bleService = service;
    try {
      await service.connectToDiscoveredDevice(
        discoveredDevice: discoveredDevice,
        onPressure: (pressure) {
          _handleLivePressure(pressure);
        },
        onBattery: (batteryPercent) {
          _batteryPercent = batteryPercent;
          _lastReceivedAt = DateTime.now();
          notifyListeners();
        },
        onConnectionState: (state) {
          if (state == BluetoothConnectionState.connected) {
            _connectedDeviceName = discoveredDevice.displayName;
            _setStatus(DeviceConnectionStatus.connected);
          } else if (state == BluetoothConnectionState.disconnected) {
            _connectedDeviceName = null;
            _setStatus(DeviceConnectionStatus.disconnected);
          }
        },
      );
      _connectedDeviceName = discoveredDevice.displayName;
      _setStatus(DeviceConnectionStatus.connected);
    } catch (error) {
      _errorMessage = bleErrorMessage(error, settings);
      _connectedDeviceName = null;
      _setStatus(DeviceConnectionStatus.error);
    }
  }

  static String bleErrorMessage(Object error, AppSettings settings) {
    if (error is TimeoutException) {
      return 'No Shiroguma Bluetooth device found. Auto connect looks for ${BleService.defaultDeviceName}; use Browse devices to choose from nearby Bluetooth devices.';
    }
    return error.toString();
  }

  Future<void> disconnect() async {
    await _bleService?.disconnect();
    _bleService = null;
    _connectedDeviceName = null;
    _discoveredDevices = const [];
    _liveSqueezeDetector = _buildLiveSqueezeDetector();
    _setStatus(DeviceConnectionStatus.disconnected);
  }

  void _handleLivePressure(double pressure) {
    final timestamp = DateTime.now();
    _latestPressure = pressure;
    _lastReceivedAt = timestamp;
    final detector = _liveSqueezeDetector;
    if (_canSaveLiveEvents && detector != null) {
      final event = detector.addPressureSample(
        pressure: pressure,
        timestamp: timestamp,
      );
      if (event != null) {
        unawaited(_saveDetectedLiveEvent(event));
      }
    }
    notifyListeners();
  }

  bool get _canSaveLiveEvents {
    return _liveSettings.dataMode == DataMode.liveBle &&
        isConnected &&
        _livePatientId != null &&
        _liveCalibration != null &&
        _saveLivePainEvent != null;
  }

  LiveSqueezeDetector? _buildLiveSqueezeDetector() {
    final patientId = _livePatientId;
    final calibration = _liveCalibration;
    if (patientId == null || calibration == null) {
      return null;
    }
    return LiveSqueezeDetector(
      patientId: patientId,
      calibration: calibration,
      settings: _liveSettings,
      deviceId: connectedDeviceName ?? _liveSettings.preferredDeviceName,
      belowThresholdDebounce: const Duration(milliseconds: 150),
      cooldown: const Duration(milliseconds: 800),
    );
  }

  Future<void> _saveDetectedLiveEvent(PainEvent event) async {
    final save = _saveLivePainEvent;
    if (save == null) return;
    try {
      await save(event);
      _lastRecordedLiveEvent = event;
      _liveRecordingMessage = 'Level ${event.painLevel} recorded';
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
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
