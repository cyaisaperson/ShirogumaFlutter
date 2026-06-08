# Shiroguma Flutter Progress

## Completed Phases
- Phases 1-7: Previously completed.
- Phase 8: Local persistence added with `shared_preferences`.
- Phase 9: Active-patient CSV export added.
- Phase 10: Settings and mode UI completed.
- Phase 11: BLE connection service and live device status added.
- Phase 12: Live BLE squeeze detection and active-patient event saving added.

## Modified Files
- `lib/app.dart`
- `lib/models/app_settings.dart`
- `lib/models/calibration.dart`
- `lib/models/pain_event.dart`
- `lib/state/app_state.dart`
- `lib/state/mock_data.dart`
- `lib/services/csv_export_service.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/services/ble_service.dart`
- `lib/services/live_squeeze_detector.dart`
- `lib/state/device_state.dart`
- `lib/state/device_state_scope.dart`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- `pubspec.lock`
- `test/app_state_test.dart`
- `test/ble_service_test.dart`
- `test/live_squeeze_detector_test.dart`
- `test/csv_export_service_test.dart`
- `test/widget_test.dart`

## Current BLE Status
- `flutter_blue_plus` is installed.
- `BleService` can scan for `PressureTX`, connect, discover services, subscribe to pressure and battery notifications, and parse notification bytes.
- Home shows current mode, connection status, connected device name when available, latest pressure, battery percentage, last update, connect/disconnect control, and a Bluetooth device browser for choosing a scanned device manually.
- Live BLE pressure samples are buffered into squeeze segments, normalized with the active patient calibration, and saved as `live_ble` pain events only when saving is eligible.
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
- Patient ID uniqueness and generated `P-00x` behavior remain in place.
- Current persistence uses `shared_preferences` JSON storage as the temporary fallback allowed in the plan.

## Known Issues
- Drift/SQLite has not been introduced yet.
- CSV export writes to the system temp directory and reports the file path in a snackbar.
- SD Card Sync UI is visible but intentionally disabled as `Coming later`.
- BLE hardware testing with the physical XIAO is still pending.
- Runtime permission prompting may need refinement after Android hardware testing.
- BLE reconnection and SD card sync are not implemented yet.

## Exact Next Step
- Phase 13: Improve BLE reconnection and status handling.
