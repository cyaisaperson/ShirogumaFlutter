import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/state/device_state.dart';

void main() {
  test('marks battery stale after the configured freshness window', () {
    final now = DateTime(2026, 6, 8, 12);

    expect(
      DeviceState.isTimestampStale(
        lastUpdate: now.subtract(const Duration(seconds: 31)),
        now: now,
        staleAfter: const Duration(seconds: 30),
      ),
      isTrue,
    );
    expect(
      DeviceState.isTimestampStale(
        lastUpdate: now.subtract(const Duration(seconds: 30)),
        now: now,
        staleAfter: const Duration(seconds: 30),
      ),
      isFalse,
    );
    expect(
      DeviceState.isTimestampStale(
        lastUpdate: null,
        now: now,
        staleAfter: const Duration(seconds: 30),
      ),
      isFalse,
    );
  });

  test(
    'live calibration uses idle baseline and stable three second MVS region',
    () {
      final shortHold = List<double>.generate(149, (index) => 2250 + index % 4);
      final stableHold = List<double>.generate(
        150,
        (index) => 2250 + index % 4,
      );

      final shortResult = DeviceState.calculateLiveMvsCalibration(
        baselinePressure: 1000,
        samples: shortHold,
      );
      expect(shortResult.valid, isFalse);
      expect(shortResult.reason, contains('Hold maximum squeeze steady'));

      final result = DeviceState.calculateLiveMvsCalibration(
        baselinePressure: 1000,
        samples: stableHold,
      );

      expect(result.valid, isTrue);
      expect(result.baselinePressure, 1000);
      expect(result.mvsPressure, closeTo(2251.5, 1));
      expect(result.samplesUsed, 150);
    },
  );

  test('live calibration auto-stop waits for stable max-force region', () {
    final ramp = <double>[1015, 1210, 1800, 2240, 2260, 2280, 2300];
    final unstableHold = List<double>.generate(
      150,
      (index) => index.isEven ? 2200 : 2350,
    );
    final stableHold = List<double>.generate(150, (index) => 2280 + index % 5);

    expect(
      DeviceState.autoStopLiveCalibrationResult(
        baselinePressure: 1000,
        samples: [...ramp, ...unstableHold],
      ),
      isNull,
    );

    final result = DeviceState.autoStopLiveCalibrationResult(
      baselinePressure: 1000,
      samples: [...ramp, ...stableHold],
    );

    expect(result, isNotNull);
    expect(result!.valid, isTrue);
    expect(result.reason, contains('Stable MVS found'));
  });

  test('live calibration rejects missing idle baseline', () {
    final result = DeviceState.calculateLiveMvsCalibration(
      baselinePressure: null,
      samples: List<double>.generate(150, (index) => 2250),
    );

    expect(result.valid, isFalse);
    expect(result.reason, contains('idle baseline'));
  });
}
