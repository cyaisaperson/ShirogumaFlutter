import 'package:flutter/foundation.dart';

import '../services/sync_service.dart';

class SdCardSyncState extends ChangeNotifier {
  SdCardSyncState({SyncService? syncService})
    : _syncService = syncService ?? SyncService();

  final SyncService _syncService;

  SyncPlaceholderStatus _status = SyncPlaceholderStatus.idle;
  String _message = 'SD card import is not implemented yet.';
  int _importedEvents = 0;
  List<String> _futureSteps = const [];

  SyncPlaceholderStatus get status => _status;
  String get message => _message;
  int get importedEvents => _importedEvents;
  List<String> get futureSteps => List.unmodifiable(_futureSteps);

  Future<void> preparePlaceholderSync() async {
    final result = await _syncService.prepareSdCardSync();
    _status = result.status;
    _message = result.message;
    _importedEvents = result.importedEvents;
    _futureSteps = result.futureSteps;
    notifyListeners();
  }
}
