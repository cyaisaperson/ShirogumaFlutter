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

  test('live calibration computes stable baseline and MVS', () {
    final samples = <double>[
      ...List<double>.generate(20, (index) => 1000 + (index % 3)),
      1010,
      1050,
      1200,
      1500,
      1800,
      2100,
      2250,
      2300,
      2280,
      2240,
      2100,
      1700,
      1300,
    ];

    final result = DeviceState.calculateLiveCalibration(samples);

    expect(result.valid, isTrue);
    expect(result.baselinePressure, closeTo(1001, 1));
    expect(result.mvsPressure, greaterThan(2200));
    expect(result.samplesUsed, greaterThan(0));
  });

  test('live calibration rejects unstable baseline', () {
    final samples = <double>[
      ...List<double>.generate(20, (index) => index.isEven ? 950 : 1100),
      1300,
      1500,
      1700,
    ];

    final result = DeviceState.calculateLiveCalibration(samples);

    expect(result.valid, isFalse);
    expect(result.reason, contains('Baseline unstable'));
  });
}
