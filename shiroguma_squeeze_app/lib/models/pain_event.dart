class PainEvent {
  const PainEvent({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.painLevel,
    required this.peakPressure,
    required this.averagePeakPressure,
    required this.normalizedSas,
    required this.baselinePressure,
    required this.mvsPressure,
    required this.source,
    this.startTime,
    this.endTime,
    this.durationMs,
    this.deviceId,
    this.notes,
  });

  final String id;
  final String patientId;
  final DateTime timestamp;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMs;
  final int painLevel;
  final double peakPressure;
  final double averagePeakPressure;
  final int normalizedSas;
  final double baselinePressure;
  final double mvsPressure;
  final String source;
  final String? deviceId;
  final String? notes;
}
