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
          const SizedBox(height: 20),
          for (final patient in appState.patients) ...[
            _PatientCard(
              patient: patient,
              isActive: appState.settings.activePatientId == patient.id,
              onTap: () =>
                  AppStateScope.read(context).setActivePatient(patient.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.isActive,
    required this.onTap,
  });

  final Patient patient;
  final bool isActive;
  final VoidCallback onTap;

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
