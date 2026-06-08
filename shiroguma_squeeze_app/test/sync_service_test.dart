import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/pain_event.dart';
import 'package:shiroguma_squeeze_app/services/sync_service.dart';

void main() {
  test(
    'SD card sync placeholder reports future flow without importing',
    () async {
      final result = await SyncService().prepareSdCardSync();

      expect(result.status, SyncPlaceholderStatus.notImplemented);
      expect(result.importedEvents, 0);
      expect(result.message, contains('not implemented'));
      expect(result.futureSteps, contains('parse historical pressure samples'));
      expect(result.futureSteps, contains('avoid duplicate imports'));
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
}
