import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/ble_service.dart';
import '../state/app_state_scope.dart';
import '../state/device_state_scope.dart';
import '../state/sd_card_sync_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final deviceState = DeviceStateScope.watch(context);
    final syncState = SdCardSyncStateScope.watch(context);
    final settings = appState.settings;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          const Text(
            'Device, detection, sync, and local storage controls.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          AppCard(
            tone: AppCardTone.sand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<DataMode>(
                  segments: const [
                    ButtonSegment(
                      value: DataMode.liveBle,
                      label: Text('Live BLE'),
                      icon: Icon(Icons.bluetooth),
                    ),
                    ButtonSegment(
                      value: DataMode.sdCard,
                      label: Text('SD Card Mode'),
                      icon: Icon(Icons.sd_card),
                    ),
                  ],
                  selected: {settings.dataMode},
                  onSelectionChanged: (selection) {
                    AppStateScope.read(context).updateSettings(
                      settings.copyWith(dataMode: selection.first),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SettingRow(
                  label: 'Current mode',
                  value: settings.dataMode.label,
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
                  label: 'Pressure characteristic UUID',
                  value: settings.characteristicUuid,
                ),
                _SettingRow(
                  label: 'Battery characteristic UUID',
                  value: settings.batteryCharacteristicUuid,
                ),
                const _SettingRow(
                  label: 'SD status UUID',
                  value: SdBleProtocol.statusCharacteristicUuid,
                ),
                const _SettingRow(
                  label: 'SD data UUID',
                  value: SdBleProtocol.dataCharacteristicUuid,
                ),
                const _SettingRow(
                  label: 'SD command UUID',
                  value: SdBleProtocol.commandCharacteristicUuid,
                ),
                const _SettingRow(
                  label: 'SD control UUID',
                  value: SdBleProtocol.recordingControlCharacteristicUuid,
                ),
                _SettingRow(
                  label: 'Connection',
                  value: deviceState.status.label,
                ),
                _SettingRow(
                  label: 'Battery',
                  value: deviceState.batteryPercent == null
                      ? 'Not connected'
                      : '${deviceState.batteryPercent}%',
                ),
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
                  label: 'Stable window',
                  value: '${settings.stableWindowSize} samples',
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
                const _SettingRow(
                  label: 'Database',
                  value: 'Local JSON storage',
                ),
                _SettingRow(
                  label: 'Patients',
                  value: appState.patients.length.toString(),
                ),
                _SettingRow(
                  label: 'Pain events',
                  value: appState.painEvents.length.toString(),
                ),
                _SettingRow(
                  label: 'Active patient',
                  value: appState.activePatient?.name ?? 'None',
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmClearDatabase(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear local database'),
                ),
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
                  'SD Card Sync',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SettingRow(
                  label: 'Last sync',
                  value: settings.lastSdSyncAt == null
                      ? 'Never'
                      : settings.lastSdSyncAt!.toIso8601String(),
                ),
                _SettingRow(label: 'Status', value: syncState.message),
                _SettingRow(
                  label: 'Imported events',
                  value: syncState.importedEvents.toString(),
                ),
                _SettingRow(
                  label: 'Duplicates skipped',
                  value: syncState.duplicatesSkipped.toString(),
                ),
                _SettingRow(
                  label: 'Malformed rows',
                  value: syncState.malformedRows.toString(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'In SD Card Mode, connect to PressureTX to pause device-side SD recording, sync stored SD files, select the patient, import events, and delete SD data only after a successful import.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local database?'),
        content: const Text(
          'This clears locally saved patients, calibrations, events, and settings, then reloads the starter mock data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await AppStateScope.read(context).clearLocalDatabase();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local database cleared.')));
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
