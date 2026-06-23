import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/calibration.dart';
import 'package:shiroguma_squeeze_app/models/pain_event.dart';
import 'package:shiroguma_squeeze_app/models/patient.dart';
import 'package:shiroguma_squeeze_app/services/csv_export_service.dart';

void main() {
  test('exports active patient profile calibration and events only', () {
    final patient = Patient(
      id: 'patient-active',
      name: 'Mina, Chen',
      patientCode: 'P-004',
      age: 9,
      description: 'Needs quiet room',
      createdAt: DateTime(2026, 6, 4),
      updatedAt: DateTime(2026, 6, 4),
    );
    final calibration = Calibration(
      id: 'calibration-active',
      patientId: patient.id,
      baselinePressure: 1012,
      mvsPressure: 2310,
      samplesUsed: 12,
      createdAt: DateTime(2026, 6, 4, 8),
      notes: 'Manual calibration',
    );
    final activeEvent = PainEvent(
      id: 'event-active',
      patientId: patient.id,
      timestamp: DateTime(2026, 6, 4, 9, 30),
      startTime: DateTime(2026, 6, 4, 9, 29, 55),
      endTime: DateTime(2026, 6, 4, 9, 30, 5),
      durationMs: 10000,
      painLevel: 6,
      peakPressure: 1400,
      averagePeakPressure: 1388,
      normalizedSas: 52,
      baselinePressure: 1012,
      mvsPressure: 2310,
      source: 'live_ble',
      deviceId: 'PressureTX',
      notes: 'First event',
    );
    final otherEvent = PainEvent(
      id: 'event-other',
      patientId: 'patient-other',
      timestamp: DateTime(2026, 6, 4, 10),
      painLevel: 8,
      peakPressure: 1500,
      averagePeakPressure: 1490,
      normalizedSas: 75,
      baselinePressure: 1000,
      mvsPressure: 2200,
      source: 'mock',
    );

    final csv = CsvExportService.buildPatientCsv(
      patient: patient,
      calibration: calibration,
      painEvents: [activeEvent, otherEvent],
    );

    expect(csv, contains(CsvExportService.headerLine));
    expect(csv, contains('"Mina, Chen"'));
    expect(csv, contains('event-active'));
    expect(csv, contains('live_ble'));
    expect(csv, contains('PressureTX'));
    expect(csv, contains('Manual calibration'));
    expect(csv, isNot(contains('event-other')));
  });

  test('exports a valid header and profile row for empty history', () {
    final patient = Patient(
      id: 'patient-empty',
      name: 'No Events',
      patientCode: 'P-005',
      description: '',
      createdAt: DateTime(2026, 6, 4),
      updatedAt: DateTime(2026, 6, 4),
    );

    final csv = CsvExportService.buildPatientCsv(
      patient: patient,
      calibration: null,
      painEvents: const [],
    );
    final lines = csv.trim().split('\n');

    expect(lines.first, CsvExportService.headerLine);
    expect(lines, hasLength(2));
    expect(lines.last, startsWith('patient-empty,P-005,No Events'));
  });
}
