class TimelineViewport {
  const TimelineViewport({
    required this.fullStart,
    required this.fullEnd,
    required this.visibleStart,
    required this.visibleEnd,
    required this.minWindow,
  });

  factory TimelineViewport.full({
    required DateTime fullStart,
    required DateTime fullEnd,
    required Duration minWindow,
  }) {
    return TimelineViewport(
      fullStart: fullStart,
      fullEnd: fullEnd,
      visibleStart: fullStart,
      visibleEnd: fullEnd,
      minWindow: minWindow,
    );
  }

  final DateTime fullStart;
  final DateTime fullEnd;
  final DateTime visibleStart;
  final DateTime visibleEnd;
  final Duration minWindow;

  Duration get fullDuration => fullEnd.difference(fullStart);
  Duration get visibleDuration => visibleEnd.difference(visibleStart);

  bool get isFullRange =>
      visibleStart.isAtSameMomentAs(fullStart) &&
      visibleEnd.isAtSameMomentAs(fullEnd);

  TimelineViewport zoomAround({
    required double focalFraction,
    required double scaleDelta,
  }) {
    final fullMilliseconds = fullDuration.inMilliseconds;
    final visibleMilliseconds = visibleDuration.inMilliseconds;
    if (fullMilliseconds <= 0 || visibleMilliseconds <= 0) return reset();

    final safeScale = scaleDelta <= 0 ? 1.0 : scaleDelta;
    final safeFocalFraction = focalFraction.clamp(0.0, 1.0);
    final minMilliseconds = minWindow.inMilliseconds.clamp(1, fullMilliseconds);
    final nextMilliseconds = (visibleMilliseconds / safeScale).round().clamp(
      minMilliseconds,
      fullMilliseconds,
    );
    final focalOffset = (visibleMilliseconds * safeFocalFraction).round();
    final focalTime = visibleStart.add(Duration(milliseconds: focalOffset));
    final nextStart = focalTime.subtract(
      Duration(milliseconds: nextMilliseconds ~/ 2),
    );

    return _copyClamped(nextStart, Duration(milliseconds: nextMilliseconds));
  }

  TimelineViewport panByFraction(double deltaFraction) {
    final visibleMilliseconds = visibleDuration.inMilliseconds;
    if (visibleMilliseconds <= 0) return reset();

    final deltaMilliseconds = (visibleMilliseconds * deltaFraction).round();
    return _copyClamped(
      visibleStart.add(Duration(milliseconds: deltaMilliseconds)),
      visibleDuration,
    );
  }

  TimelineViewport reset() {
    return TimelineViewport(
      fullStart: fullStart,
      fullEnd: fullEnd,
      visibleStart: fullStart,
      visibleEnd: fullEnd,
      minWindow: minWindow,
    );
  }

  double fractionFor(DateTime timestamp) {
    final range = visibleDuration.inMilliseconds;
    if (range <= 0) return 0.5;
    final elapsed = timestamp.difference(visibleStart).inMilliseconds;
    return (elapsed / range).clamp(0.0, 1.0);
  }

  TimelineViewport _copyClamped(DateTime proposedStart, Duration window) {
    final fullMilliseconds = fullDuration.inMilliseconds;
    if (fullMilliseconds <= 0) return reset();

    final windowMilliseconds = window.inMilliseconds.clamp(1, fullMilliseconds);
    final latestStart = fullEnd.subtract(
      Duration(milliseconds: windowMilliseconds),
    );
    final clampedStart = proposedStart.isBefore(fullStart)
        ? fullStart
        : proposedStart.isAfter(latestStart)
        ? latestStart
        : proposedStart;

    return TimelineViewport(
      fullStart: fullStart,
      fullEnd: fullEnd,
      visibleStart: clampedStart,
      visibleEnd: clampedStart.add(Duration(milliseconds: windowMilliseconds)),
      minWindow: minWindow,
    );
  }
}
