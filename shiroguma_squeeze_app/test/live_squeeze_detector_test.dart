import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/app_settings.dart';
import 'package:shiroguma_squeeze_app/models/calibration.dart';
import 'package:shiroguma_squeeze_app/services/live_squeeze_detector.dart';

void main() {
  test('detects one live BLE squeeze after debounce', () {
    final detector = LiveSqueezeDetector(
      patientId: 'patient-test',
      calibration: Calibration(
        id: 'calibration-test',
        patientId: 'patient-test',
        baselinePressure: 1000,
        mvsPressure: 2000,
        samplesUsed: 12,
        createdAt: DateTime(2026, 6, 8),
      ),
      settings: const AppSettings(
        thresholdPercentAboveBaseline: 3,
        peakWindowSize: 4,
      ),
      deviceId: 'PressureTX',
      belowThresholdDebounce: const Duration(milliseconds: 100),
      cooldown: const Duration(milliseconds: 800),
    );
    final start = DateTime(2026, 6, 8, 10);
    final pressures = [
      1001.0,
      1045.0,
      1120.0,
      1380.0,
      1540.0,
      1500.0,
      1300.0,
      1010.0,
      1005.0,
      1004.0,
    ];

    final events = <Object>[];
    for (var index = 0; index < pressures.length; index += 1) {
      final event = detector.addPressureSample(
        pressure: pressures[index],
        timestamp: start.add(Duration(milliseconds: index * 50)),
      );
      if (event != null) events.add(event);
    }

    expect(events, hasLength(1));
    final event = events.single as dynamic;
    expect(event.patientId, 'patient-test');
    expect(event.source, 'live_ble');
    expect(event.deviceId, 'PressureTX');
    expect(event.peakPressure, 1540);
    expect(event.normalizedSas, greaterThan(0));
    expect([2, 4, 6, 8, 10], contains(event.painLevel));
    expect(event.startTime, start.add(const Duration(milliseconds: 50)));
    expect(event.endTime, start.add(const Duration(milliseconds: 450)));
  });

  test('cooldown prevents duplicate events from the same squeeze', () {
    final detector = LiveSqueezeDetector(
      patientId: 'patient-test',
      calibration: Calibration(
        id: 'calibration-test',
        patientId: 'patient-test',
        baselinePressure: 1000,
        mvsPressure: 2000,
        samplesUsed: 12,
        createdAt: DateTime(2026, 6, 8),
      ),
      settings: const AppSettings(),
      belowThresholdDebounce: const Duration(milliseconds: 50),
      cooldown: const Duration(seconds: 1),
    );
    final start = DateTime(2026, 6, 8, 10);
    final samples = [
      (1040.0, 0),
      (1300.0, 50),
      (1000.0, 100),
      (1000.0, 150),
      (1400.0, 250),
      (1000.0, 300),
      (1000.0, 350),
    ];

    final events = samples
        .map(
          (sample) => detector.addPressureSample(
            pressure: sample.$1,
            timestamp: start.add(Duration(milliseconds: sample.$2)),
          ),
        )
        .whereType<Object>()
        .toList();

    expect(events, hasLength(1));
  });
}
