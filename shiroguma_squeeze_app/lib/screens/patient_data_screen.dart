import 'package:flutter/material.dart';

import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../models/patient.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class PatientDataScreen extends StatefulWidget {
  const PatientDataScreen({super.key});

  @override
  State<PatientDataScreen> createState() => _PatientDataScreenState();
}

class _PatientDataScreenState extends State<PatientDataScreen> {
  String? selectedEventId;
  String selectedRange = '1D';
  late DateTime selectedDate = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final patient = appState.activePatient;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Patient Data', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          const Text(
            'Active-patient history and calibration preview.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
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
  final String selectedRange;
  final DateTime selectedDate;
  final String? selectedEventId;
  final ValueChanged<PainEvent> onSelectEvent;
  final ValueChanged<String> onRangeChanged;
  final ValueChanged<DateTime> onSelectedDateChanged;

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _eventsForRange(events, selectedRange, selectedDate);
    final latestEvent = filteredEvents.isEmpty ? null : filteredEvents.first;
    final selectedEvent = _eventById(filteredEvents, selectedEventId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PatientSummaryCard(
          patient: patient,
          totalEvents: events.length,
          latestEvent: latestEvent,
        ),
        const SizedBox(height: 16),
        _GraphCard(
          selectedRange: selectedRange,
          selectedDate: selectedDate,
          onRangeChanged: onRangeChanged,
          onSelectedDateChanged: onSelectedDateChanged,
          events: filteredEvents,
          allEvents: events,
          selectedEvent: selectedEvent,
          onSelectEvent: onSelectEvent,
        ),
        if (selectedEvent != null) ...[
          const SizedBox(height: 16),
          _SelectedEventCard(event: selectedEvent),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 16),
        _CalibrationCard(patientId: patient.id, calibration: calibration),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSV export will be added later.')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  PainEvent? _eventById(List<PainEvent> events, String? eventId) {
    if (eventId == null) {
      return null;
    }
    for (final event in events) {
      if (event.id == eventId) {
        return event;
      }
    }
    return null;
  }

  List<PainEvent> _eventsForRange(
    List<PainEvent> events,
    String selectedRange,
    DateTime selectedDate,
  ) {
    final startDate = switch (selectedRange) {
      '7D' => selectedDate.subtract(const Duration(days: 6)),
      '30D' => selectedDate.subtract(const Duration(days: 29)),
      _ => selectedDate,
    };
    final endDate = selectedDate;

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
}

class _PatientSummaryCard extends StatelessWidget {
  const _PatientSummaryCard({
    required this.patient,
    required this.totalEvents,
    required this.latestEvent,
  });

