import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/models/timeline_viewport.dart';

void main() {
  test('zooming around 10:30 can create a 10:00 to 11:00 day window', () {
    final fullStart = DateTime(2026, 6, 10);
    final viewport = TimelineViewport.full(
      fullStart: fullStart,
      fullEnd: fullStart.add(const Duration(days: 1)),
      minWindow: const Duration(minutes: 15),
    );

    final zoomed = viewport.zoomAround(
      focalFraction: 10.5 / 24,
      scaleDelta: 24,
    );

    expect(zoomed.visibleStart, DateTime(2026, 6, 10, 10));
    expect(zoomed.visibleEnd, DateTime(2026, 6, 10, 11));
  });

  test('pan clamps at full domain boundaries', () {
    final fullStart = DateTime(2026, 6, 10);
    final fullEnd = fullStart.add(const Duration(days: 1));
    final viewport = TimelineViewport(
      fullStart: fullStart,
      fullEnd: fullEnd,
      visibleStart: DateTime(2026, 6, 10, 10),
      visibleEnd: DateTime(2026, 6, 10, 11),
      minWindow: const Duration(minutes: 15),
    );

    expect(viewport.panByFraction(-100).visibleStart, fullStart);
    expect(viewport.panByFraction(100).visibleEnd, fullEnd);
  });

  test('zoom cannot shrink below one-minute minimum window', () {
    final fullStart = DateTime(2026, 6, 10);
    final viewport = TimelineViewport.full(
      fullStart: fullStart,
      fullEnd: fullStart.add(const Duration(days: 1)),
      minWindow: const Duration(minutes: 1),
    );

    final zoomed = viewport.zoomAround(focalFraction: 0.5, scaleDelta: 50000);

    expect(zoomed.visibleDuration, const Duration(minutes: 1));
  });

  test('reset restores the full visible range', () {
    final fullStart = DateTime(2026, 6, 10);
    final fullEnd = fullStart.add(const Duration(days: 1));
    final viewport = TimelineViewport(
      fullStart: fullStart,
      fullEnd: fullEnd,
      visibleStart: DateTime(2026, 6, 10, 10),
      visibleEnd: DateTime(2026, 6, 10, 11),
      minWindow: const Duration(minutes: 15),
    );

    final reset = viewport.reset();

    expect(reset.visibleStart, fullStart);
    expect(reset.visibleEnd, fullEnd);
  });
}
