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

  factory Calibration.fromJson(Map<String, Object?> json) {
    return Calibration(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      baselinePressure: (json['baselinePressure'] as num).toDouble(),
      mvsPressure: (json['mvsPressure'] as num).toDouble(),
      samplesUsed: json['samplesUsed'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'baselinePressure': baselinePressure,
      'mvsPressure': mvsPressure,
      'samplesUsed': samplesUsed,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }
}
