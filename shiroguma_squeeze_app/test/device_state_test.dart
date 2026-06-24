import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/app_settings.dart';
import 'package:shiroguma_squeeze_app/models/calibration.dart';
import 'package:shiroguma_squeeze_app/models/pain_event.dart';
import 'package:shiroguma_squeeze_app/services/ble_service.dart';
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
    'live calibration uses middle hold samples after release to baseline',
    () {
      final samples = <double>[
        1010,
        1250,
        1600,
        1900,
        2200,
        ...List<double>.generate(20, (index) => 2240.0 + index),
        2100,
        1700,
        1300,
        1040,
        1020,
        1010,
        1008,
        1006,
      ];

      final result = DeviceState.calculateLiveMvsCalibration(
        baselinePressure: 1000,
        samples: samples,
      );

      expect(result.valid, isTrue);
      expect(result.baselinePressure, 1000);
      expect(result.mvsPressure, closeTo(2249.5, 0.1));
      expect(result.samplesUsed, 10);
    },
  );

  test('live calibration auto-stops after squeeze returns to baseline', () {
    final ramp = <double>[1015, 1210, 1800, 2240, 2260, 2280];
    final hold = List<double>.generate(20, (index) => 2260 + index % 6);
    final release = <double>[1900, 1500, 1200];
    final baselineReturn = List<double>.generate(10, (index) => 1020.0 + index);

    expect(
      DeviceState.autoStopLiveCalibrationResult(
        baselinePressure: 1000,
        samples: [...ramp, ...hold, ...release],
      ),
      isNull,
    );

    final result = DeviceState.autoStopLiveCalibrationResult(
      baselinePressure: 1000,
      samples: [...ramp, ...hold, ...release, ...baselineReturn],
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

  test(
    'reconnectNow starts a fresh connect attempt while reconnecting',
    () async {
      final fakeBleService = _FakeBleService();
      final state = DeviceState(bleServiceFactory: (_) => fakeBleService);

      await state.connect(const AppSettings());
      expect(fakeBleService.connectAttempts, 1);
      expect(state.status, DeviceConnectionStatus.connected);

      fakeBleService.emitConnectionState(BluetoothConnectionState.disconnected);
      expect(state.status, DeviceConnectionStatus.reconnecting);

      await state.reconnectNow();

      expect(fakeBleService.connectAttempts, 2);
      expect(state.status, DeviceConnectionStatus.connected);
    },
  );

  test(
    'reconnectNow uses fallback settings when no previous connection exists',
    () async {
      final fakeBleService = _FakeBleService();
      final state = DeviceState(bleServiceFactory: (_) => fakeBleService);

      await state.reconnectNow(const AppSettings());

      expect(fakeBleService.connectAttempts, 1);
      expect(state.status, DeviceConnectionStatus.connected);
    },
  );

  test(
    'SD Card Mode still saves live BLE squeeze events while connected',
    () async {
      final fakeBleService = _FakeBleService();
      final savedEvents = <PainEvent>[];
      final state = DeviceState(bleServiceFactory: (_) => fakeBleService);
      const settings = AppSettings(dataMode: DataMode.sdCard);

      state.configureLiveDetection(
        activePatientId: 'patient-sd-live',
        calibration: Calibration(
          id: 'calibration-sd-live',
          patientId: 'patient-sd-live',
          baselinePressure: 1000,
          mvsPressure: 2000,
          samplesUsed: 12,
          createdAt: DateTime(2026, 6, 24),
        ),
        settings: settings,
        onPainEvent: (event) async {
          savedEvents.add(event);
        },
      );

      await state.connect(settings);
      expect(state.liveSavingStatus, 'Live saving ready');

      fakeBleService.emitPressure(1010);
      fakeBleService.emitPressure(1080);
      fakeBleService.emitPressure(1450);
      fakeBleService.emitPressure(1500);
      fakeBleService.emitPressure(1490);
      fakeBleService.emitPressure(1010);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      fakeBleService.emitPressure(1005);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(savedEvents, hasLength(1));
      expect(savedEvents.single.patientId, 'patient-sd-live');
      expect(savedEvents.single.source, 'live_ble');
    },
  );
}

class _FakeBleService extends BleService {
  int connectAttempts = 0;
  void Function(double pressure)? onPressure;
  void Function(BluetoothConnectionState state)? onConnectionState;

  @override
  Future<void> connect({
    required void Function(double pressure) onPressure,
    required void Function(int batteryPercent) onBattery,
    void Function(BluetoothConnectionState state)? onConnectionState,
  }) async {
    connectAttempts += 1;
    this.onPressure = onPressure;
    this.onConnectionState = onConnectionState;
  }

  void emitPressure(double pressure) {
    onPressure?.call(pressure);
  }

  void emitConnectionState(BluetoothConnectionState state) {
    onConnectionState?.call(state);
  }
}
