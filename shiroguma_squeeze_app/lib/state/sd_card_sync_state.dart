import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/patient.dart';
import '../services/sync_service.dart';
import 'app_state.dart';
import 'device_state.dart';

enum SdCardSyncStatus {
  idle,
  checking,
  syncing,
  selectingPatient,
  importing,
  complete,
  deleted,
  failed,
  canceled,
}

typedef SdPatientSelector = Future<String?> Function(List<Patient> patients);

class SdCardSyncState extends ChangeNotifier {
  SdCardSyncState({SyncService? syncService})
    : _syncService = syncService ?? SyncService();

  final SyncService _syncService;

  SdCardSyncStatus _status = SdCardSyncStatus.idle;
  String _message = 'SD Card Mode ready.';
  int _importedEvents = 0;
  int _duplicatesSkipped = 0;
  int _malformedRows = 0;
  List<String> _futureSteps = const [];
  bool _syncInProgress = false;
  int _syncAttempt = 0;

  SdCardSyncStatus get status => _status;
  String get message => _message;
  int get importedEvents => _importedEvents;
  int get duplicatesSkipped => _duplicatesSkipped;
  int get malformedRows => _malformedRows;
  List<String> get futureSteps => List.unmodifiable(_futureSteps);
  bool get syncInProgress => _syncInProgress;

  Future<void> preparePlaceholderSync() async {
    final result = await _syncService.prepareSdCardSync();
    _message = result.message;
    _importedEvents = result.importedEvents;
    _futureSteps = result.futureSteps;
    notifyListeners();
  }

  Future<void> syncAfterDeviceConnected({
    required DeviceState deviceState,
    required AppState appState,
    required SdPatientSelector selectPatient,
  }) async {
    if (_syncInProgress || appState.settings.dataMode != DataMode.sdCard) {
      return;
    }
    _syncInProgress = true;
    final attempt = ++_syncAttempt;

    try {
      _setStatus(SdCardSyncStatus.checking, 'Checking SD card...');
      // SD Card Mode pauses device-side recording first. While connected, live
      // BLE streaming continues through the existing pressure/battery path.
      await deviceState.pauseSdRecording();

      _setStatus(SdCardSyncStatus.syncing, 'Syncing SD data...');
      final download = await deviceState.downloadSdCardData(
        onStatus: (status) {
          if (attempt == _syncAttempt && status.trim().isNotEmpty) {
            _message = 'Checking SD card... $status';
            notifyListeners();
          }
        },
      );
      if (!download.hasData) {
        _importedEvents = 0;
        _setStatus(SdCardSyncStatus.complete, 'Import complete');
        return;
      }

      final bundle = SyncService.parseSdTransferPayload(download.payload);
      final parsed = SyncService.parseSdEventsCsv(bundle.eventsCsv);
      _malformedRows = parsed.malformedRows;
      if (!bundle.hasData || parsed.events.isEmpty) {
        await deviceState.cancelSdSync();
        final reason = bundle.eventsCsv.trim().isEmpty
            ? 'no events.csv rows received'
            : 'no valid events found; malformed rows: $_malformedRows';
        _setStatus(
          SdCardSyncStatus.failed,
          'Sync failed - SD data kept ($reason)',
        );
        return;
      }

      _setStatus(
        SdCardSyncStatus.selectingPatient,
        'Select patient for imported data',
      );
      final patientId = await selectPatient(appState.patients);
      if (patientId == null) {
        await deviceState.cancelSdSync();
        _setStatus(SdCardSyncStatus.canceled, 'Sync failed - SD data kept');
        return;
      }

      _setStatus(SdCardSyncStatus.importing, 'Syncing SD data...');
      final importPlan = SyncService.buildPainEventsForImport(
        sdEvents: parsed.events,
        patientId: patientId,
        calibration: appState.calibrationForPatient(patientId),
        existingEvents: appState.painEvents,
        syncCompletedAt: DateTime.now(),
        deviceId: appState.settings.preferredDeviceName,
      );
      _duplicatesSkipped = importPlan.duplicatesSkipped;
      _importedEvents = await appState.importPainEvents(importPlan.events);
      await appState.updateSettings(
        appState.settings.copyWith(lastSdSyncAt: DateTime.now()),
      );
      _setStatus(SdCardSyncStatus.complete, 'Import complete');

      await deviceState.deleteSyncedSdData();
      _setStatus(SdCardSyncStatus.deleted, 'SD data deleted');
    } catch (error) {
      await deviceState.cancelSdSync().catchError((_) {});
      final reason = error is StateError ? error.message : error.runtimeType;
      _setStatus(
        SdCardSyncStatus.failed,
        'Sync failed - SD data kept ($reason)',
      );
    } finally {
      _syncInProgress = false;
      notifyListeners();
    }
  }

  void _setStatus(SdCardSyncStatus status, String message) {
    _status = status;
    _message = message;
    notifyListeners();
  }
}
