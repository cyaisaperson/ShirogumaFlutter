import 'package:flutter/material.dart';

import '../models/calibration.dart';
import '../models/pain_event.dart';
import '../models/patient.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class PatientDataScreen extends StatelessWidget {
  const PatientDataScreen({super.key});

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
            ),
        ],
      ),
    );
  }
}

class _PatientDataContent extends StatelessWidget {
  const _PatientDataContent({
    required this.patient,
    required this.calibration,
    required this.events,
  });

  final Patient patient;
  final Calibration? calibration;
  final List<PainEvent> events;

  @override
  Widget build(BuildContext context) {
    final latestEvent = events.isEmpty ? null : events.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(
          patient: patient,
          calibration: calibration,
          totalEvents: events.length,
          latestEvent: latestEvent,
        ),
        const SizedBox(height: 16),
        const _RangeAndCalendarCard(),
        const SizedBox(height: 16),
        _TimelinePlaceholder(events: events),
        const SizedBox(height: 16),
        _SelectedEventCard(event: latestEvent),
        const SizedBox(height: 16),
        _CalibrationCard(calibration: calibration),
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
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.patient,
    required this.calibration,
    required this.totalEvents,
    required this.latestEvent,
  });

  final Patient patient;
  final Calibration? calibration;
  final int totalEvents;
  final PainEvent? latestEvent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(patient.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            '${patient.patientCode}${patient.age == null ? '' : ' - Age ${patient.age}'}',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          Text(patient.description),
          const SizedBox(height: 18),
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              _DataPill(label: 'Total events', value: '$totalEvents'),
              _DataPill(
                label: 'Latest pain level',
                value: latestEvent == null
                    ? 'None'
                    : 'Level ${latestEvent!.painLevel}',
              ),
              _DataPill(
                label: 'Baseline',
                value: calibration == null
                    ? 'Not set'
                    : '${calibration!.baselinePressure.toStringAsFixed(0)} mbar',
              ),
              _DataPill(
                label: 'MVS',
                value: calibration == null
                    ? 'Not set'
                    : '${calibration!.mvsPressure.toStringAsFixed(0)} mbar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeAndCalendarCard extends StatelessWidget {
  const _RangeAndCalendarCard();

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTime.now();
    final dateLabel =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return AppCard(
      tone: AppCardTone.sand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History range', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '1D', label: Text('1D')),
              ButtonSegment(value: '7D', label: Text('7D')),
              ButtonSegment(value: '30D', label: Text('30D')),
            ],
            selected: const {'1D'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined),
              const SizedBox(width: 10),
              Text('Calendar', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                dateLabel,
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelinePlaceholder extends StatelessWidget {
  const _TimelinePlaceholder({required this.events});

  final List<PainEvent> events;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bubble timeline',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              events.isEmpty
                  ? 'No pain events in selected range.'
                  : '${events.length} mock events ready for graph phase.',
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
        ],
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
  const _CalibrationCard({required this.calibration});

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
        ],
      ),
    );
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
