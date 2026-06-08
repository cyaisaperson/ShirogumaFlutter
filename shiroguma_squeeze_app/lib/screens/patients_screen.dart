import 'package:flutter/material.dart';

import '../models/calibration.dart';
import '../models/patient.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Patient roster',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a patient to make them active across the app.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showPatientDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add patient'),
          ),
          const SizedBox(height: 20),
          for (final patient in appState.patients) ...[
            _PatientCard(
              patient: patient,
              calibration: appState.calibrationForPatient(patient.id),
              isActive: appState.settings.activePatientId == patient.id,
              onTap: () =>
                  AppStateScope.read(context).setActivePatient(patient.id),
              onOpenData: () {
                AppStateScope.read(context).setActivePatient(patient.id);
                onNavigate?.call(2);
              },
              onEdit: () => _showPatientDialog(context, patient: patient),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _showPatientDialog(
    BuildContext context, {
    Patient? patient,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PatientDialog(patient: patient),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.calibration,
    required this.isActive,
    required this.onTap,
    required this.onOpenData,
    required this.onEdit,
  });

  final Patient patient;
  final Calibration? calibration;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onOpenData;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: isActive ? AppCardTone.coral : AppCardTone.normal,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isActive ? Colors.white : AppColors.sand,
            foregroundColor: AppColors.coralDark,
            child: Text(_initials(patient.name)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        patient.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.coralDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Edit ${patient.name}',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.patientCode}${patient.age == null ? '' : ' - Age ${patient.age}'}',
                ),
                const SizedBox(height: 8),
                Text(patient.description),
                const SizedBox(height: 12),
                _CalibrationSummary(calibration: calibration),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onOpenData,
                    icon: const Icon(Icons.tune),
                    label: Text(
                      calibration == null
                          ? 'Open calibration'
                          : 'View calibration',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _CalibrationSummary extends StatelessWidget {
  const _CalibrationSummary({required this.calibration});

  final Calibration? calibration;

  @override
  Widget build(BuildContext context) {
    final calibration = this.calibration;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.mutedText,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.sand),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed, color: AppColors.coralDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MVS calibration', style: labelStyle),
                const SizedBox(height: 2),
                Text(
                  calibration == null
                      ? 'Not calibrated'
                      : '${calibration.mvsPressure.toStringAsFixed(0)} mbar',
                  style: valueStyle,
                ),
              ],
            ),
          ),
          if (calibration != null)
            Text(
              'Baseline ${calibration.baselinePressure.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.mutedText),
            ),
        ],
      ),
    );
  }
}

class _PatientDialog extends StatefulWidget {
  const _PatientDialog({this.patient});

  final Patient? patient;

  @override
  State<_PatientDialog> createState() => _PatientDialogState();
}

class _PatientDialogState extends State<_PatientDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController patientCodeController;
  late final TextEditingController ageController;
  late final TextEditingController descriptionController;

  bool get isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    nameController = TextEditingController(text: patient?.name ?? '');
    patientCodeController = TextEditingController(
      text: patient?.patientCode ?? AppStateScope.read(context).nextPatientCode,
    );
    ageController = TextEditingController(text: patient?.age?.toString() ?? '');
    descriptionController = TextEditingController(
      text: patient?.description ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    patientCodeController.dispose();
    ageController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit patient' : 'Add patient'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              TextFormField(
                controller: patientCodeController,
                decoration: const InputDecoration(labelText: 'Patient ID'),
                textInputAction: TextInputAction.next,
                validator: _patientCodeValidator,
              ),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _ageValidator,
              ),
              TextFormField(
                controller: descriptionController,
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
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save changes' : 'Save patient'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _ageValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0 || parsed > 130) {
      return 'Enter a valid age';
    }
    return null;
  }

  String? _patientCodeValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) {
      return requiredError;
    }
    final patient = widget.patient;
    final codeTaken = AppStateScope.read(
      context,
    ).isPatientCodeTaken(value!, exceptPatientId: patient?.id);
    if (codeTaken) {
      return 'Patient ID already exists';
    }
    return null;
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final ageText = ageController.text.trim();
    final age = ageText.isEmpty ? null : int.parse(ageText);
    final appState = AppStateScope.read(context);
    final patient = widget.patient;

    if (patient == null) {
      await appState.addPatient(
        name: nameController.text,
        patientCode: patientCodeController.text,
        age: age,
        description: descriptionController.text,
      );
    } else {
      await appState.updatePatient(
        patient.copyWith(
          name: nameController.text.trim(),
          patientCode: patientCodeController.text.trim(),
          age: age,
          clearAge: age == null,
          description: descriptionController.text.trim(),
        ),
      );
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}
