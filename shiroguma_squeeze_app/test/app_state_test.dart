import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiroguma_squeeze_app/models/pain_event.dart';
import 'package:shiroguma_squeeze_app/state/app_state.dart';

void main() {
  test('manual patients persist across AppState instances', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState.seeded();

    await state.addPatient(
      name: 'Mina Chen',
      patientCode: 'P-004',
      age: 9,
      description: 'Needs a quiet room for calibration.',
    );

    final reloadedState = AppState.seeded();
    await reloadedState.loadPersistedState();

    expect(
      reloadedState.patients.any(
        (patient) =>
            patient.name == 'Mina Chen' && patient.patientCode == 'P-004',
      ),
      isTrue,
    );
  });

  test('next patient code uses the next available P-00x value', () {
    final state = AppState.seeded();

    expect(state.nextPatientCode, 'P-004');
  });

  test('active patient persists across AppState instances', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState.seeded();
    final patientId = state.patients.last.id;

    await state.setActivePatient(patientId);

    final reloadedState = AppState.seeded();
    await reloadedState.loadPersistedState();

    expect(reloadedState.settings.activePatientId, patientId);
    expect(reloadedState.activePatient?.id, patientId);
  });

  test('calibration persists across AppState instances', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState.seeded();
    final patientId = state.patients.first.id;

    await state.saveCalibration(
      patientId: patientId,
      baselinePressure: 1012,
      mvsPressure: 2310,
      samplesUsed: 12,
      notes: 'Manual calibration',
    );

    final reloadedState = AppState.seeded();
    await reloadedState.loadPersistedState();
    final calibration = reloadedState.calibrations.firstWhere(
      (calibration) => calibration.patientId == patientId,
    );

    expect(calibration.baselinePressure, 1012);
    expect(calibration.mvsPressure, 2310);
    expect(calibration.samplesUsed, 12);
    expect(calibration.notes, 'Manual calibration');
  });

  test('pain events persist across AppState instances', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState.seeded();
    final patientId = state.patients.first.id;
    final event = PainEvent(
      id: 'event-persisted-test',
      patientId: patientId,
      timestamp: DateTime(2026, 6, 4, 9, 30),
      startTime: DateTime(2026, 6, 4, 9, 29, 55),
      endTime: DateTime(2026, 6, 4, 9, 30, 5),
      durationMs: 10000,
      painLevel: 2,
      peakPressure: 1400,
      averagePeakPressure: 1388,
      normalizedSas: 52,
      baselinePressure: 1010,
      mvsPressure: 2250,
      source: 'live_ble',
      deviceId: 'PressureTX',
      notes: 'Persisted test event',
    );

    await state.savePainEvent(event);

    final reloadedState = AppState.seeded();
    await reloadedState.loadPersistedState();
    final persistedEvent = reloadedState.painEvents.firstWhere(
      (event) => event.id == 'event-persisted-test',
    );

    expect(persistedEvent.patientId, patientId);
    expect(persistedEvent.source, 'live_ble');
    expect(persistedEvent.deviceId, 'PressureTX');
    expect(persistedEvent.normalizedSas, 52);
    expect(persistedEvent.painLevel, 2);
  });

  test('legacy pain events migrate from 1-5 scale to 2-10 scale', () async {
    final legacyEvent = PainEvent(
      id: 'event-legacy-scale',
      patientId: 'patient-anya',
      timestamp: DateTime(2026, 6, 4, 9, 30),
      painLevel: 2,
      peakPressure: 1400,
      averagePeakPressure: 1388,
      normalizedSas: 36,
      baselinePressure: 1010,
      mvsPressure: 2250,
      source: 'live_ble',
    );
    SharedPreferences.setMockInitialValues({
      'shiroguma.pain_events.v1': jsonEncode([legacyEvent.toJson()]),
    });

    final state = AppState.seeded();
    await state.loadPersistedState();
    final migratedEvent = state.painEvents.firstWhere(
      (event) => event.id == 'event-legacy-scale',
    );
    final preferences = await SharedPreferences.getInstance();

    expect(migratedEvent.painLevel, 4);
    expect(preferences.getString('shiroguma.pain_events.v1'), isNull);
    expect(preferences.getString('shiroguma.pain_events.v2'), isNotNull);
  });

  test('v2 pain events keep level 2 without legacy remapping', () async {
    final currentEvent = PainEvent(
      id: 'event-current-scale',
      patientId: 'patient-anya',
      timestamp: DateTime(2026, 6, 4, 9, 30),
      painLevel: 2,
      peakPressure: 1260,
      averagePeakPressure: 1238,
      normalizedSas: 18,
      baselinePressure: 1008,
      mvsPressure: 2250,
      source: 'live_ble',
    );
    SharedPreferences.setMockInitialValues({
      'shiroguma.pain_events.v2': jsonEncode([currentEvent.toJson()]),
    });

    final state = AppState.seeded();
    await state.loadPersistedState();
    final restoredEvent = state.painEvents.firstWhere(
      (event) => event.id == 'event-current-scale',
    );

    expect(restoredEvent.painLevel, 2);
  });
  test(
    'delete patient removes profile calibration events and active selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState.seeded();
      final patientId = state.patients.first.id;

      await state.setActivePatient(patientId);
      await state.saveCalibration(
        patientId: patientId,
        baselinePressure: 1000,
        mvsPressure: 2000,
        samplesUsed: 10,
      );
      await state.savePainEvent(
        PainEvent(
          id: 'event-delete-test',
          patientId: patientId,
          timestamp: DateTime(2026, 6, 4, 9, 30),
          startTime: DateTime(2026, 6, 4, 9, 29, 55),
          endTime: DateTime(2026, 6, 4, 9, 30, 5),
          durationMs: 10000,
          painLevel: 2,
          peakPressure: 1400,
          averagePeakPressure: 1388,
          normalizedSas: 52,
          baselinePressure: 1010,
          mvsPressure: 2250,
          source: 'live_ble',
        ),
      );

      await state.deletePatient(patientId);

      expect(state.patients.any((patient) => patient.id == patientId), isFalse);
      expect(
        state.calibrations.any(
          (calibration) => calibration.patientId == patientId,
        ),
        isFalse,
      );
      expect(
        state.painEvents.any((event) => event.patientId == patientId),
        isFalse,
      );
      expect(state.settings.activePatientId, isNull);
    },
  );
}
