import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/app_settings.dart';
import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../services/ble_service.dart';
import '../services/live_squeeze_detector.dart';
import '../services/pressure_processing_service.dart';

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

class LiveCalibrationResult {
  const LiveCalibrationResult({
    required this.valid,
    required this.baselinePressure,
    required this.mvsPressure,
    required this.samplesUsed,
    required this.reason,
  });

  final bool valid;
  final double baselinePressure;
  final double mvsPressure;
  final int samplesUsed;
  final String reason;
}

class DeviceState extends ChangeNotifier {
  DeviceState({BleService Function(AppSettings settings)? bleServiceFactory})
    : _bleServiceFactory = bleServiceFactory ?? _defaultBleServiceFactory;

  static const batteryStaleAfter = Duration(seconds: 30);
  static const reconnectDelay = Duration(seconds: 3);
  static const liveCalibrationBaselineSamples = 20;
  static const idleBaselineWindowSamples = 50;
  static const liveCalibrationMiddleMvsSamples = 10;
  static const liveCalibrationReturnToBaselineSamples = 5;

  DeviceConnectionStatus _status = DeviceConnectionStatus.disconnected;
  String? _connectedDeviceName;
  double? _latestPressure;
  int? _batteryPercent;
  DateTime? _lastReceivedAt;
  DateTime? _lastBatteryReceivedAt;
  String? _errorMessage;
  BleService? _bleService;
  final BleService Function(AppSettings settings) _bleServiceFactory;
  List<BleDiscoveredDevice> _discoveredDevices = const [];
  AppSettings? _lastConnectionSettings;
  BleDiscoveredDevice? _lastDiscoveredDevice;
  Timer? _reconnectTimer;
  bool _manualDisconnecting = false;
  String? _livePatientId;
  Calibration? _liveCalibration;
  AppSettings _liveSettings = const AppSettings();
  Future<void> Function(PainEvent event)? _saveLivePainEvent;
  LiveSqueezeDetector? _liveSqueezeDetector;
  String? _liveDetectorKey;
  PainEvent? _lastRecordedLiveEvent;
  String? _liveRecordingMessage;
  bool _isLiveCalibrationRecording = false;
  List<double> _liveCalibrationSamples = const [];
  LiveCalibrationResult? _liveCalibrationResult;
  List<double> _idleBaselineSamples = const [];
  double? _idleBaselinePressure;
  double? _liveCalibrationBaselinePressure;

