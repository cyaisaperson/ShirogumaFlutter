import 'package:flutter/material.dart';

import '../models/pain_event.dart';
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
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${patient.patientCode}${patient.age == null ? '' : ' - Age ${patient.age}'}',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  Text(patient.description),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              tone: AppCardTone.sand,
              child: Row(
                children: [
                  Expanded(
                    child: _DataMetric(
                      label: 'Total events',
                      value: appState.activePatientEvents.length.toString(),
                    ),
                  ),
                  Expanded(
                    child: _DataMetric(
                      label: 'Latest pain level',
                      value: _latestPainLabel(appState.activePatientEvents),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calibration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (appState.activeCalibration == null)
                    const Text('No calibration saved for this patient.')
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _DataMetric(
                            label: 'Baseline',
                            value:
                                '${appState.activeCalibration!.baselinePressure.toStringAsFixed(0)} mbar',
                          ),
                        ),
                        Expanded(
                          child: _DataMetric(
                            label: 'MVS',
                            value:
                                '${appState.activeCalibration!.mvsPressure.toStringAsFixed(0)} mbar',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              tone: AppCardTone.dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent mock events'),
                  const SizedBox(height: 12),
                  if (appState.activePatientEvents.isEmpty)
                    const Text('No pain events for this patient yet.')
                  else
                    for (final event in appState.activePatientEvents.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Level ${event.painLevel} - ${_formatDateTime(event.timestamp)} - SAS ${event.normalizedSas}',
                        ),
                      ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _latestPainLabel(List<PainEvent> events) {
    if (events.isEmpty) {
      return 'None';
    }
    return 'Level ${events.first.painLevel}';
  }

  static String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _DataMetric extends StatelessWidget {
  const _DataMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedText)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
