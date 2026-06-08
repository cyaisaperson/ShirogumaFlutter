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

  test('live calibration auto-stop waits for extended stable peak samples', () {
    final baseline = List<double>.generate(20, (index) => 1000 + (index % 2));
    final earlySqueeze = <double>[1015, 1210, 1800, 2260, 2300];
    final shortPeakHold = <double>[
      1015,
      1210,
      1800,
      2240,
      2260,
      2280,
      2300,
      2290,
      2270,
      2255,
      2245,
      2235,
    ];
    final extendedPeakHold = <double>[
      ...shortPeakHold,
      2265,
      2275,
      2285,
      2295,
      2288,
      2278,
      2268,
      2258,
    ];

    expect(
      DeviceState.autoStopLiveCalibrationResult([...baseline, ...earlySqueeze]),
      isNull,
    );
    expect(
      DeviceState.autoStopLiveCalibrationResult([
        ...baseline,
        ...shortPeakHold,
      ]),
      isNull,
    );

    final result = DeviceState.autoStopLiveCalibrationResult([
      ...baseline,
      ...extendedPeakHold,
    ]);

    expect(result, isNotNull);
    expect(result!.valid, isTrue);
    expect(result.reason, contains('Stable MVS found'));
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
