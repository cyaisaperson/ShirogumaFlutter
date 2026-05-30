import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../models/patient.dart';
import 'mock_data.dart';

class AppState extends ChangeNotifier {
  AppState({
    required List<Patient> patients,
    required List<Calibration> calibrations,
    required List<PainEvent> painEvents,
    required AppSettings settings,
  }) : _patients = List.unmodifiable(patients),
       _calibrations = List.unmodifiable(calibrations),
       _painEvents = List.unmodifiable(painEvents),
       _settings = settings;

  factory AppState.seeded() {
    return AppState(
      patients: MockData.patients(),
      calibrations: MockData.calibrations(),
      painEvents: MockData.painEvents(),
      settings: MockData.settings(),
    );
  }

  final List<Patient> _patients;
  final List<Calibration> _calibrations;
  final List<PainEvent> _painEvents;
  AppSettings _settings;

  List<Patient> get patients => _patients;
  List<Calibration> get calibrations => _calibrations;
  List<PainEvent> get painEvents => _painEvents;
  AppSettings get settings => _settings;

  Patient? get activePatient {
    final activePatientId = _settings.activePatientId;
    if (activePatientId == null) {
      return null;
    }
    return _patientById(activePatientId);
  }

  Calibration? get activeCalibration {
    final patient = activePatient;
    if (patient == null) {
      return null;
    }
    for (final calibration in _calibrations) {
      if (calibration.patientId == patient.id) {
        return calibration;
      }
    }
    return null;
  }

  List<PainEvent> get activePatientEvents {
    final patient = activePatient;
    if (patient == null) {
      return const [];
    }
    final events =
        _painEvents
            .where(
              (event) => event.patientId == patient.id && event.painLevel > 0,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(events);
  }

  void setActivePatient(String patientId) {
    if (_patientById(patientId) == null ||
        _settings.activePatientId == patientId) {
      return;
    }
    _settings = _settings.copyWith(activePatientId: patientId);
    notifyListeners();
  }

  Patient? _patientById(String patientId) {
    for (final patient in _patients) {
      if (patient.id == patientId) {
        return patient;
      }
    }
    return null;
  }
}
