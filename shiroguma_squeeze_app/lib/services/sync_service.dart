enum SyncPlaceholderStatus { idle, notImplemented }

class SyncPlaceholderResult {
  const SyncPlaceholderResult({
    required this.status,
    required this.message,
    required this.importedEvents,
    required this.futureSteps,
  });

  final SyncPlaceholderStatus status;
  final String message;
  final int importedEvents;
  final List<String> futureSteps;
}

class SyncService {
  Future<SyncPlaceholderResult> prepareSdCardSync() async {
    // TODO: Connect to the XIAO device and request stored SD log chunks.
    // TODO: Parse historical pressure samples/events from the device log.
    // TODO: Assign timestamps from device metadata or user-provided sync time.
    // TODO: Save imported events under the active patient only.
    // TODO: Use PainEvent.externalSampleId to avoid duplicate imports.
    return const SyncPlaceholderResult(
      status: SyncPlaceholderStatus.notImplemented,
      message:
          'SD card sync architecture is ready, but import is not implemented yet.',
      importedEvents: 0,
      futureSteps: [
        'connect to device',
        'request stored SD log',
        'parse historical pressure samples',
        'assign timestamps',
        'save events under active patient',
        'avoid duplicate imports',
      ],
    );
  }
}
