import '../models/calibration.dart';
import '../models/pain_event.dart';
import 'live_squeeze_detector.dart';
import 'pressure_processing_service.dart';

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

class SdTransferBundle {
  const SdTransferBundle({
    required this.rawCsv,
    required this.eventsCsv,
    required this.hasData,
  });

  final String rawCsv;
  final String eventsCsv;
  final bool hasData;
}

class SdEventRow {
  const SdEventRow({
    required this.eventId,
    required this.startMs,
    required this.endMs,
    required this.durationMs,
    required this.baselineMbar,
    required this.peakMbar,
    required this.deltaMbar,
  });

  final String eventId;
  final int startMs;
  final int endMs;
  final int durationMs;
  final double baselineMbar;
  final double peakMbar;
  final double deltaMbar;

  String get stableImportKey =>
      'sd:$eventId:$startMs:$durationMs:${peakMbar.toStringAsFixed(3)}';
}

class SdEventsParseResult {
  const SdEventsParseResult({
    required this.events,
    required this.malformedRows,
  });

  final List<SdEventRow> events;
  final int malformedRows;
}

class SdPainImportPlan {
  const SdPainImportPlan({
    required this.events,
    required this.duplicatesSkipped,
  });

  final List<PainEvent> events;
  final int duplicatesSkipped;
}

class SyncService {
  Future<SyncPlaceholderResult> prepareSdCardSync() async {
    return const SyncPlaceholderResult(
      status: SyncPlaceholderStatus.notImplemented,
      message:
          'SD card sync is available when SD Card Sync mode connects to a device.',
      importedEvents: 0,
      futureSteps: [
        'pause SD recording',
        'request stored SD log',
        'select patient for imported data',
        'save events under selected patient',
        'delete synced SD files after successful import',
      ],
    );
  }

  static SdTransferBundle parseSdTransferPayload(String payload) {
    final withoutSentinel = payload
        .replaceAll('SYNC_END', '')
        .replaceAll('SYNC_EMPTY', '')
        .trim();
    if (withoutSentinel.isEmpty) {
      return const SdTransferBundle(rawCsv: '', eventsCsv: '', hasData: false);
    }

    final files = _extractTaggedFiles(withoutSentinel);
    if (files.isNotEmpty) {
      final rawCsv = files['raw.csv'] ?? '';
      final eventsCsv = files['events.csv'] ?? '';
      return SdTransferBundle(
        rawCsv: rawCsv,
        eventsCsv: eventsCsv,
        hasData: rawCsv.trim().isNotEmpty || eventsCsv.trim().isNotEmpty,
      );
    }

    final looksLikeEvents = withoutSentinel
        .split(RegExp(r'\r?\n'))
        .first
        .contains('duration_ms');
    return SdTransferBundle(
      rawCsv: '',
      eventsCsv: looksLikeEvents ? withoutSentinel : '',
      hasData: withoutSentinel.isNotEmpty,
    );
  }

