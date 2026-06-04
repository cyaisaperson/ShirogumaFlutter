# Shiroguma Flutter Progress

## Completed Phases
- Phases 1-7: Previously completed.
- Phase 8: Local persistence added with `shared_preferences`.
- Phase 9: Active-patient CSV export added.

## Modified Files
- `lib/app.dart`
- `lib/models/app_settings.dart`
- `lib/models/calibration.dart`
- `lib/models/pain_event.dart`
- `lib/state/app_state.dart`
- `lib/state/mock_data.dart`
- `lib/services/csv_export_service.dart`
- `test/app_state_test.dart`
- `test/csv_export_service_test.dart`

## Current BLE Status
- BLE is not implemented yet.
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
- Patient ID uniqueness and generated `P-00x` behavior remain in place.
- Current persistence uses `shared_preferences` JSON storage as the temporary fallback allowed in the plan.

## Known Issues
- Drift/SQLite has not been introduced yet.
- CSV export writes to the system temp directory and reports the file path in a snackbar.
- BLE live data, live event detection, reconnection, and SD card sync are not implemented yet.

## Exact Next Step
- Phase 10: Complete Settings and mode UI for Live BLE vs SD Card Sync, BLE constants, detection settings, storage information, reset confirmation, and placeholders/status labels.
