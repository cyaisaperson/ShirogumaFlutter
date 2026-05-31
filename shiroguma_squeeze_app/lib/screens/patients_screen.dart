import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PatientDialog(patient: patient),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
  });

  final Patient patient;
  final bool isActive;
  final VoidCallback onTap;
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
      text: patient?.patientCode ?? '',
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
                validator: _required,
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

  void _save() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final ageText = ageController.text.trim();
    final age = ageText.isEmpty ? null : int.parse(ageText);
    final appState = AppStateScope.read(context);
    final patient = widget.patient;

    if (patient == null) {
      appState.addPatient(
        name: nameController.text,
        patientCode: patientCodeController.text,
        age: age,
        description: descriptionController.text,
      );
    } else {
      appState.updatePatient(
        patient.copyWith(
          name: nameController.text.trim(),
          patientCode: patientCodeController.text.trim(),
          age: age,
          clearAge: age == null,
          description: descriptionController.text.trim(),
        ),
      );
    }

    Navigator.of(context).pop();
  }
}
