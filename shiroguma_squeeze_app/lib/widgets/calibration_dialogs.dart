import 'dart:async';

import 'package:flutter/material.dart';

import '../models/calibration.dart';
import '../state/app_state_scope.dart';
import '../state/device_state.dart';
import '../state/device_state_scope.dart';
import '../theme/app_colors.dart';

class LiveCalibrationDialog extends StatefulWidget {
  const LiveCalibrationDialog({super.key, required this.patientId});

  final String patientId;

  @override
  State<LiveCalibrationDialog> createState() => _LiveCalibrationDialogState();
}

class _LiveCalibrationDialogState extends State<LiveCalibrationDialog> {
  Timer? countdownTimer;
  int? countdownSeconds;

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = DeviceStateScope.watch(context);
    final result = deviceState.liveCalibrationResult;
    final latestPressure = deviceState.latestPressure;
    final canSave = result?.valid == true;
    final step = _calibrationStep(deviceState, countdownSeconds);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
      title: Row(
        children: [
          const Expanded(child: Text('Live MVS calibration')),
          IconButton(
            tooltip: 'Close',
            onPressed: () {
              countdownTimer?.cancel();
              DeviceStateScope.read(context).resetLiveCalibration();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Calibration - ${step.index + 1} of 3',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: index <= step.index
                            ? AppColors.coral
                            : AppColors.sand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (index < 2) const SizedBox(width: 6),
                ],
              ],
            ),
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
            Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              step.body,
              style: const TextStyle(color: AppColors.mutedText, height: 1.35),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CalibrationMiniMetric(
                    label: 'Baseline',
                    value: result == null || result.baselinePressure <= 0
                        ? _baselineLabel(deviceState)
                        : '${result.baselinePressure.toStringAsFixed(0)} mbar',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CalibrationMiniMetric(
                    label: 'MVS',
                    value: result == null || result.mvsPressure <= 0
                        ? _mvsProgressLabel(deviceState)
                        : '${result.mvsPressure.toStringAsFixed(0)} mbar',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CalibrationDetailLine(
              label: 'Samples',
              value: deviceState.liveCalibrationSampleCount.toString(),
            ),
            if (result != null)
              Text(
                result.reason,
                style: TextStyle(
                  color: result.valid ? AppColors.coralDark : Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (deviceState.isLiveCalibrationRecording || countdownSeconds != null)
          const SizedBox.shrink()
        else if (result == null)
          FilledButton(onPressed: _beginCountdown, child: const Text('Begin'))
        else
          FilledButton(
            onPressed: _beginCountdown,
            child: const Text('Recalibrate'),
          ),
        if (canSave)
          FilledButton(
            onPressed: () async {
              await AppStateScope.read(context).saveCalibration(
                patientId: widget.patientId,
                baselinePressure: result!.baselinePressure,
                mvsPressure: result.mvsPressure,
                samplesUsed: result.samplesUsed,
                notes: 'Live MVS calibration',
              );
              if (!context.mounted) return;
              DeviceStateScope.read(context).resetLiveCalibration();
              Navigator.of(context).pop();
            },
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

  void _beginCountdown() {
    countdownTimer?.cancel();
    DeviceStateScope.read(context).resetLiveCalibration();
    setState(() {
      countdownSeconds = 3;
    });
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = countdownSeconds;
      if (current == null) {
        timer.cancel();
        return;
      }
      if (current <= 1) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          countdownSeconds = null;
        });
        DeviceStateScope.read(context).startLiveCalibration();
        return;
      }
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        countdownSeconds = current - 1;
      });
    });
  }

  _GuidedCalibrationStep _calibrationStep(
    DeviceState deviceState,
    int? countdown,
  ) {
    final result = deviceState.liveCalibrationResult;
    if (result?.valid == true) {
      return const _GuidedCalibrationStep(
        index: 2,
        title: 'All set',
        body:
            'Stable MVS found. Review the values, then save this calibration.',
      );
    }
    if (countdown != null) {
      return _GuidedCalibrationStep(
        index: 1,
        title: 'Press in $countdown',
        body:
            'Get ready. Squeeze when the countdown finishes, hold for 3 seconds, then release.',
      );
    }
    if (deviceState.isLiveCalibrationRecording) {
      return const _GuidedCalibrationStep(
        index: 1,
        title: 'Maximum squeeze',
        body:
            'Squeeze for 3 seconds, then release. Recording stops when pressure returns to baseline.',
      );
    }
    if (result != null && !result.valid) {
      return const _GuidedCalibrationStep(
        index: 2,
        title: 'Try again',
        body:
            'The last attempt was not stable enough. Reset your grip and recalibrate.',
      );
    }
    return const _GuidedCalibrationStep(
      index: 0,
      title: 'Get comfortable',
      body:
          'Hold the soft device naturally. The app uses the continuously tracked idle baseline, so this step only captures MVS.',
    );
  }

  String _baselineLabel(DeviceState deviceState) {
    final baseline =
        deviceState.liveCalibrationBaselinePressure ??
        deviceState.idleBaselinePressure;
    if (baseline == null || !baseline.isFinite || baseline <= 0) {
      return 'Tracking';
    }
    return '${baseline.toStringAsFixed(0)} mbar';
  }

  String _mvsProgressLabel(DeviceState deviceState) {
    if (!deviceState.isLiveCalibrationRecording) {
      return 'Waiting';
    }
    final seconds = (deviceState.liveCalibrationSampleCount / 50).clamp(0, 3);
    return '${seconds.toStringAsFixed(1)}s';
  }
}

class ManualCalibrationDialog extends StatefulWidget {
  const ManualCalibrationDialog({
    super.key,
    required this.patientId,
    required this.calibration,
  });

  final String patientId;
  final Calibration? calibration;

  @override
  State<ManualCalibrationDialog> createState() =>
      _ManualCalibrationDialogState();
}

class _ManualCalibrationDialogState extends State<ManualCalibrationDialog> {
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

class _GuidedCalibrationStep {
  const _GuidedCalibrationStep({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;
}

class _CalibrationMiniMetric extends StatelessWidget {
  const _CalibrationMiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sand.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CalibrationDetailLine extends StatelessWidget {
  const _CalibrationDetailLine({required this.label, required this.value});

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
              style: const TextStyle(color: AppColors.mutedText),
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
