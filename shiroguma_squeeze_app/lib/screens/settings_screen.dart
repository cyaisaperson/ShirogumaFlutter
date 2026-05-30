import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final settings = appState.settings;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          const Text(
            'Local app configuration placeholders for the next phases.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SettingRow(
                  label: 'Preferred device',
                  value: settings.preferredDeviceName,
                ),
                _SettingRow(label: 'Service UUID', value: settings.serviceUuid),
                _SettingRow(
                  label: 'Characteristic UUID',
                  value: settings.characteristicUuid,
                ),
                const _SettingRow(label: 'Connection', value: 'Placeholder'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            tone: AppCardTone.sand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detection settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SettingRow(
                  label: 'Start threshold',
                  value:
                      '${settings.thresholdPercentAboveBaseline.toStringAsFixed(0)}% above baseline',
                ),
                _SettingRow(
                  label: 'Peak window',
                  value: '${settings.peakWindowSize} samples',
                ),
                _SettingRow(
                  label: 'Notable swing',
                  value:
                      '${settings.notableSwingPercentOfMvsRange.toStringAsFixed(0)}% of MVS range',
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
                  'Local storage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SettingRow(label: 'Database', value: 'In-memory mock data'),
                _SettingRow(
                  label: 'Patients',
                  value: appState.patients.length.toString(),
                ),
                _SettingRow(
                  label: 'Pain events',
                  value: appState.painEvents.length.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
