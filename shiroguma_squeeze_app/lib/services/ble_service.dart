import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BleService({
    this.deviceName = 'PressureTX',
    this.serviceUuid = '12345678-1234-1234-1234-1234567890ab',
    this.pressureCharacteristicUuid = 'abcd1234-5678-4321-abcd-1234567890ab',
    this.batteryCharacteristicUuid = 'abcd1234-5678-4321-abcd-1234567890ac',
  });

  final String deviceName;
  final String serviceUuid;
  final String pressureCharacteristicUuid;
  final String batteryCharacteristicUuid;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _pressureCharacteristic;
  BluetoothCharacteristic? _batteryCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _pressureSubscription;
  StreamSubscription<List<int>>? _batterySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  Future<BluetoothDevice> scanForDevice({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final completer = Completer<BluetoothDevice>();
    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = _displayNameFor(result.device, result.advertisementData);
        if (name == deviceName && !completer.isCompleted) {
          completer.complete(result.device);
        }
      }
    });

    await FlutterBluePlus.startScan(withNames: [deviceName], timeout: timeout);

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  Future<void> connect({
    required void Function(double pressure) onPressure,
    required void Function(int batteryPercent) onBattery,
    void Function(BluetoothConnectionState state)? onConnectionState,
  }) async {
    final device = await scanForDevice();
    _device = device;
    _connectionSubscription = device.connectionState.listen(onConnectionState);
    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 12),
    );
    final services = await device.discoverServices();
    _pressureCharacteristic = _findCharacteristic(
      services,
      pressureCharacteristicUuid,
    );
    _batteryCharacteristic = _findCharacteristic(
      services,
      batteryCharacteristicUuid,
    );

    await _pressureCharacteristic!.setNotifyValue(true);
    _pressureSubscription = _pressureCharacteristic!.lastValueStream.listen(
      (value) => onPressure(parsePressureBytes(value)),
    );

    await _batteryCharacteristic!.setNotifyValue(true);
    _batterySubscription = _batteryCharacteristic!.lastValueStream.listen(
      (value) => onBattery(parseBatteryBytes(value)),
    );
  }

  Future<void> disconnect() async {
    await _pressureSubscription?.cancel();
    await _batterySubscription?.cancel();
    await _connectionSubscription?.cancel();
    _pressureSubscription = null;
    _batterySubscription = null;
    _connectionSubscription = null;
    await _pressureCharacteristic
        ?.setNotifyValue(false)
        .catchError((_) => false);
    await _batteryCharacteristic
        ?.setNotifyValue(false)
        .catchError((_) => false);
    await _device?.disconnect().catchError((_) {});
    _pressureCharacteristic = null;
    _batteryCharacteristic = null;
    _device = null;
  }

  static double parsePressureBytes(List<int> bytes) {
    if (bytes.length != 4) {
      throw FormatException(
        'Pressure notification must be 4 bytes, got ${bytes.length}.',
      );
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return data.getFloat32(0, Endian.little);
  }

  static int parseBatteryBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('Battery notification must include 1 byte.');
    }
    return bytes.first.clamp(0, 100);
  }

  static BluetoothCharacteristic _findCharacteristic(
    List<BluetoothService> services,
    String characteristicUuid,
  ) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.str.toLowerCase() ==
            characteristicUuid.toLowerCase()) {
          return characteristic;
        }
      }
    }
    throw StateError('Characteristic $characteristicUuid not found.');
  }

  static String _displayNameFor(
    BluetoothDevice device,
    AdvertisementData advertisementData,
  ) {
    if (advertisementData.advName.isNotEmpty) {
      return advertisementData.advName;
    }
    if (device.advName.isNotEmpty) {
      return device.advName;
    }
    return device.platformName;
  }
}
