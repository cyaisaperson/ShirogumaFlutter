import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/app_settings.dart';
import 'package:shiroguma_squeeze_app/services/ble_service.dart';
import 'package:shiroguma_squeeze_app/state/device_state.dart';

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

  test('normalizes blank discovered device names', () {
    final namedDevice = BleDiscoveredDevice(
      id: 'AA:BB:CC',
      name: 'PressureTX',
      rssi: -42,
    );
    final unnamedDevice = BleDiscoveredDevice(
      id: '11:22:33',
      name: '',
      rssi: -80,
    );

    expect(namedDevice.displayName, 'PressureTX');
    expect(unnamedDevice.displayName, 'Unknown device');
  });

  test('normalizes advertised device names for matching', () {
    expect(BleService.isMatchingDeviceName('PressureTX', 'PressureTX'), isTrue);
    expect(
      BleService.isMatchingDeviceName('PressureTX', 'Pressure TX'),
      isTrue,
    );
    expect(BleService.isMatchingDeviceName('PressureTX', 'pressuretx'), isTrue);
    expect(BleService.isMatchingDeviceName('Presure TX', 'PressureTX'), isTrue);
  });

  test('formats scan timeout as a device search message', () {
    final message = DeviceState.bleErrorMessage(
      TimeoutException('Future not completed', const Duration(seconds: 8)),
      const AppSettings(),
    );

    expect(
      message,
      'No device found. Check that it is turned on, nearby, and charged.',
    );
    expect(message, isNot(contains('TimeoutException')));
  });

  test('formats common BLE setup errors for users', () {
    expect(
      DeviceState.bleErrorMessage(
        StateError('Bluetooth permission denied: BlePermission.bluetoothScan'),
        const AppSettings(),
      ),
      contains('Bluetooth permission missing'),
    );
    expect(
      DeviceState.bleErrorMessage(
        StateError('Bluetooth is not enabled.'),
        const AppSettings(),
      ),
      contains('Bluetooth is off or unavailable'),
    );
    expect(
      DeviceState.bleErrorMessage(
        StateError('Characteristic abcd not found.'),
        const AppSettings(),
      ),
      contains('pressure service not available'),
    );
  });

  test('selects Android BLE permissions by SDK version', () {
    expect(BlePermissionPlan.forAndroidSdk(31), [
      BlePermission.bluetoothScan,
      BlePermission.bluetoothConnect,
    ]);
    expect(BlePermissionPlan.forAndroidSdk(30), [
      BlePermission.accessFineLocation,
    ]);
  });
}
