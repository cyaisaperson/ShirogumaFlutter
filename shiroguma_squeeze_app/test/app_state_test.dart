import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await reloadedState.loadPersistedPatients();

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
}
