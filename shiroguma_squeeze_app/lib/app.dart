import 'package:flutter/material.dart';
import 'models/app_settings.dart';
import 'models/patient.dart';
import 'screens/home_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/patient_data_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'state/device_state.dart';
import 'state/device_state_scope.dart';
import 'state/sd_card_sync_state.dart';
import 'state/sd_card_sync_state_scope.dart';
import 'theme/app_theme.dart';

class ShirogumaApp extends StatefulWidget {
  const ShirogumaApp({super.key});

  @override
  State<ShirogumaApp> createState() => _ShirogumaAppState();
}

class _ShirogumaAppState extends State<ShirogumaApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final AppState appState = AppState.seeded();
  late final DeviceState deviceState = DeviceState();
  late final SdCardSyncState sdCardSyncState = SdCardSyncState();
  DeviceConnectionStatus? _lastDeviceStatus;

  @override
  void initState() {
    super.initState();
    appState.addListener(_syncLiveDetectionContext);
    deviceState.addListener(_syncSdCardModeAfterConnect);
    _syncLiveDetectionContext();
    appState.loadPersistedState().then((_) => _syncLiveDetectionContext());
  }

  @override
  void dispose() {
    appState.removeListener(_syncLiveDetectionContext);
    deviceState.removeListener(_syncSdCardModeAfterConnect);
    sdCardSyncState.dispose();
    deviceState.dispose();
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: appState,
      child: DeviceStateScope(
        deviceState: deviceState,
        child: SdCardSyncStateScope(
          syncState: sdCardSyncState,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Shiroguma Squeeze',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const MainNavigationScreen(),
          ),
        ),
      ),
    );
  }

  void _syncLiveDetectionContext() {
    deviceState.configureLiveDetection(
      activePatientId: appState.activePatient?.id,
      calibration: appState.activeCalibration,
      settings: appState.settings,
      onPainEvent: appState.savePainEvent,
    );
  }

  void _syncSdCardModeAfterConnect() {
    final wasConnected = _lastDeviceStatus == DeviceConnectionStatus.connected;
    final isConnected = deviceState.status == DeviceConnectionStatus.connected;
    _lastDeviceStatus = deviceState.status;
    if (wasConnected ||
        !isConnected ||
        appState.settings.dataMode != DataMode.sdCard ||
        sdCardSyncState.syncInProgress) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSdCardSyncPrompt();
    });
  }

  Future<void> _startSdCardSyncPrompt() async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted || !deviceState.isConnected) {
      return;
    }
    await sdCardSyncState.syncAfterDeviceConnected(
      deviceState: deviceState,
      appState: appState,
      selectPatient: (patients) =>
          _showSdPatientSelectionDialog(context, patients),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(sdCardSyncState.message)));
  }

  Future<String?> _showSdPatientSelectionDialog(
    BuildContext context,
    List<Patient> patients,
  ) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select patient for imported data'),
        content: SizedBox(
          width: double.maxFinite,
          child: patients.isEmpty
              ? const Text('Add a patient before importing SD card data.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: patients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return ListTile(
                      title: Text(patient.name),
                      subtitle: Text(patient.patientCode),
                      onTap: () => Navigator.of(context).pop(patient.id),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _selectIndex),
      PatientsScreen(onNavigate: _selectIndex),
      const PatientDataScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          _selectIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: 'Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _selectIndex(int index) {
    setState(() {
      currentIndex = index;
    });
  }
}
