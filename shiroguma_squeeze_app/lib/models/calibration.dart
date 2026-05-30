class Calibration {
  const Calibration({
    required this.id,
    required this.patientId,
    required this.baselinePressure,
    required this.mvsPressure,
    required this.samplesUsed,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String patientId;
  final double baselinePressure;
  final double mvsPressure;
  final int samplesUsed;
  final DateTime createdAt;
  final String? notes;
}
