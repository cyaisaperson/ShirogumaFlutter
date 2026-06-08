# Shiroguma Flutter Progress

## Completed Phases
- Phases 1-7: Previously completed.
- Phase 8: Local persistence added with `shared_preferences`.
- Phase 9: Active-patient CSV export added.
- Phase 10: Settings and mode UI completed.
- Phase 11: BLE connection service and live device status added.
- Phase 12: Live BLE squeeze detection and active-patient event saving added.
- Phase 13: BLE reconnect attempts and stale battery status added.
- Phase 14: SD Card Sync placeholder architecture added.
- Phase 15: Live MVS calibration flow added with manual entry retained as fallback.
- Calibration UX checkpoint: Live MVS calibration now uses a guided step flow with auto-stop after stable peak samples, and patient cards show MVS info plus a calibration shortcut.
- Calibration stability tweak: Live MVS auto-stop now waits for a longer stable max-force hold before accepting the calibration.

## Modified Files
- `lib/app.dart`
- `lib/models/app_settings.dart`
- `lib/models/calibration.dart`
- `lib/models/pain_event.dart`
- `lib/state/app_state.dart`
- `lib/state/mock_data.dart`
- `lib/services/csv_export_service.dart`
- `lib/services/sync_service.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/patient_data_screen.dart`
- `lib/screens/patients_screen.dart`
- `lib/services/ble_service.dart`
- `lib/services/live_squeeze_detector.dart`
- `lib/state/device_state.dart`
- `lib/state/device_state_scope.dart`
- `lib/state/sd_card_sync_state.dart`
- `lib/state/sd_card_sync_state_scope.dart`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- `pubspec.lock`
- `test/app_state_test.dart`
- `test/ble_service_test.dart`
- `test/device_state_test.dart`
- `test/live_squeeze_detector_test.dart`
- `test/sync_service_test.dart`
- `test/csv_export_service_test.dart`
- `test/widget_test.dart`

## Current BLE Status
- `flutter_blue_plus` is installed.
- `BleService` can scan for `PressureTX`, connect, discover services, subscribe to pressure and battery notifications, and parse notification bytes.
- Home shows current mode, connection status, connected device name when available, latest pressure, battery percentage, last update, connect/disconnect control, and a Bluetooth device browser for choosing a scanned device manually.
- Live BLE pressure samples are buffered into squeeze segments, normalized with the active patient calibration, and saved as `live_ble` pain events only when saving is eligible.
- Unexpected disconnects move the app into `Reconnecting`, retry with the last known device/settings while the app is open, and mark battery data stale after 30 seconds without updates.
- Live MVS calibration can record pressure samples from the BLE stream, evaluate baseline stability, compute MVS, and save valid calibration values to the active patient.
- Live MVS calibration now guides the user through Get comfortable, Resting baseline, Maximum squeeze, and All set states; recording auto-stops once a longer stable MVS plateau is detected.
- Settings exposes Live BLE / SD Card Sync mode selection, BLE UUID values, connection status, and battery status.
- Android manifest includes Bluetooth scan/connect permissions.
- Device contract from the continuation plan is noted for Phase 11:
  - Device name: `PressureTX`
  - Service UUID: `12345678-1234-1234-1234-1234567890ab`
  - Pressure characteristic UUID: `abcd1234-5678-4321-abcd-1234567890ab`
  - Battery characteristic UUID: `abcd1234-5678-4321-abcd-1234567890ac`

## Current Persistence Status
- Patients persist locally.
- Active patient ID persists locally.
- Calibrations persist locally.
- Pain events persist locally.
- Data mode and BLE/detection settings persist locally.
- Pain events support a future `externalSampleId` duplicate key for SD sync imports.
- Patient ID uniqueness and generated `P-00x` behavior remain in place.
- Current persistence uses `shared_preferences` JSON storage as the temporary fallback allowed in the plan.

## Known Issues
- Drift/SQLite has not been introduced yet.
- CSV export writes to the system temp directory and reports the file path in a snackbar.
- SD Card Sync UI is visible, intentionally disabled as `Coming later`, and backed by placeholder sync service/state architecture.
- BLE hardware testing with the physical XIAO is still pending.
- Runtime permission prompting may need refinement after Android hardware testing.
- Full SD card log transfer/parsing/import is not implemented yet.
- Live MVS calibration depends on an active BLE pressure stream; if the device is disconnected, recording will collect no samples and fail validation.
- Live MVS calibration still requires the user to explicitly save after auto-stop so patient calibration is not overwritten by accident.

## Exact Next Step
- Phase 16: Compact Header Battery Text.
