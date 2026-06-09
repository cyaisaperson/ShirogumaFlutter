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
    final batteryLabel = deviceState.batteryPercent == null
        ? '--%'
        : '${deviceState.batteryPercent}%${deviceState.isBatteryStale ? ' stale' : ''}';
    final modeLabel = settings.dataMode == DataMode.liveBle ? 'Live' : 'SD';
    final connectionLabel = deviceState.status.label;
    final signalState = deviceState.isConnected ? 'streaming' : 'standby';
    final rawValue = deviceState.latestPressure == null
        ? '--'
        : '${deviceState.latestPressure!.toStringAsFixed(0)} mbar';
    final sasValue = latestEvent == null
        ? '--'
        : latestEvent.painLevel.toString();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HomeHeader(
            batteryLabel: batteryLabel,
            connectionLabel: connectionLabel,
            modeLabel: modeLabel,
          ),
          const SizedBox(height: 20),
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
                Row(
                  children: [
                    Text(
                      'LIVE SIGNAL',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _InlineStateChip(label: signalState),
                  ],
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
                      child: _SignalMetric(label: 'Raw', value: rawValue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SignalMetric(label: 'SAS', value: sasValue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _SignalMetric(label: 'Rate', value: '50 Hz'),
                    ),
                  ],
                ),
                if (deviceState.liveRecordingMessage != null) ...[
                  const SizedBox(height: 12),
                  _LiveRecordingNotice(
                    message: deviceState.liveRecordingMessage!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEVICE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Squeeze·01',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                const Text(
                  'XIAO nRF52840',
                  style: TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 14),
                _DeviceInfoRow(label: 'Battery', value: batteryLabel),
                const SizedBox(height: 6),
                const _DeviceInfoRow(label: 'Rate', value: '50 Hz'),
                const SizedBox(height: 6),
                _DeviceInfoRow(
                  label: 'Live saving',
                  value: deviceState.liveSavingStatus,
                ),
                if (deviceState.lastReceivedAt != null) ...[
                  const SizedBox(height: 6),
                  _DeviceInfoRow(
                    label: 'Last update',
                    value: deviceState.lastReceivedAt!.toIso8601String(),
                  ),
                ],
                if (deviceState.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    deviceState.errorMessage!,
                    style: const TextStyle(color: AppColors.coralDark),
                  ),
                ],
                const SizedBox(height: 14),
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
                                  _showDeviceBrowser(context, settings);
                                }
                              },
                        icon: Icon(
                          deviceState.isConnected
                              ? Icons.bluetooth_disabled
                              : Icons.bluetooth_searching,
                        ),
                        label: Text(
                          deviceState.isConnected
                              ? 'Disconnect'
                              : 'Browse devices',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            deviceState.isConnected ||
                                deviceState.status ==
                                    DeviceConnectionStatus.connecting ||
                                deviceState.status ==
                                    DeviceConnectionStatus.scanning
                            ? null
                            : () {
                                if (deviceState.status ==
                                    DeviceConnectionStatus.reconnecting) {
                                  DeviceStateScope.read(context).reconnectNow();
                                } else {
                                  DeviceStateScope.read(
                                    context,
                                  ).connect(settings);
                                }
                              },
                        icon: const Icon(Icons.bluetooth_connected),
                        label: Text(
                          deviceState.status ==
                                  DeviceConnectionStatus.reconnecting
                              ? 'Reconnect'
                              : 'Auto connect',
                        ),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.batteryLabel,
    required this.connectionLabel,
    required this.modeLabel,
  });

  final String batteryLabel;
  final String connectionLabel;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );

    List<Widget> buildChips({required bool showMode}) {
      return [
        _StatusChip(
          icon: Icons.battery_full,
          label: batteryLabel,
          active: batteryLabel != '--%',
        ),
        const SizedBox(width: 8),
        _StatusChip(
          icon: Icons.bluetooth,
          label: connectionLabel,
          active: connectionLabel == 'Connected',
        ),
        if (showMode) ...[
          const SizedBox(width: 8),
          _StatusChip(icon: Icons.circle, label: modeLabel, active: true),
        ],
      ];
    }

    Widget chipRow({required bool showMode}) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: buildChips(showMode: showMode),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showMode = constraints.maxWidth >= 420;
        final chips = chipRow(showMode: showMode);
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: chips),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            Flexible(
              child: Align(alignment: Alignment.topRight, child: chips),
            ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.coralDark : AppColors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.coralSoft : AppColors.sand,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.coral : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStateChip extends StatelessWidget {
  const _InlineStateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final active = label == 'streaming';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.coralSoft : AppColors.sand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.coralDark : AppColors.mutedText,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SignalMetric extends StatelessWidget {
  const _SignalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ],
    );
  }
}

class _DeviceInfoRow extends StatelessWidget {
  const _DeviceInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label:', style: const TextStyle(color: AppColors.mutedText)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _LiveRecordingNotice extends StatelessWidget {
  const _LiveRecordingNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.coralDark,
          fontWeight: FontWeight.w900,
        ),
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