  DeviceConnectionStatus get status => _status;
  String? get connectedDeviceName => _connectedDeviceName;
  double? get latestPressure => _latestPressure;
  int? get batteryPercent => _batteryPercent;
  DateTime? get lastReceivedAt => _lastReceivedAt;
  DateTime? get lastBatteryReceivedAt => _lastBatteryReceivedAt;
  String? get errorMessage => _errorMessage;
  List<BleDiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  bool get isConnected => _status == DeviceConnectionStatus.connected;
  bool get isBatteryStale => isTimestampStale(
    lastUpdate: _lastBatteryReceivedAt,
    now: DateTime.now(),
    staleAfter: batteryStaleAfter,
  );
  PainEvent? get lastRecordedLiveEvent => _lastRecordedLiveEvent;
  String? get liveRecordingMessage => _liveRecordingMessage;
  bool get isLiveCalibrationRecording => _isLiveCalibrationRecording;
  int get liveCalibrationSampleCount => _liveCalibrationSamples.length;
  LiveCalibrationResult? get liveCalibrationResult => _liveCalibrationResult;
  double? get idleBaselinePressure => _idleBaselinePressure;
  double? get liveCalibrationBaselinePressure =>
      _liveCalibrationBaselinePressure;
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
    _manualDisconnecting = false;
    _lastConnectionSettings = settings;
    _errorMessage = null;
    final service = _bleServiceFactory(settings);
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
          _lastBatteryReceivedAt = _lastReceivedAt;
          notifyListeners();
        },
        onConnectionState: (state) {
          if (state == BluetoothConnectionState.connected) {
            _connectedDeviceName = settings.preferredDeviceName;
            _setStatus(DeviceConnectionStatus.connected);
          } else if (state == BluetoothConnectionState.disconnected) {
            _connectedDeviceName = null;
            _handleUnexpectedDisconnect();
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
    final service = _bleServiceFactory(settings);
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
    _manualDisconnecting = false;
    _lastConnectionSettings = settings;
    _lastDiscoveredDevice = discoveredDevice;
    _setStatus(DeviceConnectionStatus.connecting);
    _errorMessage = null;
    final service = _bleService ?? _bleServiceFactory(settings);
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
          _lastBatteryReceivedAt = _lastReceivedAt;
          notifyListeners();
        },
        onConnectionState: (state) {
          if (state == BluetoothConnectionState.connected) {
            _connectedDeviceName = discoveredDevice.displayName;
            _setStatus(DeviceConnectionStatus.connected);
          } else if (state == BluetoothConnectionState.disconnected) {
            _connectedDeviceName = null;
            _handleUnexpectedDisconnect();
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
      return 'No device found. Check that it is turned on, nearby, and charged.';
    }
    if (error is StateError) {
      final message = error.message.toLowerCase();
      if (message.contains('permission')) {
        return 'Bluetooth permission missing. Allow Bluetooth permissions and retry.';
      }
      if (message.contains('not enabled')) {
        return 'Bluetooth is off or unavailable. Turn Bluetooth on and retry.';
      }
      if (message.contains('characteristic')) {
        return 'Device found but pressure service not available.';
      }
    }
    return error.toString();
  }

  Future<void> disconnect() async {
    _manualDisconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _bleService?.disconnect();
    _bleService = null;
    _connectedDeviceName = null;
    _discoveredDevices = const [];
    _liveSqueezeDetector = _buildLiveSqueezeDetector();
    _setStatus(DeviceConnectionStatus.disconnected);
  }

  Future<void> reconnectNow([AppSettings? fallbackSettings]) async {
    final settings = _lastConnectionSettings ?? fallbackSettings;
    if (settings == null ||
        _status == DeviceConnectionStatus.connecting ||
        _status == DeviceConnectionStatus.connected) {
      return;
    }
    _lastConnectionSettings = settings;
    _manualDisconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _attemptReconnect();
  }

  void startLiveCalibration() {
    _isLiveCalibrationRecording = true;
    _liveCalibrationSamples = [];
    _liveCalibrationResult = null;
    _liveCalibrationBaselinePressure = _idleBaselinePressure ?? _latestPressure;
    notifyListeners();
  }

  LiveCalibrationResult stopLiveCalibration() {
    _isLiveCalibrationRecording = false;
    final result = calculateLiveMvsCalibration(
      baselinePressure: _liveCalibrationBaselinePressure,
      samples: _liveCalibrationSamples,
    );
    _liveCalibrationResult = result;
    notifyListeners();
    return result;
  }

  void resetLiveCalibration() {
    _isLiveCalibrationRecording = false;
    _liveCalibrationSamples = [];
    _liveCalibrationResult = null;
    _liveCalibrationBaselinePressure = null;
    notifyListeners();
  }

  void _handleLivePressure(double pressure) {
    final timestamp = DateTime.now();
    _latestPressure = pressure;
    _lastReceivedAt = timestamp;
    if (_isLiveCalibrationRecording && pressure.isFinite) {
      _liveCalibrationSamples = [..._liveCalibrationSamples, pressure];
      final result = autoStopLiveCalibrationResult(
        baselinePressure: _liveCalibrationBaselinePressure,
        samples: _liveCalibrationSamples,
      );
      if (result != null) {
        _isLiveCalibrationRecording = false;
        _liveCalibrationResult = result;
      }
      notifyListeners();
      return;
    }
    if (pressure.isFinite) {
      _trackIdleBaseline(pressure);
    }
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

  void _handleUnexpectedDisconnect() {
    if (_manualDisconnecting) {
      _setStatus(DeviceConnectionStatus.disconnected);
      return;
    }
    _setStatus(DeviceConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null || _lastConnectionSettings == null) {
      return;
    }
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectTimer = null;
      unawaited(_attemptReconnect());
    });
  }

  Future<void> _attemptReconnect() async {
    final settings = _lastConnectionSettings;
    if (settings == null || _manualDisconnecting) return;
    if (_status == DeviceConnectionStatus.connected ||
        _status == DeviceConnectionStatus.connecting) {
      return;
    }
    _setStatus(DeviceConnectionStatus.reconnecting);
    _bleService = null;
    final discoveredDevice = _lastDiscoveredDevice;
    if (discoveredDevice != null) {
      await connectToDiscoveredDevice(settings, discoveredDevice);
    } else {
      await connect(settings);
    }
    if (_status == DeviceConnectionStatus.error && !_manualDisconnecting) {
      _scheduleReconnect();
    }
  }

  static bool isTimestampStale({
    required DateTime? lastUpdate,
    required DateTime now,
    required Duration staleAfter,
  }) {
    if (lastUpdate == null) return false;
    return now.difference(lastUpdate) > staleAfter;
  }

  static LiveCalibrationResult calculateLiveCalibration(List<double> samples) {
    final cleanSamples = samples.where((sample) => sample.isFinite).toList();
    if (cleanSamples.length < liveCalibrationBaselineSamples + 3) {
      return const LiveCalibrationResult(
        valid: false,
        baselinePressure: 0,
        mvsPressure: 0,
        samplesUsed: 0,
        reason: 'Not enough samples. Hold still, squeeze, and retry.',
      );
    }

    final baselineSamples = cleanSamples
        .take(liveCalibrationBaselineSamples)
        .toList();
    final baselineResult = PressureProcessingService.assessBaseline(
      baselineSamples,
    );
    if (!baselineResult.isStable) {
      return LiveCalibrationResult(
        valid: false,
        baselinePressure: baselineResult.meanPressure,
        mvsPressure: 0,
        samplesUsed: baselineSamples.length,
        reason: 'Baseline unstable. Hold device still and retry.',
      );
    }

    final squeezeSamples = cleanSamples
        .skip(liveCalibrationBaselineSamples)
        .toList();
    final mvsResult = PressureProcessingService.calculateMvs(
      baselinePressure: baselineResult.meanPressure,
      samples: squeezeSamples,
    );
    if (!mvsResult.valid) {
      return LiveCalibrationResult(
        valid: false,
        baselinePressure: baselineResult.meanPressure,
        mvsPressure: mvsResult.mvsPressure,
        samplesUsed: mvsResult.samplesUsed,
        reason: mvsResult.reason,
      );
    }

    return LiveCalibrationResult(
      valid: true,
      baselinePressure: baselineResult.meanPressure,
      mvsPressure: mvsResult.mvsPressure,
      samplesUsed: mvsResult.samplesUsed,
      reason: 'Live calibration valid.',
    );
  }

  static LiveCalibrationResult? autoStopLiveCalibrationResult({
    required double? baselinePressure,
    required List<double> samples,
  }) {
    final result = calculateLiveMvsCalibration(
      baselinePressure: baselinePressure,
      samples: samples,
    );
    if (!result.valid) {
      return null;
    }
    return LiveCalibrationResult(
      valid: true,
      baselinePressure: result.baselinePressure,
      mvsPressure: result.mvsPressure,
      samplesUsed: result.samplesUsed,
      reason: 'Stable MVS found. Ready to save.',
    );
  }

  static LiveCalibrationResult calculateLiveMvsCalibration({
    required double? baselinePressure,
    required List<double> samples,
  }) {
    final baseline = baselinePressure;
    if (baseline == null || !baseline.isFinite || baseline <= 0) {
      return const LiveCalibrationResult(
        valid: false,
        baselinePressure: 0,
        mvsPressure: 0,
        samplesUsed: 0,
        reason: 'Need a stable idle baseline before MVS calibration.',
      );
    }
    final cleanSamples = samples.where((sample) => sample.isFinite).toList();
    final squeezeRegion = _completedSqueezeRegion(
      baselinePressure: baseline,
      samples: cleanSamples,
    );
    if (squeezeRegion == null) {
      return LiveCalibrationResult(
        valid: false,
        baselinePressure: baseline,
        mvsPressure: 0,
        samplesUsed: cleanSamples.length,
        reason: 'Squeeze for 3 seconds, then release to baseline.',
      );
    }

    final peakPressure = squeezeRegion.reduce(
      (current, sample) => sample > current ? sample : current,
    );
    final highThreshold = baseline + (peakPressure - baseline) * 0.85;
    final highForceRegion = squeezeRegion
        .where((sample) => sample >= highThreshold)
        .toList();
    if (highForceRegion.length < liveCalibrationMiddleMvsSamples) {
      return LiveCalibrationResult(
        valid: false,
        baselinePressure: baseline,
        mvsPressure: peakPressure,
        samplesUsed: highForceRegion.length,
        reason: 'Squeeze for 3 seconds, then release to baseline.',
      );
    }
    final middleRegion = _middleSamples(
      highForceRegion,
      liveCalibrationMiddleMvsSamples,
    );
    final mvsPressure =
        middleRegion.reduce((a, b) => a + b) / middleRegion.length;

    return LiveCalibrationResult(
      valid: true,
      baselinePressure: baseline,
      mvsPressure: mvsPressure,
      samplesUsed: middleRegion.length,
      reason: 'Live calibration valid.',
    );
  }

  static List<double>? _completedSqueezeRegion({
    required double baselinePressure,
    required List<double> samples,
  }) {
    final squeezeThreshold = baselinePressure + 150;
    final releaseThreshold = baselinePressure + 80;
    final startIndex = samples.indexWhere(
      (sample) => sample >= squeezeThreshold,
    );
    if (startIndex < 0) {
      return null;
    }
    var releaseRun = 0;
    for (
      var index = startIndex + liveCalibrationMiddleMvsSamples;
      index < samples.length;
      index++
    ) {
      if (samples[index] <= releaseThreshold) {
        releaseRun += 1;
      } else {
        releaseRun = 0;
      }
      if (releaseRun >= liveCalibrationReturnToBaselineSamples) {
        final endIndex = index - releaseRun + 1;
        final squeezeRegion = samples.sublist(startIndex, endIndex);
        if (squeezeRegion.length < liveCalibrationMiddleMvsSamples) {
          return null;
        }
        return squeezeRegion;
      }
    }
    return null;
  }

  static List<double> _middleSamples(List<double> samples, int count) {
    if (samples.length <= count) {
      return List.of(samples);
    }
    final start = ((samples.length - count) / 2).floor();
    return samples.sublist(start, start + count);
  }

  void _trackIdleBaseline(double pressure) {
    final samples = [..._idleBaselineSamples, pressure];
    _idleBaselineSamples = samples.length > idleBaselineWindowSamples
        ? samples.skip(samples.length - idleBaselineWindowSamples).toList()
        : samples;
    if (_idleBaselineSamples.length < idleBaselineWindowSamples) {
      return;
    }
    final result = PressureProcessingService.assessBaseline(
      _idleBaselineSamples,
    );
    if (!result.isStable) {
      return;
    }
    final currentBaseline = _idleBaselinePressure;
    if (currentBaseline != null &&
        result.meanPressure > currentBaseline + 120) {
      return;
    }
    _idleBaselinePressure = result.meanPressure;
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _bleService?.disconnect();
    super.dispose();
  }

  static BleService _defaultBleServiceFactory(AppSettings settings) {
    return BleService(
      deviceName: settings.preferredDeviceName,
      serviceUuid: settings.serviceUuid,
      pressureCharacteristicUuid: settings.characteristicUuid,
      batteryCharacteristicUuid: settings.batteryCharacteristicUuid,
    );
  }
}
