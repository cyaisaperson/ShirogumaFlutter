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

  factory PainEvent.fromJson(Map<String, Object?> json) {
    return PainEvent(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      startTime: _dateTimeOrNull(json['startTime']),
      endTime: _dateTimeOrNull(json['endTime']),
      durationMs: json['durationMs'] as int?,
      painLevel: json['painLevel'] as int,
      peakPressure: (json['peakPressure'] as num).toDouble(),
      averagePeakPressure: (json['averagePeakPressure'] as num).toDouble(),
      normalizedSas: json['normalizedSas'] as int,
      baselinePressure: (json['baselinePressure'] as num).toDouble(),
      mvsPressure: (json['mvsPressure'] as num).toDouble(),
      source: json['source'] as String,
      deviceId: json['deviceId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': durationMs,
      'painLevel': painLevel,
      'peakPressure': peakPressure,
      'averagePeakPressure': averagePeakPressure,
      'normalizedSas': normalizedSas,
      'baselinePressure': baselinePressure,
      'mvsPressure': mvsPressure,
      'source': source,
      'deviceId': deviceId,
      'notes': notes,
    };
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}
