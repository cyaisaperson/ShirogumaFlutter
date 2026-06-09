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
    final createdPatient = await showDialog<Patient>(
      context: context,
      builder: (dialogContext) => _PatientDialog(
        patient: patient,
        onCalibrate: (patient) => _openPatientData(context, patient),
      ),
    );
    if (!context.mounted || patient != null || createdPatient == null) {
      return;
    }
    await _showMvsPrompt(context, createdPatient);
  }

  void _openPatientData(BuildContext context, Patient patient) {
    AppStateScope.read(context).setActivePatient(patient.id);
    onNavigate?.call(2);
  }

  Future<void> _showMvsPrompt(BuildContext context, Patient patient) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calibrate MVS?'),
        content: Text(
          '${patient.name} was added. MVS: Not calibrated. Live pain-level detection stays blocked until MVS is calibrated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Skip calibration'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openPatientData(context, patient);
            },
            child: const Text('Calibrate MVS'),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.calibration,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
  });

  final Patient patient;
  final Calibration? calibration;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: isActive ? AppCardTone.dark : AppCardTone.normal,
      onTap: onTap,
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                border: Border.all(color: AppColors.coral, width: 2),
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        padding: isActive ? const EdgeInsets.all(10) : EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isActive ? AppColors.coral : AppColors.sand,
              foregroundColor: isActive ? Colors.white : AppColors.coralDark,
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
                  const SizedBox(height: 8),
                  Text(
                    _mvsLabel(calibration),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.mutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _mvsLabel(Calibration? calibration) {
    if (calibration == null) {
      return 'MVS: Not calibrated';
    }
    return 'MVS: ${calibration.mvsPressure.toStringAsFixed(0)} mbar';
  }
}

class _PatientDialog extends StatefulWidget {
  const _PatientDialog({this.patient, required this.onCalibrate});

  final Patient? patient;
  final ValueChanged<Patient> onCalibrate;

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
              if (isEditing) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onCalibrate(widget.patient!);
                    },
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Calibrate MVS'),
                  ),
                ),
              ],
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
      final createdPatient = await appState.addPatient(
        name: nameController.text,
        patientCode: patientCodeController.text,
        age: age,
        description: descriptionController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(createdPatient);
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
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }
  }
}
