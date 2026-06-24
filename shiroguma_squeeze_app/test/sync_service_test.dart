import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/calibration.dart';
import 'package:shiroguma_squeeze_app/models/pain_event.dart';
import 'package:shiroguma_squeeze_app/services/sync_service.dart';

void main() {
  test(
    'SD card sync placeholder reports future flow without importing',
    () async {
      final result = await SyncService().prepareSdCardSync();

      expect(result.status, SyncPlaceholderStatus.notImplemented);
      expect(result.importedEvents, 0);
      expect(result.message, contains('SD Card Sync mode connects'));
      expect(result.futureSteps, contains('request stored SD log'));
      expect(
        result.futureSteps,
        contains('delete synced SD files after successful import'),
      );
    },
  );

  test(
    'pain event preserves external sample id for future SD duplicate checks',
    () {
      final event = PainEvent(
        id: 'event-sd-1',
        patientId: 'patient-1',
        timestamp: DateTime(2026, 6, 8, 9),
        painLevel: 2,
        peakPressure: 1200,
        averagePeakPressure: 1180,
        normalizedSas: 31,
        baselinePressure: 1000,
        mvsPressure: 1600,
        source: 'sd_sync',
        deviceId: 'PressureTX',
        externalSampleId: 'sd-row-42',
      );

      final restored = PainEvent.fromJson(event.toJson());

      expect(restored.source, 'sd_sync');
      expect(restored.externalSampleId, 'sd-row-42');
    },
  );

  test('parses valid SD events and skips malformed rows', () {
    const csv = '''
event_id,start_ms,end_ms,duration_ms,baseline_mbar,peak_mbar,delta_mbar
7,1000,2500,1500,1012.5,1420.5,408
bad,row,that,should,be,skipped
8,3000,3900,900,1013,1300,287
''';

    final result = SyncService.parseSdEventsCsv(csv);

    expect(result.events, hasLength(2));
    expect(result.malformedRows, 1);
    expect(result.events.first.eventId, '7');
    expect(result.events.first.durationMs, 1500);
    expect(result.events.first.peakMbar, 1420.5);
  });

  test('extracts events.csv from a tagged SD transfer payload', () {
    const payload = '''
FILE:raw.csv
event_id,time_ms,pressure_mbar,baseline_mbar,delta_mbar,state
7,1000,1200,1010,190,start
END_FILE
FILE:events.csv
event_id,start_ms,end_ms,duration_ms,baseline_mbar,peak_mbar,delta_mbar
7,1000,2500,1500,1012.5,1420.5,408
END_FILE
SYNC_END
''';

    final bundle = SyncService.parseSdTransferPayload(payload);

    expect(bundle.hasData, isTrue);
    expect(bundle.eventsCsv, contains('duration_ms'));
    expect(bundle.rawCsv, contains('pressure_mbar'));
  });

  test('extracts events.csv from an events-only SD transfer payload', () {
    const payload = '''
FILE:events.csv
event_id,start_ms,end_ms,duration_ms,baseline_mbar,peak_mbar,delta_mbar
7,1000,2500,1500,1012.5,1420.5,408
END_FILE
SYNC_END
''';

    final bundle = SyncService.parseSdTransferPayload(payload);
    final parsed = SyncService.parseSdEventsCsv(bundle.eventsCsv);

    expect(bundle.hasData, isTrue);
    expect(bundle.rawCsv, isEmpty);
    expect(parsed.events, hasLength(1));
    expect(parsed.events.single.eventId, '7');
  });

  test('builds importable pain events and skips duplicate SD keys', () {
    final parsed = SyncService.parseSdEventsCsv('''
event_id,start_ms,end_ms,duration_ms,baseline_mbar,peak_mbar,delta_mbar
7,1000,2500,1500,1012.5,1420.5,408
8,3000,3900,900,1013,1300,287
''');
    final now = DateTime(2026, 6, 19, 12);
    final existing = PainEvent(
      id: 'existing',
      patientId: 'patient-1',
      timestamp: now,
      painLevel: 6,
      peakPressure: 1420.5,
      averagePeakPressure: 1420.5,
      normalizedSas: 41,
      baselinePressure: 1012.5,
      mvsPressure: 2000,
      source: 'sd_sync',
      externalSampleId: 'sd:7:1000:1500:1420.500',
    );

    final result = SyncService.buildPainEventsForImport(
      sdEvents: parsed.events,
      patientId: 'patient-1',
      calibration: Calibration(
        id: 'cal-1',
        patientId: 'patient-1',
        baselinePressure: 1000,
        mvsPressure: 2000,
        samplesUsed: 10,
        createdAt: now,
      ),
      existingEvents: [existing],
      syncCompletedAt: now,
      deviceId: 'PressureTX',
    );

    expect(result.events, hasLength(1));
    expect(result.duplicatesSkipped, 1);
    expect(result.events.single.externalSampleId, startsWith('sd:8:'));
    expect(result.events.single.source, 'sd_sync');
    expect([2, 4, 6, 8, 10], contains(result.events.single.painLevel));
    expect(result.events.single.timestamp, now);
    expect(
      result.events.single.startTime,
      now.subtract(const Duration(milliseconds: 900)),
    );
  });
}