  final Patient patient;
  final int totalEvents;
  final PainEvent? latestEvent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('patient-summary-card'),
      tone: AppCardTone.sand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(patient.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            '${patient.patientCode}${patient.age == null ? '' : ' - Age ${patient.age}'}',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DataPill(label: 'Total events', value: '$totalEvents'),
              _DataPill(
                label: 'Latest pain level',
                value: latestEvent == null
                    ? 'None'
                    : 'Level ${latestEvent!.painLevel}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GraphCard extends StatelessWidget {
  const _GraphCard({
    required this.selectedRange,
    required this.selectedDate,
    required this.onRangeChanged,
    required this.onSelectedDateChanged,
    required this.events,
    required this.allEvents,
    required this.selectedEvent,
    required this.onSelectEvent,
  });

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
    final dateLabel =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return AppCard(
      key: const ValueKey('patient-graph-card'),
      tone: AppCardTone.sand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '1D', label: Text('1D')),
                ButtonSegment(value: '7D', label: Text('7D')),
                ButtonSegment(value: '30D', label: Text('30D')),
              ],
              selected: {selectedRange},
              onSelectionChanged: (selection) {
                onRangeChanged(selection.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (selectedRange == '1D')
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: () {
                    onSelectedDateChanged(
                      selectedDate.subtract(const Duration(days: 1)),
                    );
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
              const Icon(Icons.calendar_today_outlined),
              const SizedBox(width: 8),
              Text('Calendar', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 6),
              TextButton(
                key: const ValueKey('calendar-open-button'),
                onPressed: () async {
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
                child: Text(dateLabel),
              ),
              if (selectedRange == '1D')
                IconButton(
                  tooltip: 'Next day',
                  onPressed: () {
                    onSelectedDateChanged(
                      selectedDate.add(const Duration(days: 1)),
                    );
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: _PainTimelineGraph(
              events: events,
              selectedRange: selectedRange,
              selectedEvent: selectedEvent,
              onSelectEvent: onSelectEvent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PainTimelineGraph extends StatelessWidget {
  const _PainTimelineGraph({
    required this.events,
    required this.selectedRange,
    required this.selectedEvent,
    required this.onSelectEvent,
  });

  final List<PainEvent> events;
  final String selectedRange;
  final PainEvent? selectedEvent;
  final ValueChanged<PainEvent> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    final graphEvents = events.where((event) => event.painLevel > 0).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      key: const ValueKey('bubble-timeline-graph'),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: graphEvents.isEmpty
          ? const Center(
              child: Text(
                'No pain events in selected range.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final axis = _TimelineAxis.forEvents(
                  graphEvents,
                  selectedRange,
                );
                const sidePadding = 14.0;
                final usableWidth = constraints.maxWidth - (sidePadding * 2);
                final axisTop = constraints.maxHeight * 0.52;
                final labelTop = constraints.maxHeight - 38;

                return Stack(
                  children: [
                    Positioned(
                      left: sidePadding,
                      right: sidePadding,
                      top: axisTop,
                      child: Container(height: 2, color: AppColors.border),
                    ),
                    for (final tick in axis.ticks)
                      Positioned(
                        left:
                            sidePadding +
                            usableWidth * axis.fractionFor(tick.timestamp) -
                            24,
                        top: labelTop,
                        width: 48,
                        child: Text(
                          tick.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    for (final event in graphEvents)
                      Positioned(
                        left:
                            sidePadding +
                            usableWidth * axis.fractionFor(event.timestamp) -
                            _bubbleRadius(event.painLevel),
                        top: axisTop - _bubbleRadius(event.painLevel),
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

  factory _TimelineAxis.forEvents(
    List<PainEvent> events,
    String selectedRange,
  ) {
    if (selectedRange == '1D') {
      return _TimelineAxis._forOneDay(events);
    }
    return _TimelineAxis._forDateRange(events);
  }

  factory _TimelineAxis._forOneDay(List<PainEvent> events) {
    final first = events.first.timestamp;
    final last = events.last.timestamp;
    var start = DateTime(first.year, first.month, first.day, first.hour);
    var endHour = last.hour;
    if (last.minute > 0 || last.second > 0 || last.millisecond > 0) {
      endHour += 1;
    }
    var end = DateTime(last.year, last.month, last.day, endHour);
    if (!end.isAfter(start)) {
      end = start.add(const Duration(hours: 1));
    }

    final spanHours = end.difference(start).inHours;
    final stepHours = spanHours <= 6 ? 1 : 2;
    final ticks = <_TimelineTick>[];
    for (
      var tick = start;
      !tick.isAfter(end);
      tick = tick.add(Duration(hours: stepHours))
    ) {
      ticks.add(_TimelineTick(tick, _formatHour(tick)));
    }
    if (ticks.last.timestamp != end) {
      ticks.add(_TimelineTick(end, _formatHour(end)));
    }

    return _TimelineAxis(start: start, end: end, ticks: ticks);
  }

  factory _TimelineAxis._forDateRange(List<PainEvent> events) {
    final first = _dateOnly(events.first.timestamp);
    final last = _dateOnly(events.last.timestamp);
    final end = last.add(const Duration(days: 1));
    final spanDays = end.difference(first).inDays;
    final stepDays = spanDays <= 7
        ? 1
        : spanDays <= 14
        ? 2
        : 7;

    final ticks = <_TimelineTick>[];
    for (
      var tick = first;
      !tick.isAfter(end);
      tick = tick.add(Duration(days: stepDays))
    ) {
      ticks.add(_TimelineTick(tick, _formatDate(tick)));
    }
    if (ticks.last.timestamp != end) {
      ticks.add(_TimelineTick(end, _formatDate(end)));
    }

    return _TimelineAxis(start: first, end: end, ticks: ticks);
  }

  double fractionFor(DateTime timestamp) {
    final range = end.difference(start).inMilliseconds;
    if (range <= 0) {
      return 0.5;
    }
    final elapsed = timestamp.difference(start).inMilliseconds;
    return (elapsed / range).clamp(0.0, 1.0);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatHour(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    return '$hour:00';
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
        child: Text(
          event.painLevel.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
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
  const _SelectedEventCard({required this.event});

  final PainEvent? event;

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
          if (event == null)
            const Text('Tap a future timeline bubble to inspect event details.')
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
            child: const Text('Wong-Baker face image placeholder'),
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
                builder: (_) => _CalibrationDialog(
                  patientId: patientId,
                  calibration: calibration,
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: const Text('Calibrate'),
          ),
        ],
      ),
    );
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
    if (error != null) {
      return error;
    }
    final baseline = double.tryParse(baselineController.text.trim());
    final mvs = double.parse(value!.trim());
    if (baseline != null && mvs <= baseline) {
      return 'MVS must be above baseline';
    }
    return null;
  }

  void _save() {
    if (!formKey.currentState!.validate()) {
      return;
    }
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
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
