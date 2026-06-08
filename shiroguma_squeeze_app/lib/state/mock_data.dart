import '../models/app_settings.dart';
import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../models/patient.dart';

class MockData {
  static DateTime get _now => DateTime.now();

  static DateTime get _today {
    final now = _now;
    return DateTime(now.year, now.month, now.day);
  }

  static int get _currentWeekSampleOffset {
    final weekday = _now.weekday;
    return weekday == DateTime.monday ? -1 : 1;
  }

  static List<Patient> patients() {
    final createdAt = _today.subtract(const Duration(days: 21));
    return [
      Patient(
        id: 'patient-anya',
        name: 'Anya Rahimi',
        patientCode: 'P-001',
        age: 8,
        description:
            'Prefers right hand. Responds well to calm visual prompts.',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      Patient(
        id: 'patient-marcus',
        name: 'Marcus Tate',
        patientCode: 'P-002',
        age: 11,
        description:
            'Use short sessions and compare left/right hand separately.',
        createdAt: createdAt.add(const Duration(days: 2)),
        updatedAt: createdAt.add(const Duration(days: 2)),
      ),
      Patient(
        id: 'patient-joud',
        name: 'Joud Karam',
        patientCode: 'P-003',
        age: 6,
        description: 'Likes the orb view. Baseline can drift if grip changes.',
        createdAt: createdAt.add(const Duration(days: 5)),
        updatedAt: createdAt.add(const Duration(days: 5)),
      ),
    ];
  }

  static List<Calibration> calibrations() {
    final calibrationDay = _today.subtract(const Duration(days: 3));
    return [
      Calibration(
        id: 'calibration-anya',
        patientId: 'patient-anya',
        baselinePressure: 1008,
        mvsPressure: 2250,
        samplesUsed: 8,
        createdAt: calibrationDay,
      ),
      Calibration(
        id: 'calibration-marcus',
        patientId: 'patient-marcus',
        baselinePressure: 1014,
        mvsPressure: 2860,
        samplesUsed: 9,
        createdAt: calibrationDay.add(const Duration(hours: 2)),
      ),
      Calibration(
        id: 'calibration-joud',
        patientId: 'patient-joud',
        baselinePressure: 995,
        mvsPressure: 1980,
        samplesUsed: 7,
        createdAt: calibrationDay.add(const Duration(hours: 4)),
      ),
    ];
  }

  static List<PainEvent> painEvents() {
    return [
      _event(
        id: 'event-anya-today-level-1',
        patientId: 'patient-anya',
        dayOffset: 0,
        hour: 8,
        minute: 10,
        painLevel: 1,
        peakPressure: 1260,
        averagePeakPressure: 1238,
        normalizedSas: 18,
        baselinePressure: 1008,
        mvsPressure: 2250,
      ),
      _event(
        id: 'event-anya-today-1',
        patientId: 'patient-anya',
        dayOffset: 0,
        hour: 9,
        minute: 20,
        painLevel: 2,
        peakPressure: 1440,
        averagePeakPressure: 1398,
        normalizedSas: 31,
        baselinePressure: 1008,
        mvsPressure: 2250,
      ),
      _event(
        id: 'event-anya-today-level-3',
        patientId: 'patient-anya',
        dayOffset: 0,
        hour: 12,
        minute: 35,
        painLevel: 3,
        peakPressure: 1690,
        averagePeakPressure: 1640,
        normalizedSas: 55,
        baselinePressure: 1008,
        mvsPressure: 2250,
      ),
      _event(
        id: 'event-anya-today-level-4',
        patientId: 'patient-anya',
        dayOffset: 0,
        hour: 14,
        minute: 55,
        painLevel: 4,
        peakPressure: 1940,
        averagePeakPressure: 1875,
        normalizedSas: 70,
        baselinePressure: 1008,
        mvsPressure: 2250,
      ),
      _event(
        id: 'event-anya-today-level-5',
        patientId: 'patient-anya',
        dayOffset: 0,
        hour: 17,
        minute: 40,
        painLevel: 5,
        peakPressure: 2210,
        averagePeakPressure: 2160,
        normalizedSas: 93,
        baselinePressure: 1008,
        mvsPressure: 2250,
      ),
      _event(
        id: 'event-anya-yesterday-1',
        patientId: 'patient-anya',
        dayOffset: 1,
        hour: 15,
        minute: 5,
        painLevel: 4,
        peakPressure: 2010,
        averagePeakPressure: 1964,
        normalizedSas: 77,
        baselinePressure: 1008,
        mvsPressure: 2250,
      ),
      _event(
        id: 'event-marcus-today-1',
        patientId: 'patient-marcus',
        dayOffset: 0,
        hour: 10,
        minute: 45,
        painLevel: 3,
        peakPressure: 1985,
        averagePeakPressure: 1902,
        normalizedSas: 48,
        baselinePressure: 1014,
        mvsPressure: 2860,
      ),
      _event(
        id: 'event-marcus-week-1',
        patientId: 'patient-marcus',
        dayOffset: _currentWeekSampleOffset,
        hour: 14,
        minute: 10,
        painLevel: 5,
        peakPressure: 2795,
        averagePeakPressure: 2678,
        normalizedSas: 91,
        baselinePressure: 1014,
        mvsPressure: 2860,
      ),
      _event(
        id: 'event-joud-today-1',
        patientId: 'patient-joud',
        dayOffset: 0,
        hour: 11,
        minute: 30,
        painLevel: 1,
        peakPressure: 1185,
        averagePeakPressure: 1160,
        normalizedSas: 17,
        baselinePressure: 995,
        mvsPressure: 1980,
      ),
      _event(
        id: 'event-joud-month-1',
        patientId: 'patient-joud',
        dayOffset: 12,
        hour: 16,
        minute: 50,
        painLevel: 3,
        peakPressure: 1532,
        averagePeakPressure: 1488,
        normalizedSas: 50,
        baselinePressure: 995,
        mvsPressure: 1980,
      ),
    ];
  }

  static AppSettings settings() => const AppSettings();

  static PainEvent _event({
    required String id,
    required String patientId,
    required int dayOffset,
    required int hour,
    required int minute,
    required int painLevel,
    required double peakPressure,
    required double averagePeakPressure,
    required int normalizedSas,
    required double baselinePressure,
    required double mvsPressure,
  }) {
    final timestamp = _today
        .subtract(Duration(days: dayOffset))
        .add(Duration(hours: hour, minutes: minute));
    return PainEvent(
      id: id,
      patientId: patientId,
      timestamp: timestamp,
      startTime: timestamp.subtract(const Duration(seconds: 2)),
      endTime: timestamp.add(const Duration(seconds: 2)),
      durationMs: 4000,
      painLevel: painLevel,
      peakPressure: peakPressure,
      averagePeakPressure: averagePeakPressure,
      normalizedSas: normalizedSas,
      baselinePressure: baselinePressure,
      mvsPressure: mvsPressure,
      source: 'mock',
    );
  }
}
