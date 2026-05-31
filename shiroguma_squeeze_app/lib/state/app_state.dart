import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) : _patients = List.of(patients),
       _calibrations = List.of(calibrations),
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
  static const _patientsStorageKey = 'shiroguma.patients.v1';

  List<Patient> get patients => List.unmodifiable(_patients);
  List<Calibration> get calibrations => List.unmodifiable(_calibrations);
  List<PainEvent> get painEvents => _painEvents;
  AppSettings get settings => _settings;

  String get nextPatientCode {
    var maxNumber = 0;
    final codePattern = RegExp(r'^P-(\d+)$');
    for (final patient in _patients) {
      final match = codePattern.firstMatch(patient.patientCode.trim());
      if (match == null) {
        continue;
      }
      final number = int.tryParse(match.group(1)!);
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }
    final nextNumber = maxNumber + 1;
    return 'P-${nextNumber.toString().padLeft(3, '0')}';
  }

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

  Future<void> loadPersistedPatients() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPatients = preferences.getString(_patientsStorageKey);
    if (encodedPatients == null) {
      return;
    }
    final decodedPatients = jsonDecode(encodedPatients) as List<dynamic>;
    _patients
      ..clear()
      ..addAll(
        decodedPatients.map(
          (patientJson) =>
              Patient.fromJson(Map<String, Object?>.from(patientJson as Map)),
        ),
      );
    if (_settings.activePatientId != null &&
        _patientById(_settings.activePatientId!) == null) {
      _settings = _settings.copyWith(clearActivePatient: true);
    }
    notifyListeners();
  }

  bool isPatientCodeTaken(String patientCode, {String? exceptPatientId}) {
    final normalizedCode = patientCode.trim().toLowerCase();
    return _patients.any(
      (patient) =>
          patient.id != exceptPatientId &&
          patient.patientCode.trim().toLowerCase() == normalizedCode,
    );
  }

  Future<void> addPatient({
    required String name,
    required String patientCode,
    required String description,
    int? age,
  }) async {
    final now = DateTime.now();
    final patient = Patient(
      id: 'patient-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      patientCode: patientCode.trim(),
      age: age,
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _patients.insert(0, patient);
    _settings = _settings.copyWith(activePatientId: patient.id);
    notifyListeners();
    await _persistPatients();
  }

  Future<void> updatePatient(Patient updatedPatient) async {
    final index = _patients.indexWhere(
      (patient) => patient.id == updatedPatient.id,
    );
    if (index == -1) {
      return;
    }
    _patients[index] = updatedPatient.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _persistPatients();
  }

  void saveCalibration({
    required String patientId,
    required double baselinePressure,
    required double mvsPressure,
    int samplesUsed = 0,
    String? notes,
  }) {
    _calibrations.removeWhere(
      (calibration) => calibration.patientId == patientId,
    );
    _calibrations.insert(
      0,
      Calibration(
        id: 'calibration-${DateTime.now().microsecondsSinceEpoch}',
        patientId: patientId,
        baselinePressure: baselinePressure,
        mvsPressure: mvsPressure,
        samplesUsed: samplesUsed,
        createdAt: DateTime.now(),
        notes: notes,
      ),
    );
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

  Future<void> _persistPatients() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPatients = jsonEncode(
      _patients.map((patient) => patient.toJson()).toList(),
    );
    await preferences.setString(_patientsStorageKey, encodedPatients);
  }
}
