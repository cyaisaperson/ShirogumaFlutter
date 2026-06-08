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
}
