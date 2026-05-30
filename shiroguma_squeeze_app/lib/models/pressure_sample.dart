class PressureSample {
  const PressureSample({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.pressure,
    this.sessionId,
    this.deviceId,
  });

  final String id;
  final String patientId;
  final DateTime timestamp;
  final double pressure;
  final String? sessionId;
  final String? deviceId;
}
