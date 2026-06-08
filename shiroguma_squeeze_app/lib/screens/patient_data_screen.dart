import 'package:flutter/material.dart';

import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../models/patient.dart';
import '../services/csv_export_service.dart';
import '../state/app_state_scope.dart';
import '../state/device_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class PatientDataScreen extends StatefulWidget {
  const PatientDataScreen({super.key});

  @override
  State<PatientDataScreen> createState() => _PatientDataScreenState();
}

class _PatientDataScreenState extends State<PatientDataScreen> {
  String? selectedEventId;
  String selectedRange = 'Day';
  late DateTime selectedDate = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final deviceState = DeviceStateScope.watch(context);
    final patient = appState.activePatient;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        children: [
          Text('Patient Data', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 18),
          if (patient == null)
            const AppCard(
              tone: AppCardTone.sand,
              child: Text(
                'Select or add a patient to view patient-specific data.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            )
          else
            _PatientDataContent(
              patient: patient,
              calibration: appState.activeCalibration,
              events: appState.activePatientEvents,
              liveSavingStatus: deviceState.liveSavingStatus,
              selectedRange: selectedRange,
              selectedDate: selectedDate,
              selectedEventId: selectedEventId,
              onSelectEvent: (event) {
                setState(() {
                  selectedEventId = event.id;
                });
              },
              onRangeChanged: (range) {
                setState(() {
                  selectedRange = range;
                  selectedEventId = null;
                });
              },
              onSelectedDateChanged: (date) {
                setState(() {
                  selectedDate = _dateOnly(date);
                  selectedEventId = null;
                });
              },
            ),
        ],
      ),
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _PatientDataContent extends StatelessWidget {
  const _PatientDataContent({
    required this.patient,
    required this.calibration,
    required this.events,
    required this.liveSavingStatus,
    required this.selectedRange,
    required this.selectedDate,
    required this.selectedEventId,
    required this.onSelectEvent,
    required this.onRangeChanged,
    required this.onSelectedDateChanged,
  });

  final Patient patient;
  final Calibration? calibration;
  final List<PainEvent> events;
  final String liveSavingStatus;
  final String selectedRange;
  final DateTime selectedDate;
  final String? selectedEventId;
  final ValueChanged<PainEvent> onSelectEvent;
  final ValueChanged<String> onRangeChanged;
  final ValueChanged<DateTime> onSelectedDateChanged;

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _eventsForRange(events, selectedRange, selectedDate);
    final selectedEvent = _eventById(filteredEvents, selectedEventId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PatientSummaryCard(
          patient: patient,
          selectedRange: selectedRange,
          selectedDate: selectedDate,
          onRangeChanged: onRangeChanged,
          onSelectedDateChanged: onSelectedDateChanged,
          events: filteredEvents,
          allEvents: events,
          selectedEvent: selectedEvent,
          onSelectEvent: onSelectEvent,
        ),
        const SizedBox(height: 16),
        _SelectedEventCard(
          event: selectedEvent,
          liveSavingStatus: liveSavingStatus,
        ),
        const SizedBox(height: 16),
        _CalibrationCard(patientId: patient.id, calibration: calibration),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final exportedFile = await CsvExportService.exportPatientCsv(
              patient: patient,
              calibration: calibration,
              painEvents: events,
            );
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CSV exported to ${exportedFile.path}')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  PainEvent? _eventById(List<PainEvent> events, String? eventId) {
    if (eventId == null) return null;
    for (final event in events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  List<PainEvent> _eventsForRange(
    List<PainEvent> events,
    String selectedRange,
    DateTime selectedDate,
  ) {
    final (startDate, endDate) = _rangeBounds(selectedRange, selectedDate);

    final filtered = events.where((event) {
      final eventDate = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
      );
      return !eventDate.isBefore(startDate) && !eventDate.isAfter(endDate);
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  (DateTime, DateTime) _rangeBounds(
    String selectedRange,
    DateTime selectedDate,
  ) {
    return switch (selectedRange) {
      'Week' => (
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1)),
        selectedDate.add(
          Duration(days: DateTime.daysPerWeek - selectedDate.weekday),
        ),
      ),
      'Month' => (
        DateTime(selectedDate.year, selectedDate.month),
        DateTime(selectedDate.year, selectedDate.month + 1, 0),
      ),
      'Year' => (
        DateTime(selectedDate.year),
        DateTime(selectedDate.year, 12, 31),
      ),
      _ => (selectedDate, selectedDate),
    };
  }
}

class _PatientSummaryCard extends StatelessWidget {
  const _PatientSummaryCard({
    required this.patient,
    required this.selectedRange,
    required this.selectedDate,
    required this.onRangeChanged,
    required this.onSelectedDateChanged,
    required this.events,
    required this.allEvents,
    required this.selectedEvent,
    required this.onSelectEvent,
  });

  final Patient patient;
  final String selectedRange;
  final DateTime selectedDate;
  final ValueChanged<String> onRangeChanged;
  final ValueChanged<DateTime> onSelectedDateChanged;
  final List<PainEvent> events;
  final List<PainEvent> allEvents;
  final PainEvent? selectedEvent;
  final ValueChanged<PainEvent> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('patient-summary-card'),
      tone: AppCardTone.sand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patient.name,
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${patient.patientCode}${patient.age == null ? '' : '  •  Age ${patient.age}'}',
            style: const TextStyle(color: AppColors.mutedText),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _TimelineRangeSelector(
                selectedRange: selectedRange,
                onRangeChanged: onRangeChanged,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous range',
                onPressed: () {
                  onSelectedDateChanged(
                    _shiftSelectedDate(selectedDate, selectedRange, -1),
                  );
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  key: const ValueKey('calendar-open-button'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final pickedDate = await showDialog<DateTime>(
                      context: context,
                      builder: (context) => _EventCalendarDialog(
                        selectedDate: selectedDate,
                        events: allEvents,
                      ),
                    );
                    if (pickedDate != null) {
                      onSelectedDateChanged(pickedDate);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _rangeTitle(selectedRange, selectedDate),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next range',
                onPressed: () {
                  onSelectedDateChanged(
                    _shiftSelectedDate(selectedDate, selectedRange, 1),
                  );
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 280,
            child: _PainTimelineGraph(
              events: events,
              selectedRange: selectedRange,
              selectedDate: selectedDate,
              selectedEvent: selectedEvent,
              onSelectEvent: onSelectEvent,
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _shiftSelectedDate(
    DateTime selectedDate,
    String selectedRange,
    int direction,
  ) {
    return switch (selectedRange) {
      'Week' => selectedDate.add(Duration(days: 7 * direction)),
      'Month' => DateTime(
        selectedDate.year,
        selectedDate.month + direction,
        selectedDate.day,
      ),
      'Year' => DateTime(
        selectedDate.year + direction,
        selectedDate.month,
        selectedDate.day,
      ),
      _ => selectedDate.add(Duration(days: direction)),
    };
  }

  static String _rangeTitle(String selectedRange, DateTime selectedDate) {
    return switch (selectedRange) {
      'Week' => _weekTitle(selectedDate),
      'Month' => _monthName(selectedDate.month),
      'Year' => selectedDate.year.toString(),
      _ =>
        '${_weekdayName(selectedDate.weekday)}, ${_monthName(selectedDate.month)} ${selectedDate.day}',
    };
  }

  static String _weekTitle(DateTime selectedDate) {
    final start = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final end = start.add(const Duration(days: 6));

    if (start.month == end.month) {
      return '${_monthName(start.month)} ${start.day} - ${end.day}';
    }

    return '${_monthName(start.month)} ${start.day} - ${_monthName(end.month)} ${end.day}';
  }

  static String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class _PainTimelineGraph extends StatelessWidget {
  const _PainTimelineGraph({
    required this.events,
    required this.selectedRange,
    required this.selectedDate,
    required this.selectedEvent,
    required this.onSelectEvent,
  });

  final List<PainEvent> events;
  final String selectedRange;
  final DateTime selectedDate;
  final PainEvent? selectedEvent;
  final ValueChanged<PainEvent> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    final graphEvents = events.where((event) => event.painLevel > 0).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      key: const ValueKey('bubble-timeline-graph'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: graphEvents.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No pain events in selected range.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final axis = _TimelineAxis.forRange(
                  selectedRange,
                  selectedDate,
                );

                const labelHeight = 32.0;
                const labelBottomPadding = 8.0;
                const bubbleTopPadding = 18.0;
                final labelWidth = _labelWidth(selectedRange);
                final axisInset = labelWidth / 2 + 4;

                final maxBubbleRadius = graphEvents
                    .map((event) => _bubbleRadius(event.painLevel))
                    .fold<double>(
                      0,
                      (max, radius) => radius > max ? radius : max,
                    );

                final usableWidth = constraints.maxWidth - (axisInset * 2);
                final axisTop = (constraints.maxHeight - labelHeight) * 0.58;
                final labelTop =
                    constraints.maxHeight - labelHeight - labelBottomPadding;

                final safeBubbleTop = bubbleTopPadding + maxBubbleRadius;
                final safeAxisTop = axisTop.clamp(
                  safeBubbleTop,
                  constraints.maxHeight - labelHeight - maxBubbleRadius - 12,
                );

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: axisInset,
                      right: axisInset,
                      top: safeAxisTop,
                      child: Container(height: 2, color: AppColors.border),
                    ),
                    for (final tick in axis.ticks)
                      Positioned(
                        left:
                            axisInset +
                            usableWidth * axis.fractionFor(tick.timestamp) -
                            labelWidth / 2,
                        top: labelTop,
                        width: labelWidth,
                        height: labelHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tick.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    for (final event in graphEvents)
                      Positioned(
                        left: _safeBubbleLeft(
                          axisInset +
                              usableWidth * axis.fractionFor(event.timestamp),
                          _bubbleRadius(event.painLevel),
                          constraints.maxWidth,
                        ),
                        top: safeAxisTop - _bubbleRadius(event.painLevel),
                        child: _PainBubble(
                          event: event,
                          isSelected: selectedEvent?.id == event.id,
                          onTap: () => onSelectEvent(event),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  static double _labelWidth(String selectedRange) {
    return switch (selectedRange) {
      'Day' => 54,
      'Month' => 64,
      _ => 44,
    };
  }

  static double _safeBubbleLeft(
    double centerX,
    double radius,
    double graphWidth,
  ) {
    return (centerX - radius).clamp(2.0, graphWidth - radius * 2 - 2);
  }
}

class _TimelineRangeSelector extends StatelessWidget {
  const _TimelineRangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  static const _ranges = ['Day', 'Week', 'Month', 'Year'];

  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('timeline-range-selector'),
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        color: AppColors.background,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final range in _ranges)
            Expanded(
              child: _TimelineRangeButton(
                label: range,
                isSelected: selectedRange == range,
                onTap: () => onRangeChanged(range),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineRangeButton extends StatelessWidget {
  const _TimelineRangeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.coral : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineAxis {
  const _TimelineAxis({
    required this.start,
    required this.end,
    required this.ticks,
  });

  final DateTime start;
  final DateTime end;
  final List<_TimelineTick> ticks;

  factory _TimelineAxis.forRange(String selectedRange, DateTime selectedDate) {
    return switch (selectedRange) {
      'Week' => _TimelineAxis._forWeek(selectedDate),
      'Month' => _TimelineAxis._forMonth(selectedDate),
      'Year' => _TimelineAxis._forYear(selectedDate),
      _ => _TimelineAxis._forDay(selectedDate),
    };
  }

  factory _TimelineAxis._forDay(DateTime selectedDate) {
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));
    final ticks = [
      _TimelineTick(start, '0:00'),
      _TimelineTick(start.add(const Duration(hours: 6)), '6:00'),
      _TimelineTick(start.add(const Duration(hours: 12)), '12:00'),
      _TimelineTick(start.add(const Duration(hours: 18)), '18:00'),
      _TimelineTick(end, '0:00'),
    ];

    return _TimelineAxis(start: start, end: end, ticks: ticks);
  }

  factory _TimelineAxis._forWeek(DateTime selectedDate) {
    final start = _dateOnly(
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1)),
    );
    final end = start.add(const Duration(days: 7));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final ticks = [
      for (var index = 0; index < labels.length; index += 1)
        _TimelineTick(start.add(Duration(days: index)), labels[index]),
    ];

    return _TimelineAxis(start: start, end: end, ticks: ticks);
  }

  factory _TimelineAxis._forMonth(DateTime selectedDate) {
    final start = DateTime(selectedDate.year, selectedDate.month);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final end = DateTime(selectedDate.year, selectedDate.month + 1);
    final tickDays = <int>{1, 8, 15, 22, lastDay}.toList()..sort();

    final ticks = [
      for (final day in tickDays)
        _TimelineTick(
          DateTime(selectedDate.year, selectedDate.month, day),
          _formatDate(DateTime(selectedDate.year, selectedDate.month, day)),
        ),
    ];

    return _TimelineAxis(start: start, end: end, ticks: ticks);
  }

  factory _TimelineAxis._forYear(DateTime selectedDate) {
    final start = DateTime(selectedDate.year);
    final end = DateTime(selectedDate.year + 1);
    final ticks = [
      for (var month = 1; month <= 12; month += 1)
        _TimelineTick(DateTime(selectedDate.year, month), '$month'),
    ];

    return _TimelineAxis(start: start, end: end, ticks: ticks);
  }

  double fractionFor(DateTime timestamp) {
    final range = end.difference(start).inMilliseconds;
    if (range <= 0) return 0.5;
    final elapsed = timestamp.difference(start).inMilliseconds;
    return (elapsed / range).clamp(0.0, 1.0);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

class _TimelineTick {
  const _TimelineTick(this.timestamp, this.label);

  final DateTime timestamp;
  final String label;
}

class _PainBubble extends StatelessWidget {
  const _PainBubble({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  final PainEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = _bubbleRadius(event.painLevel);

    return GestureDetector(
      key: ValueKey('pain-bubble-${event.id}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.coralDark : AppColors.coral,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.ink : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Text(
            event.painLevel.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

double _bubbleRadius(int painLevel) {
  return switch (painLevel) {
    1 => 14,
    2 => 16,
    3 => 18,
    4 => 21,
    5 => 24,
    _ => 0,
  };
}

class _EventCalendarDialog extends StatefulWidget {
  const _EventCalendarDialog({
    required this.selectedDate,
    required this.events,
  });

  final DateTime selectedDate;
  final List<PainEvent> events;

  @override
  State<_EventCalendarDialog> createState() => _EventCalendarDialogState();
}

class _EventCalendarDialogState extends State<_EventCalendarDialog> {
  late DateTime visibleMonth = DateTime(
    widget.selectedDate.year,
    widget.selectedDate.month,
  );

  @override
  Widget build(BuildContext context) {
    final days = _visibleCalendarDays(visibleMonth);

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () {
              setState(() {
                visibleMonth = DateTime(
                  visibleMonth.year,
                  visibleMonth.month - 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${visibleMonth.year}-${visibleMonth.month.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: () {
              setState(() {
                visibleMonth = DateTime(
                  visibleMonth.year,
                  visibleMonth.month + 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                _WeekdayLabel('S'),
                _WeekdayLabel('M'),
                _WeekdayLabel('T'),
                _WeekdayLabel('W'),
                _WeekdayLabel('T'),
                _WeekdayLabel('F'),
                _WeekdayLabel('S'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final day in days)
                  _CalendarDayButton(
                    day: day,
                    isVisibleMonth: day.month == visibleMonth.month,
                    isSelected: _sameDay(day, widget.selectedDate),
                    hasEvent: _hasEventOnDay(day),
                    onTap: () => Navigator.of(context).pop(day),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<DateTime> _visibleCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final startDay = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    return [
      for (var index = 0; index < 42; index++)
        DateTime(startDay.year, startDay.month, startDay.day + index),
    ];
  }

  bool _hasEventOnDay(DateTime day) {
    return widget.events.any((event) => _sameDay(event.timestamp, day));
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.day,
    required this.isVisibleMonth,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime day;
  final bool isVisibleMonth;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = hasEvent
        ? AppColors.coralDark
        : isSelected
        ? AppColors.coralSoft
        : Colors.transparent;
    final foregroundColor = hasEvent
        ? Colors.white
        : isVisibleMonth
        ? AppColors.foreground
        : AppColors.mutedText;

    return InkWell(
      key: hasEvent
          ? ValueKey(
              'calendar-day-with-event-${day.year}-${day.month}-${day.day}',
            )
          : ValueKey('calendar-day-${day.year}-${day.month}-${day.day}'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(
            color: isSelected ? AppColors.coralDark : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Text(
            day.day.toString(),
            style: TextStyle(
              color: foregroundColor,
              fontWeight: hasEvent || isSelected
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectedEventCard extends StatelessWidget {
  const _SelectedEventCard({
    required this.event,
    required this.liveSavingStatus,
  });

  final PainEvent? event;
  final String liveSavingStatus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('selected-event-card'),
      tone: AppCardTone.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected pain event',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 14),
          _DetailLine(label: 'Live saving', value: liveSavingStatus),
          if (event == null)
            const Text(
              'Tap a timeline bubble to inspect event details.',
              style: TextStyle(color: Colors.white70),
            )
          else ...[
            _DetailLine(
              label: 'Pain level',
              value: 'Level ${event!.painLevel}',
            ),
            _DetailLine(
              label: 'Time',
              value: _formatDateTime(event!.timestamp),
            ),
            _DetailLine(
              label: 'Duration',
              value: event!.durationMs == null
                  ? 'Not recorded'
                  : '${event!.durationMs} ms',
            ),
            _DetailLine(
              label: 'Peak pressure',
              value: '${event!.peakPressure.toStringAsFixed(0)} mbar',
            ),
            _DetailLine(
              label: 'Normalized SAS',
              value: '${event!.normalizedSas}',
            ),
            _DetailLine(
              label: 'Baseline used',
              value: '${event!.baselinePressure.toStringAsFixed(0)} mbar',
            ),
            _DetailLine(
              label: 'MVS used',
              value: '${event!.mvsPressure.toStringAsFixed(0)} mbar',
            ),
            _DetailLine(label: 'Source', value: event!.source),
          ],
          const SizedBox(height: 14),
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Wong-Baker face image placeholder',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({required this.patientId, required this.calibration});

  final String patientId;
  final Calibration? calibration;

  @override
  Widget build(BuildContext context) {
    final deviceState = DeviceStateScope.watch(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calibration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (calibration == null)
            const Text('No calibration saved for this patient.')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DataPill(
                  label: 'Baseline',
                  value:
                      '${calibration!.baselinePressure.toStringAsFixed(0)} mbar',
                ),
                _DataPill(
                  label: 'MVS',
                  value: '${calibration!.mvsPressure.toStringAsFixed(0)} mbar',
                ),
                _DataPill(
                  label: 'Samples',
                  value: calibration!.samplesUsed.toString(),
                ),
              ],
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => _LiveCalibrationDialog(patientId: patientId),
              );
            },
            icon: const Icon(Icons.sensors),
            label: const Text('Live calibrate'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => _CalibrationDialog(
                  patientId: patientId,
                  calibration: calibration,
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: const Text('Manual entry'),
          ),
          if (deviceState.liveCalibrationResult != null) ...[
            const SizedBox(height: 10),
            Text(
              deviceState.liveCalibrationResult!.reason,
              style: TextStyle(
                color: deviceState.liveCalibrationResult!.valid
                    ? AppColors.coralDark
                    : Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveCalibrationDialog extends StatelessWidget {
  const _LiveCalibrationDialog({required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final deviceState = DeviceStateScope.watch(context);
    final result = deviceState.liveCalibrationResult;
    final latestPressure = deviceState.latestPressure;
    final canSave = result?.valid == true;

    return AlertDialog(
      title: const Text('Live MVS calibration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('1. Hold device still for baseline.'),
            const Text('2. Squeeze with maximum comfortable force.'),
            const Text('3. Release, then stop recording.'),
            const SizedBox(height: 16),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: _liveCalibrationOrbSize(latestPressure),
                height: _liveCalibrationOrbSize(latestPressure),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.coral, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  latestPressure == null
                      ? '--'
                      : latestPressure.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailLine(
              label: 'Status',
              value: deviceState.isLiveCalibrationRecording
                  ? 'Recording'
                  : 'Ready',
            ),
            _DetailLine(
              label: 'Samples',
              value: deviceState.liveCalibrationSampleCount.toString(),
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Baseline',
                value: result.baselinePressure <= 0
                    ? '--'
                    : '${result.baselinePressure.toStringAsFixed(0)} mbar',
              ),
              _DetailLine(
                label: 'MVS',
                value: result.mvsPressure <= 0
                    ? '--'
                    : '${result.mvsPressure.toStringAsFixed(0)} mbar',
              ),
              Text(
                result.reason,
                style: TextStyle(
                  color: result.valid ? AppColors.coralDark : Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            DeviceStateScope.read(context).resetLiveCalibration();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        if (deviceState.isLiveCalibrationRecording)
          FilledButton(
            onPressed: () {
              DeviceStateScope.read(context).stopLiveCalibration();
            },
            child: const Text('Stop recording'),
          )
        else
          FilledButton(
            onPressed: () {
              DeviceStateScope.read(context).startLiveCalibration();
            },
            child: const Text('Start live calibration'),
          ),
        FilledButton(
          onPressed: canSave
              ? () async {
                  await AppStateScope.read(context).saveCalibration(
                    patientId: patientId,
                    baselinePressure: result!.baselinePressure,
                    mvsPressure: result.mvsPressure,
                    samplesUsed: result.samplesUsed,
                    notes: 'Live MVS calibration',
                  );
                  if (!context.mounted) return;
                  DeviceStateScope.read(context).resetLiveCalibration();
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Save calibration'),
        ),
      ],
    );
  }

  double _liveCalibrationOrbSize(double? pressure) {
    if (pressure == null || !pressure.isFinite) return 82;
    final scaled = 82 + ((pressure - 1000).clamp(0, 1400) / 1400) * 46;
    return scaled.toDouble();
  }
}

class _CalibrationDialog extends StatefulWidget {
  const _CalibrationDialog({
    required this.patientId,
    required this.calibration,
  });

  final String patientId;
  final Calibration? calibration;

  @override
  State<_CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<_CalibrationDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController baselineController;
  late final TextEditingController mvsController;
  late final TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    baselineController = TextEditingController(
      text: widget.calibration?.baselinePressure.toStringAsFixed(0) ?? '',
    );
    mvsController = TextEditingController(
      text: widget.calibration?.mvsPressure.toStringAsFixed(0) ?? '',
    );
    notesController = TextEditingController(
      text: widget.calibration?.notes ?? '',
    );
  }

  @override
  void dispose() {
    baselineController.dispose();
    mvsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual calibration'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: baselineController,
                decoration: const InputDecoration(
                  labelText: 'Baseline pressure',
                  suffixText: 'mbar',
                ),
                keyboardType: TextInputType.number,
                validator: _positiveNumber,
              ),
              TextFormField(
                controller: mvsController,
                decoration: const InputDecoration(
                  labelText: 'MVS pressure',
                  suffixText: 'mbar',
                ),
                keyboardType: TextInputType.number,
                validator: _mvsValidator,
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save calibration')),
      ],
    );
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Enter a pressure above 0';
    }
    return null;
  }

  String? _mvsValidator(String? value) {
    final error = _positiveNumber(value);
    if (error != null) return error;
    final baseline = double.tryParse(baselineController.text.trim());
    final mvs = double.parse(value!.trim());
    if (baseline != null && mvs <= baseline) {
      return 'MVS must be above baseline';
    }
    return null;
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;

    AppStateScope.read(context).saveCalibration(
      patientId: widget.patientId,
      baselinePressure: double.parse(baselineController.text.trim()),
      mvsPressure: double.parse(mvsController.text.trim()),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.coralSoft),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
