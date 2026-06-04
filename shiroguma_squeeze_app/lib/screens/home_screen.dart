import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/ble_service.dart';
import '../state/app_state_scope.dart';
import '../state/device_state.dart';
import '../state/device_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final activePatient = appState.activePatient;
    final activeEvents = appState.activePatientEvents;
    final latestEvent = activeEvents.isEmpty ? null : activeEvents.first;
    final settings = appState.settings;
    final deviceState = DeviceStateScope.watch(context);

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
                    child: Text(
                      deviceState.latestPressure == null
                          ? 'Waiting'
                          : '${deviceState.latestPressure!.toStringAsFixed(0)} mbar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SignalStatusTile(
                        label: 'Mode',
                        value: settings.dataMode.label,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SignalStatusTile(
                        label: 'Battery',
                        value: deviceState.batteryPercent == null
                            ? 'Not connected'
                            : '${deviceState.batteryPercent}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SignalStatusTile(
                  label: 'Connection',
                  value:
                      '${deviceState.status.label}${deviceState.connectedDeviceName == null ? '' : ' - ${deviceState.connectedDeviceName}'}',
                ),
                if (deviceState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    deviceState.errorMessage!,
                    style: const TextStyle(color: AppColors.coralDark),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            deviceState.status ==
                                    DeviceConnectionStatus.scanning ||
                                deviceState.status ==
                                    DeviceConnectionStatus.connecting
                            ? null
                            : () {
                                if (deviceState.isConnected) {
                                  DeviceStateScope.read(context).disconnect();
                                } else {
                                  DeviceStateScope.read(
                                    context,
                                  ).connect(settings);
                                }
                              },
                        icon: Icon(
                          deviceState.isConnected
                              ? Icons.bluetooth_disabled
                              : Icons.bluetooth_searching,
                        ),
                        label: Text(
                          deviceState.isConnected ? 'Disconnect' : 'Connect',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: deviceState.isConnected
                            ? null
                            : () => _showDeviceBrowser(context, settings),
                        icon: const Icon(Icons.manage_search),
                        label: const Text('Browse devices'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: () => onNavigate?.call(1),
                  child: const _QuickAction(
                    icon: Icons.people,
                    label: 'Manage patients',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  onTap: () => onNavigate?.call(2),
                  child: const _QuickAction(
                    icon: Icons.insert_chart,
                    label: 'Open data',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: _CardHeader(
              icon: Icons.bluetooth_disabled,
              title:
                  '${settings.preferredDeviceName} ${deviceState.status.label}',
              subtitle: deviceState.lastReceivedAt == null
                  ? 'No live data received yet.'
                  : 'Last update ${deviceState.lastReceivedAt!.toIso8601String()}',
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

Future<void> _showDeviceBrowser(
  BuildContext context,
  AppSettings settings,
) async {
  final deviceState = DeviceStateScope.read(context);
  await showDialog<void>(
    context: context,
    builder: (context) =>
        _BleDeviceBrowserDialog(deviceState: deviceState, settings: settings),
  );
}

class _BleDeviceBrowserDialog extends StatefulWidget {
  const _BleDeviceBrowserDialog({
    required this.deviceState,
    required this.settings,
  });

  final DeviceState deviceState;
  final AppSettings settings;

  @override
  State<_BleDeviceBrowserDialog> createState() =>
      _BleDeviceBrowserDialogState();
}

class _BleDeviceBrowserDialogState extends State<_BleDeviceBrowserDialog> {
  late final Stream<List<BleDiscoveredDevice>> devicesStream;

  @override
  void initState() {
    super.initState();
    devicesStream = widget.deviceState.browseDevices(widget.settings);
  }

  @override
  void dispose() {
    widget.deviceState.stopBrowsing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Browse Bluetooth devices'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<BleDiscoveredDevice>>(
          stream: devicesStream,
          initialData: widget.deviceState.discoveredDevices,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Scan failed: ${snapshot.error}');
            }
            final devices = snapshot.data ?? const [];
            if (devices.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning for nearby Bluetooth devices...'),
                  ],
                ),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: devices.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(device.displayName),
                    subtitle: Text('${device.id} - RSSI ${device.rssi}'),
                    onTap: () async {
                      await widget.deviceState.stopBrowsing();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      await widget.deviceState.connectToDiscoveredDevice(
                        widget.settings,
                        device,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SignalStatusTile extends StatelessWidget {
  const _SignalStatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.coralDark),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
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
