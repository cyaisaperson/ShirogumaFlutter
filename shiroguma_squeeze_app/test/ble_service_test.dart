import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/services/ble_service.dart';

void main() {
  test('parses little-endian pressure float notifications', () {
    final pressure = BleService.parsePressureBytes([0x00, 0x00, 0xFA, 0x43]);

    expect(pressure, closeTo(500, 0.001));
  });

  test('rejects malformed pressure notifications', () {
    expect(
      () => BleService.parsePressureBytes([1, 2, 3]),
      throwsFormatException,
    );
  });

  test('parses battery percentage notifications', () {
    expect(BleService.parseBatteryBytes([87]), 87);
  });

  test('clamps malformed battery percentage notifications', () {
    expect(BleService.parseBatteryBytes([150]), 100);
    expect(() => BleService.parseBatteryBytes([]), throwsFormatException);
  });
}
