class BaselineResult {
  const BaselineResult({
    required this.isStable,
    required this.meanPressure,
    required this.range,
    required this.reason,
  });

  final bool isStable;
  final double meanPressure;
  final double range;
  final String reason;
}

class MvsCalibrationResult {
  const MvsCalibrationResult({
    required this.valid,
    required this.mvsPressure,
    required this.samplesUsed,
    required this.reason,
  });

  final bool valid;
  final double mvsPressure;
  final int samplesUsed;
  final String reason;
}

class PressureProcessingService {
  static double normalizePressure({
    required double pressure,
    required double baselinePressure,
    required double mvsPressure,
  }) {
    final usableRange = mvsPressure - baselinePressure;
    if (!pressure.isFinite || !usableRange.isFinite || usableRange <= 0) {
      return 0;
    }
    final normalized = ((pressure - baselinePressure) / usableRange).clamp(
      0.0,
      1.0,
    );
    return (normalized * 1000).round() / 1000;
  }

  static BaselineResult assessBaseline(List<double> samples) {
    final cleanSamples = samples.where((sample) => sample.isFinite).toList();
    if (cleanSamples.length < 3) {
      return const BaselineResult(
        isStable: false,
        meanPressure: 0,
        range: 0,
        reason: 'Need at least 3 baseline samples.',
      );
    }

    cleanSamples.sort();
    final minPressure = cleanSamples.first;
    final maxPressure = cleanSamples.last;
    final range = maxPressure - minPressure;
    final mean = cleanSamples.reduce((a, b) => a + b) / cleanSamples.length;
    final isStable = range <= 80;

    return BaselineResult(
      isStable: isStable,
      meanPressure: mean,
      range: range,
      reason: isStable
          ? 'Baseline stable.'
          : 'Baseline unstable; hold device still and try again.',
    );
  }

  static MvsCalibrationResult calculateMvs({
    required double baselinePressure,
    required List<double> samples,
  }) {
    final cleanSamples = samples.where((sample) => sample.isFinite).toList();
    if (cleanSamples.length < 3) {
      return const MvsCalibrationResult(
        valid: false,
        mvsPressure: 0,
        samplesUsed: 0,
        reason: 'Need at least 3 squeeze samples.',
      );
    }

    cleanSamples.sort();
    final peakPressure = cleanSamples.last;
    final rise = peakPressure - baselinePressure;
    if (rise < 150) {
      return const MvsCalibrationResult(
        valid: false,
        mvsPressure: 0,
        samplesUsed: 0,
        reason: 'Peak rise is less than 150 mbar above baseline.',
      );
    }

    final threshold = baselinePressure + rise * 0.85;
    final upperSamples = cleanSamples
        .where((sample) => sample >= threshold)
        .toList();
    final mvsPressure = _median(upperSamples);

    return MvsCalibrationResult(
      valid: true,
      mvsPressure: mvsPressure,
      samplesUsed: upperSamples.length,
      reason: 'MVS calibration valid.',
    );
  }

  static double _median(List<double> samples) {
    if (samples.isEmpty) {
      return 0;
    }
    samples.sort();
    final middle = samples.length ~/ 2;
    if (samples.length.isOdd) {
      return samples[middle];
    }
    return (samples[middle - 1] + samples[middle]) / 2;
  }
}
