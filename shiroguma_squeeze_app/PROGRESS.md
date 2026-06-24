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
- Phase 16: Compact header battery/status text now uses short one-line chips, hides the mode chip first on narrow widths, and keeps device battery detail compact.
- Phase 17: Actual BLE battery value path confirmed; battery notifications log raw bytes and parsed percentage while the UI shows real state or `--%`.
- Phase 21: Required UI polish pass moved Live MVS close control to the dialog header and only shows Save calibration once a valid final result exists.
- Phase 22: Removed completed-feature fake Home values by showing connected device/preferred device from state and replacing hard-coded sample rate with `--`.
- Phase 23: Added guardrails for common BLE errors, low battery warning, and no-events CSV export.
- Calibration UX checkpoint: Live MVS calibration now uses a guided step flow with auto-stop after stable peak samples, and patient cards show MVS info plus a calibration shortcut.
- Calibration stability tweak: Live MVS auto-stop now waits for a longer stable max-force hold before accepting the calibration.
- Calibration button-flow tweak: Live MVS calibration starts automatically when opened and shows Recalibrate only after recording reaches a result.
- Calibration flow revision: Baseline is continuously tracked from idle pressure, MVS calibration starts from Begin, shows a 3-2-1 countdown, then uses only a stable 3-second max-force region.
- Calibration release-stop tweak: MVS recording now stops after pressure returns to baseline and computes MVS from the middle 10 high-force samples rather than requiring a perfectly stable full region.
- Patient data polish: MVS now appears as simple patient-info text, normal patient cards no longer show a large calibration action, new patients prompt for MVS calibration, and active patient contrast is stronger.
- Patient management polish: Edit patient mode now supports confirmed patient deletion, and active patient cards use the prior coral color treatment again.
- Current UI Fix Phase 1: Moved live MVS calibration out of Patient Data and into the Patients page flow for new-patient prompts and edit-patient recalibration. Patient Data now shows calibration values as a read-only summary.
- Current UI Fix Phase 2: Centered Patient Data bubble graph week labels in day buckets and month labels in date buckets.
- Current UI Fix Phase 2 follow-up: Corrected month final-bucket labels and year labels so both use bucket-center positions.
- Current UI Fix Phase 3: Moved patient deletion from the edit dialog body row to a top-right delete icon in the edit dialog header.
- Current UI Fix Phase 4: Improved BLE scan timeout copy to show compact common causes. The connection label change was skipped per user instruction.
- Current UI Fix Phase 4 follow-up: Hardened the Home Reconnect button so it passes current settings into immediate retry and added reconnect regressions with fake BLE service coverage.
- Current UI Fix Phase 5: Hid MVS labels from patient roster cards while keeping calibration prompt text and Patient Data calibration summaries intact.
- Current UI Fix Phase 6 replacement: Replaced pixel-scaling zoom with time-domain zoom and pan for Patient Data bubble graphs. Pinch/trackpad-style scale gestures now narrow the visible time window, axis ticks are recalculated for the visible domain, bubbles keep stable visual size, and reset is available by double-tap or the compact reset control.
- Current UI Fix Phase 6 follow-up: Increased bubble graph zoom depth to a one-minute minimum viewport, added one-minute tick labels for tight zoom windows, and made bubble fills translucent so overlapping pain values remain easier to inspect.

## Modified Files
- `lib/app.dart`
- `lib/models/app_settings.dart`
- `lib/models/calibration.dart`
- `lib/models/pain_event.dart`
- `lib/models/timeline_viewport.dart`
- `lib/state/app_state.dart`
- `lib/state/mock_data.dart`
- `lib/services/csv_export_service.dart`
- `lib/services/sync_service.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/patient_data_screen.dart`
- `lib/screens/patients_screen.dart`
- `lib/widgets/calibration_dialogs.dart`
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
- `test/timeline_viewport_test.dart`
- `test/csv_export_service_test.dart`
- `test/widget_test.dart`

## Current BLE Status
- `flutter_blue_plus` is installed.
- `BleService` can scan for `PressureTX`, connect, discover services, subscribe to pressure and battery notifications, parse notification bytes, log raw/parsed battery notifications, and surface readable permission/offline/service-missing errors.
- Home shows compact header chips for battery percentage, BLE connection status, and mode; the device card shows connected name when available, latest pressure, battery percentage, last update, connect/disconnect control, and a Bluetooth device browser for choosing a scanned device manually.
- Live BLE pressure samples are buffered into squeeze segments, normalized with the active patient calibration, and saved as `live_ble` pain events only when saving is eligible.
- Unexpected disconnects move the app into `Reconnecting`, retry with the last known device/settings while the app is open, and mark battery data stale after 30 seconds without updates.
- Live MVS calibration can record pressure samples from the BLE stream, evaluate baseline stability, compute MVS, and save valid calibration values to the active patient.
- Live MVS calibration now guides the user through Get comfortable, Resting baseline, Maximum squeeze, and All set states; recording auto-stops once a longer stable MVS plateau is detected.
- Live MVS calibration skips a separate baseline step, snapshots the continuously tracked idle baseline, uses Begin plus a 3-2-1 countdown, stops after release back to baseline, and averages the middle high-force samples for MVS.
- Live pain-level detection remains blocked until the active patient has an MVS calibration.
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
- Deleting a patient removes the profile, its calibration, its saved pain events, and clears active patient selection if needed.
- Current persistence uses `shared_preferences` JSON storage as the temporary fallback allowed in the plan.

