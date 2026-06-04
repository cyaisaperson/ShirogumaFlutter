import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BlePermission { bluetoothScan, bluetoothConnect, accessFineLocation }

class BlePermissionPlan {
  static List<BlePermission> forAndroidSdk(int sdkInt) {
    if (sdkInt >= 31) {
      return const [
        BlePermission.bluetoothScan,
        BlePermission.bluetoothConnect,
      ];
    }
    return const [BlePermission.accessFineLocation];
  }
}

class BleDiscoveredDevice {
  const BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.device,
  });

  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice? device;

  String get displayName {
    if (name.trim().isEmpty) {
      return 'Unknown device';
    }
    return name.trim();
  }
}

class BleService {
  static const defaultDeviceName = 'PressureTX';

  BleService({
    this.deviceName = defaultDeviceName,
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

  Stream<List<BleDiscoveredDevice>> scanNearbyDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    await _prepareForBle('browse scan');
    debugPrint('[BLE] Starting browse scan for ${timeout.inSeconds}s');
    await FlutterBluePlus.startScan(timeout: timeout);
    yield* FlutterBluePlus.scanResults.map((results) {
      final discovered = <String, BleDiscoveredDevice>{};
      for (final result in results) {
        final name = _displayNameFor(result.device, result.advertisementData);
        debugPrint(
          '[BLE] Device found: name="$name", id=${result.device.remoteId.str}, rssi=${result.rssi}',
        );
        discovered[result.device.remoteId.str] = BleDiscoveredDevice(
          id: result.device.remoteId.str,
          name: name,
          rssi: result.rssi,
          device: result.device,
        );
      }
      final devices = discovered.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      return devices;
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<BluetoothDevice> scanForDevice({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await _prepareForBle('auto scan');
    final completer = Completer<BluetoothDevice>();
    final scanNames = <String>{
      deviceName.trim(),
      defaultDeviceName,
    }.where((name) => name.isNotEmpty).toList();
    debugPrint(
      '[BLE] Starting auto scan for ${timeout.inSeconds}s with names=$scanNames',
    );
    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = _displayNameFor(result.device, result.advertisementData);
        debugPrint(
          '[BLE] Device found: name="$name", id=${result.device.remoteId.str}, rssi=${result.rssi}',
        );
        if (isMatchingDeviceName(deviceName, name) && !completer.isCompleted) {
          debugPrint('[BLE] Matched device "$name" for auto connect');
          completer.complete(result.device);
        }
      }
    });

    await FlutterBluePlus.startScan(withNames: scanNames, timeout: timeout);

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
    await connectToDevice(
      device,
      onPressure: onPressure,
      onBattery: onBattery,
      onConnectionState: onConnectionState,
    );
  }

  Future<void> connectToDiscoveredDevice({
    required BleDiscoveredDevice discoveredDevice,
    required void Function(double pressure) onPressure,
    required void Function(int batteryPercent) onBattery,
    void Function(BluetoothConnectionState state)? onConnectionState,
  }) async {
    await _prepareForBle('connect to selected device');
    final device =
        discoveredDevice.device ?? BluetoothDevice.fromId(discoveredDevice.id);
    await connectToDevice(
      device,
      onPressure: onPressure,
      onBattery: onBattery,
      onConnectionState: onConnectionState,
    );
  }

  Future<void> connectToDevice(
    BluetoothDevice device, {
    required void Function(double pressure) onPressure,
    required void Function(int batteryPercent) onBattery,
    void Function(BluetoothConnectionState state)? onConnectionState,
  }) async {
    await _prepareForBle('connect');
    _device = device;
    _connectionSubscription = device.connectionState.listen(onConnectionState);
    debugPrint('[BLE] Connecting to ${device.remoteId.str}');
    await device.connect(
      license: License.nonprofit,
      timeout: const Duration(seconds: 12),
    );
    debugPrint('[BLE] Connect result: connected to ${device.remoteId.str}');
    final services = await device.discoverServices();
    debugPrint('[BLE] Service discovery complete: ${services.length} services');
    _pressureCharacteristic = _findCharacteristic(
      services,
      pressureCharacteristicUuid,
    );
    _batteryCharacteristic = _findCharacteristic(
      services,
      batteryCharacteristicUuid,
    );

    await _pressureCharacteristic!.setNotifyValue(true);
    debugPrint(
      '[BLE] Pressure notification subscription enabled: $pressureCharacteristicUuid',
    );
    _pressureSubscription = _pressureCharacteristic!.lastValueStream.listen(
      (value) => onPressure(parsePressureBytes(value)),
    );

    await _batteryCharacteristic!.setNotifyValue(true);
    debugPrint(
      '[BLE] Battery notification subscription enabled: $batteryCharacteristicUuid',
    );
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

  static bool isMatchingDeviceName(String expectedName, String advertisedName) {
    final normalizedExpected = _normalizeDeviceName(expectedName);
    final normalizedAdvertised = _normalizeDeviceName(advertisedName);
    if (normalizedAdvertised.isEmpty) {
      return false;
    }
    return normalizedAdvertised == normalizedExpected ||
        normalizedAdvertised == _normalizeDeviceName(defaultDeviceName);
  }

  static String _normalizeDeviceName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _prepareForBle(String operation) async {
    debugPrint('[BLE] Preparing for $operation');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidBlePermissions();
    }
    await _ensureBluetoothEnabled();
  }

  Future<void> _requestAndroidBlePermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final permissions = BlePermissionPlan.forAndroidSdk(
      androidInfo.version.sdkInt,
    );
    debugPrint(
      '[BLE] Android SDK ${androidInfo.version.sdkInt}; requesting permissions: $permissions',
    );

    for (final permission in permissions) {
      final handlerPermission = _permissionHandlerPermission(permission);
      final beforeStatus = await handlerPermission.status;
      debugPrint('[BLE] Permission $permission before request: $beforeStatus');
      final afterStatus = beforeStatus.isGranted
          ? beforeStatus
          : await handlerPermission.request();
      debugPrint('[BLE] Permission $permission after request: $afterStatus');
      if (!afterStatus.isGranted) {
        throw StateError('Bluetooth permission denied: $permission');
      }
    }
  }

  Future<void> _ensureBluetoothEnabled() async {
    final adapterState = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 3),
      onTimeout: () => BluetoothAdapterState.unknown,
    );
    debugPrint('[BLE] Bluetooth adapter state: $adapterState');
    if (adapterState != BluetoothAdapterState.on) {
      throw StateError('Bluetooth is not enabled.');
    }
  }

  Permission _permissionHandlerPermission(BlePermission permission) {
    return switch (permission) {
      BlePermission.bluetoothScan => Permission.bluetoothScan,
      BlePermission.bluetoothConnect => Permission.bluetoothConnect,
      BlePermission.accessFineLocation => Permission.locationWhenInUse,
    };
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
