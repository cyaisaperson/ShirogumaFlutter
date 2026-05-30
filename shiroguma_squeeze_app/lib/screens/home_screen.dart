import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final activePatient = appState.activePatient;
    final activeEvents = appState.activePatientEvents;
    final latestEvent = activeEvents.isEmpty ? null : activeEvents.first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Shiroguma Squeeze',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Doctor-facing pain monitoring dashboard',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 24),
          AppCard(
            tone: activePatient == null ? AppCardTone.sand : AppCardTone.dark,
            child: activePatient == null
                ? const _EmptyActivePatient()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active patient'),
                      const SizedBox(height: 10),
                      Text(
                        activePatient.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${activePatient.patientCode}${activePatient.age == null ? '' : ' - Age ${activePatient.age}'}',
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(
                  icon: Icons.radio_button_checked,
                  title: 'Live Signal',
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.coral, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Waiting',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  tone: AppCardTone.sand,
                  child: _MetricTile(
                    label: 'Today events',
                    value: activeEvents
                        .where((event) => _isToday(event.timestamp))
                        .length
                        .toString(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  tone: AppCardTone.coral,
                  child: _MetricTile(
                    label: 'Latest pain',
                    value: latestEvent == null
                        ? 'None'
                        : 'Level ${latestEvent.painLevel}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppCard(
            child: _CardHeader(
              icon: Icons.bluetooth_disabled,
              title: 'PressureTX placeholder',
              subtitle:
                  'BLE connection will be added after local UI is stable.',
            ),
          ),
        ],
      ),
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _EmptyActivePatient extends StatelessWidget {
  const _EmptyActivePatient();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select or add a patient',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text('Patient-specific data appears here after selection.'),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
