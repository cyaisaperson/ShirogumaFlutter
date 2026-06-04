import 'dart:io';

import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../models/patient.dart';

class CsvExportService {
  static const columns = [
    'patient_id',
    'patient_code',
    'patient_name',
    'age',
    'event_id',
    'timestamp',
    'start_time',
    'end_time',
    'duration_ms',
    'pain_level',
    'peak_pressure',
    'average_peak_pressure',
    'normalized_sas',
    'baseline_pressure',
    'mvs_pressure',
    'source',
    'device_id',
    'notes',
  ];

  static final headerLine = columns.join(',');

  static String buildPatientCsv({
    required Patient patient,
    required Calibration? calibration,
    required List<PainEvent> painEvents,
  }) {
    final patientEvents =
        painEvents.where((event) => event.patientId == patient.id).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final rows = <List<String?>>[
      columns,
      if (patientEvents.isEmpty)
        _rowForPatientProfile(patient, calibration)
      else
        for (final event in patientEvents)
          _rowForPainEvent(patient, calibration, event),
    ];

    return rows.map(_encodeRow).join('\n');
  }

  static Future<File> exportPatientCsv({
    required Patient patient,
    required Calibration? calibration,
    required List<PainEvent> painEvents,
    Directory? outputDirectory,
  }) async {
    final directory = outputDirectory ?? Directory.systemTemp;
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final file = File(
      '${directory.path}${Platform.pathSeparator}${_fileNameFor(patient)}',
    );
    return file.writeAsString(
      buildPatientCsv(
        patient: patient,
        calibration: calibration,
        painEvents: painEvents,
      ),
    );
  }

  static List<String?> _rowForPatientProfile(
    Patient patient,
    Calibration? calibration,
  ) {
    return [
      patient.id,
      patient.patientCode,
      patient.name,
      patient.age?.toString(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      calibration?.baselinePressure.toStringAsFixed(0),
      calibration?.mvsPressure.toStringAsFixed(0),
      null,
      null,
      _combineNotes(patient.description, calibration?.notes),
    ];
  }

  static List<String?> _rowForPainEvent(
    Patient patient,
    Calibration? calibration,
    PainEvent event,
  ) {
    return [
      patient.id,
      patient.patientCode,
      patient.name,
      patient.age?.toString(),
      event.id,
      event.timestamp.toIso8601String(),
      event.startTime?.toIso8601String(),
      event.endTime?.toIso8601String(),
      event.durationMs?.toString(),
      event.painLevel.toString(),
      event.peakPressure.toStringAsFixed(2),
      event.averagePeakPressure.toStringAsFixed(2),
      event.normalizedSas.toString(),
      event.baselinePressure.toStringAsFixed(2),
      event.mvsPressure.toStringAsFixed(2),
      event.source,
      event.deviceId,
      _combineNotes(patient.description, calibration?.notes, event.notes),
    ];
  }

  static String _encodeRow(List<String?> values) {
    return values.map(_encodeCell).join(',');
  }

  static String _encodeCell(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }
    return escaped;
  }

  static String? _combineNotes(
    String? patientNotes, [
    String? calibrationNotes,
    String? eventNotes,
  ]) {
    final parts = [
      if (patientNotes != null && patientNotes.trim().isNotEmpty)
        'patient: ${patientNotes.trim()}',
      if (calibrationNotes != null && calibrationNotes.trim().isNotEmpty)
        'calibration: ${calibrationNotes.trim()}',
      if (eventNotes != null && eventNotes.trim().isNotEmpty)
        'event: ${eventNotes.trim()}',
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' | ');
  }

  static String _fileNameFor(Patient patient) {
    final safeCode = patient.patientCode.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]+'),
      '_',
    );
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    return 'shiroguma_${safeCode}_$timestamp.csv';
  }
}