## Known Issues
- Drift/SQLite has not been introduced yet.
- CSV export writes to the system temp directory and reports the file path in a snackbar; patients with no pain events show `No events to export`.
- SD Card Sync UI is visible, intentionally disabled as `Coming later`, and backed by placeholder sync service/state architecture.
- BLE hardware testing with the physical XIAO is still pending.
- Runtime permission prompting may need refinement after Android hardware testing.
- Full SD card log transfer/parsing/import is not implemented yet.
- Live MVS calibration depends on an active BLE pressure stream; if the device is disconnected, recording will collect no samples and fail validation.
- Live MVS calibration still requires the user to explicitly save after auto-stop so patient calibration is not overwritten by accident.
- Phase 1 checks completed:
  - `flutter test test\widget_test.dart` passed.
  - `flutter analyze` passed with no issues.
- Phase 2 checks completed:
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.
- Phase 3 checks completed:
  - `flutter test test\widget_test.dart` passed.
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.
- Phase 4 checks completed:
  - `flutter test test\ble_service_test.dart` passed.
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.
- Phase 4 reconnect follow-up checks completed:
  - `flutter test test\device_state_test.dart` passed.
  - `flutter test test\widget_test.dart` passed.
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.
- Phase 5 checks completed:
  - `flutter test test\widget_test.dart` passed.
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.
- Phase 6 replacement checks completed:
  - `flutter test test\timeline_viewport_test.dart` passed.
  - `flutter test test\widget_test.dart` passed.
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.
- Phase 6 zoom/readability follow-up checks completed:
  - `flutter test test\timeline_viewport_test.dart` passed.
  - `flutter test test\widget_test.dart` passed.
  - `flutter test` passed.
  - `flutter analyze` passed with no issues.

## Exact Next Step
- Next phase: Phase 7, add live pressure trace to Home and Calibration.

## 2026-06-19 SD Card Mode Implementation

### Files Changed
- `lib/app.dart`
- `lib/models/app_settings.dart`
- `lib/screens/settings_screen.dart`
- `lib/services/ble_service.dart`
- `lib/services/sync_service.dart`
- `lib/state/app_state.dart`
- `lib/state/device_state.dart`
- `lib/state/sd_card_sync_state.dart`
- `test/sync_service_test.dart`

### Completed Work
- Added SD Card Mode connection flow that starts only when `DataMode.sdCard` is selected.
- Kept Live BLE pressure, battery, calibration, and live event-saving paths unchanged.
- Added expected SD BLE UUIDs in `SdBleProtocol`:
  - SD status: `abcd1234-5678-4321-abcd-1234567890b0`
  - SD data transfer: `abcd1234-5678-4321-abcd-1234567890b1`
  - SD command: `abcd1234-5678-4321-abcd-1234567890b2`
  - SD recording control: `abcd1234-5678-4321-abcd-1234567890b3`
- Added app-side commands for `SD_PAUSE`, `SD_RESUME`, `SYNC_START`, `SYNC_CANCEL`, and `SYNC_DONE_DELETE`.
- Added SD transfer parsing for tagged `raw.csv` / `events.csv` payloads and direct `events.csv` payloads.
- Added robust `events.csv` parsing for `event_id,start_ms,end_ms,duration_ms,baseline_mbar,peak_mbar,delta_mbar`.
- Added SD event import into selected patient history with duplicate prevention via stable `externalSampleId`.
- Added patient-selection popup titled `Select patient for imported data`.
- Added status messages for checking, syncing, patient selection, import complete, SD deletion, and failure-with-data-kept cases.
- Added tests for SD CSV parsing, malformed-row skipping, transfer payload extraction, and duplicate-safe import planning.

### Pending Arduino-Side BLE Characteristic Work
- Add the four SD BLE characteristics listed above to the `PressureTX` service.
- On app connect / `SD_PAUSE`, pause SD recording while keeping live pressure and battery BLE notifications active.
- On app disconnect / `SD_RESUME`, resume standalone SD recording when the app is not connected.
- Implement SD status read/notify values such as `EMPTY`, `HAS_DATA`, or an error string.
- Implement `SYNC_START` to notify SD data chunks on the SD data characteristic.
- End transfer with `SYNC_END`; use `SYNC_EMPTY` when no SD data exists.
- Stream payloads in this format:
  - `FILE:raw.csv`
  - raw CSV contents
  - `END_FILE`
  - `FILE:events.csv`
  - events CSV contents
  - `END_FILE`
  - `SYNC_END`
- Implement `SYNC_DONE_DELETE` to delete only the SD files that were successfully synced.
- Implement `SYNC_CANCEL` so failed or canceled app imports leave SD files intact.

### Exact Next Steps
- Update the Arduino firmware to expose and honor the SD BLE protocol above.
- Hardware-test SD Card Mode with a real XIAO nRF52840 and microSD BFF:
  - connect in SD Card Mode
  - verify `SD_PAUSE`
  - sync stored files
  - select patient
  - confirm imported history
  - confirm `SYNC_DONE_DELETE` deletes only after successful import
- Re-test failure cases with the device: disconnect mid-transfer, malformed CSV, empty SD files, and repeated sync attempts.





