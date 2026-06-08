import '../models/app_settings.dart';
import '../models/calibration.dart';
import '../models/pain_event.dart';
import 'pressure_processing_service.dart';

class LiveSqueezeDetector {
  LiveSqueezeDetector({
    required this.patientId,
    required this.calibration,
    required this.settings,
    this.deviceId,
    this.belowThresholdDebounce = const Duration(milliseconds: 150),
    this.cooldown = const Duration(milliseconds: 800),
  });

  final String patientId;
  final Calibration calibration;
  final AppSettings settings;
  final String? deviceId;
  final Duration belowThresholdDebounce;
  final Duration cooldown;

  final List<_LivePressureSample> _segment = [];
  DateTime? _belowThresholdSince;
  DateTime? _lastSavedAt;

  bool get hasValidCalibration =>
      calibration.baselinePressure.isFinite &&
      calibration.mvsPressure.isFinite &&
      calibration.mvsPressure > calibration.baselinePressure;

  PainEvent? addPressureSample({
    required double pressure,
    required DateTime timestamp,
  }) {
    if (!pressure.isFinite || !hasValidCalibration) return null;
    if (_isCoolingDown(timestamp)) return null;

    final threshold =
        calibration.baselinePressure *
        (1 + settings.thresholdPercentAboveBaseline / 100);
    final isAboveThreshold = pressure > threshold;

    if (_segment.isEmpty) {
      if (isAboveThreshold) {
        _segment.add(_LivePressureSample(pressure, timestamp));
      }
      return null;
    }

    if (isAboveThreshold) {
      _belowThresholdSince = null;
      _segment.add(_LivePressureSample(pressure, timestamp));
      return null;
    }

    _belowThresholdSince ??= timestamp;
    if (timestamp.difference(_belowThresholdSince!) < belowThresholdDebounce) {
      return null;
    }

    return _finishSegment(timestamp);
  }

  bool _isCoolingDown(DateTime timestamp) {
    final lastSavedAt = _lastSavedAt;
    return lastSavedAt != null && timestamp.difference(lastSavedAt) < cooldown;
  }

  PainEvent? _finishSegment(DateTime finalizedAt) {
    if (_segment.isEmpty) return null;
    final segment = List<_LivePressureSample>.of(_segment);
    _segment.clear();
    _belowThresholdSince = null;

    final representativePressure = _representativePressure(segment);
    final normalized = PressureProcessingService.normalizePressure(
      pressure: representativePressure,
      baselinePressure: calibration.baselinePressure,
      mvsPressure: calibration.mvsPressure,
    );
    final normalizedSas = (normalized * 100).round().clamp(0, 100);
    final painLevel = painLevelForSas(normalizedSas);
    if (painLevel == 0) return null;

    final startTime = segment.first.timestamp;
    final endTime = finalizedAt;
    _lastSavedAt = finalizedAt;

    return PainEvent(
      id: 'live-${finalizedAt.microsecondsSinceEpoch}',
      patientId: patientId,
      timestamp: endTime,
      startTime: startTime,
      endTime: endTime,
      durationMs: endTime.difference(startTime).inMilliseconds,
      painLevel: painLevel,
      peakPressure: segment
          .map((sample) => sample.pressure)
          .reduce((a, b) => a > b ? a : b),
      averagePeakPressure: representativePressure,
      normalizedSas: normalizedSas,
      baselinePressure: calibration.baselinePressure,
      mvsPressure: calibration.mvsPressure,
      source: 'live_ble',
      deviceId: deviceId,
      notes: 'Detected from live BLE pressure stream.',
    );
  }

  double _representativePressure(List<_LivePressureSample> segment) {
    if (segment.isEmpty) return 0;
    final windowSize = settings.peakWindowSize.clamp(1, segment.length);
    final middle = segment.length ~/ 2;
    final start = (middle - windowSize ~/ 2).clamp(0, segment.length);
    final end = (start + windowSize).clamp(start + 1, segment.length);
    final samples = segment.sublist(start, end);
    return samples.map((sample) => sample.pressure).reduce((a, b) => a + b) /
        samples.length;
  }

  static int painLevelForSas(int normalizedSas) {
    if (normalizedSas <= 0) return 0;
    if (normalizedSas <= 20) return 1;
    if (normalizedSas <= 40) return 2;
    if (normalizedSas <= 60) return 3;
    if (normalizedSas <= 80) return 4;
    return 5;
  }
}

class _LivePressureSample {
  const _LivePressureSample(this.pressure, this.timestamp);

  final double pressure;
  final DateTime timestamp;
}