  static SdEventsParseResult parseSdEventsCsv(String csv) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const SdEventsParseResult(events: [], malformedRows: 0);
    }

    final header = lines.first.split(',');
    final columnIndex = <String, int>{};
    for (var index = 0; index < header.length; index++) {
      columnIndex[header[index].trim()] = index;
    }

    const requiredColumns = [
      'event_id',
      'start_ms',
      'end_ms',
      'duration_ms',
      'baseline_mbar',
      'peak_mbar',
      'delta_mbar',
    ];
    if (requiredColumns.any((column) => !columnIndex.containsKey(column))) {
      return SdEventsParseResult(
        events: const [],
        malformedRows: lines.length - 1,
      );
    }

    final events = <SdEventRow>[];
    var malformedRows = 0;
    for (final line in lines.skip(1)) {
      final columns = line.split(',');
      try {
        final row = SdEventRow(
          eventId: _stringColumn(columns, columnIndex, 'event_id'),
          startMs: _intColumn(columns, columnIndex, 'start_ms'),
          endMs: _intColumn(columns, columnIndex, 'end_ms'),
          durationMs: _intColumn(columns, columnIndex, 'duration_ms'),
          baselineMbar: _doubleColumn(columns, columnIndex, 'baseline_mbar'),
          peakMbar: _doubleColumn(columns, columnIndex, 'peak_mbar'),
          deltaMbar: _doubleColumn(columns, columnIndex, 'delta_mbar'),
        );
        if (row.eventId.isEmpty ||
            row.durationMs < 0 ||
            row.endMs < row.startMs ||
            !row.peakMbar.isFinite ||
            !row.baselineMbar.isFinite) {
          malformedRows += 1;
          continue;
        }
        events.add(row);
      } on FormatException {
        malformedRows += 1;
      } on RangeError {
        malformedRows += 1;
      }
    }

    return SdEventsParseResult(events: events, malformedRows: malformedRows);
  }

  static SdPainImportPlan buildPainEventsForImport({
    required List<SdEventRow> sdEvents,
    required String patientId,
    required Calibration? calibration,
    required List<PainEvent> existingEvents,
    required DateTime syncCompletedAt,
    required String deviceId,
  }) {
    final existingKeys = existingEvents
        .where((event) => event.patientId == patientId)
        .map((event) => event.externalSampleId)
        .whereType<String>()
        .toSet();
    final latestEndMs = sdEvents.isEmpty
        ? 0
        : sdEvents.map((event) => event.endMs).reduce((a, b) => a > b ? a : b);
    final events = <PainEvent>[];
    var duplicatesSkipped = 0;

    for (final sdEvent in sdEvents) {
      final importKey = sdEvent.stableImportKey;
      if (existingKeys.contains(importKey)) {
        duplicatesSkipped += 1;
        continue;
      }

      final endTime = syncCompletedAt.subtract(
        Duration(milliseconds: latestEndMs - sdEvent.endMs),
      );
      final startTime = endTime.subtract(
        Duration(milliseconds: sdEvent.durationMs),
      );
      final baseline = calibration?.baselinePressure ?? sdEvent.baselineMbar;
      final mvs = calibration?.mvsPressure ?? sdEvent.peakMbar;
      final normalized = PressureProcessingService.normalizePressure(
        pressure: sdEvent.peakMbar,
        baselinePressure: baseline,
        mvsPressure: mvs,
      );
      final normalizedSas = (normalized * 100).round().clamp(0, 100);
      final painLevel = LiveSqueezeDetector.painLevelForSas(normalizedSas);

      events.add(
        PainEvent(
          id: 'sd-${importKey.hashCode.abs()}-${endTime.microsecondsSinceEpoch}',
          patientId: patientId,
          timestamp: endTime,
          startTime: startTime,
          endTime: endTime,
          durationMs: sdEvent.durationMs,
          painLevel: painLevel,
          peakPressure: sdEvent.peakMbar,
          averagePeakPressure: sdEvent.peakMbar,
          normalizedSas: normalizedSas,
          baselinePressure: baseline,
          mvsPressure: mvs,
          source: 'sd_sync',
          deviceId: deviceId,
          externalSampleId: importKey,
          notes: calibration == null
              ? 'Imported from SD card using SD event baseline.'
              : 'Imported from SD card.',
        ),
      );
      existingKeys.add(importKey);
    }

    return SdPainImportPlan(
      events: events,
      duplicatesSkipped: duplicatesSkipped,
    );
  }

  static Map<String, String> _extractTaggedFiles(String payload) {
    final files = <String, String>{};
    final lines = payload.split(RegExp(r'\r?\n'));
    String? currentName;
    final buffer = StringBuffer();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('FILE:')) {
        if (currentName != null) {
          files[currentName] = buffer.toString().trim();
          buffer.clear();
        }
        currentName = trimmed.substring('FILE:'.length).trim().toLowerCase();
        continue;
      }
      if (trimmed == 'END_FILE') {
        if (currentName != null) {
          files[currentName] = buffer.toString().trim();
          currentName = null;
          buffer.clear();
        }
        continue;
      }
      if (currentName != null) {
        buffer.writeln(line);
      }
    }
    if (currentName != null) {
      files[currentName] = buffer.toString().trim();
    }
    return files;
  }

  static String _stringColumn(
    List<String> columns,
    Map<String, int> columnIndex,
    String column,
  ) {
    return columns[columnIndex[column]!].trim();
  }

  static int _intColumn(
    List<String> columns,
    Map<String, int> columnIndex,
    String column,
  ) {
    return int.parse(_stringColumn(columns, columnIndex, column));
  }

  static double _doubleColumn(
    List<String> columns,
    Map<String, int> columnIndex,
    String column,
  ) {
    return double.parse(_stringColumn(columns, columnIndex, column));
  }
}
