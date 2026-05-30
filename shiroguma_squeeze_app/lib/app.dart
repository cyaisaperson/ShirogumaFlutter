import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/patient_data_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'theme/app_theme.dart';

class ShirogumaApp extends StatefulWidget {
  const ShirogumaApp({super.key});

  @override
  State<ShirogumaApp> createState() => _ShirogumaAppState();
}

class _ShirogumaAppState extends State<ShirogumaApp> {
  late final AppState appState = AppState.seeded();

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: appState,
      child: MaterialApp(
        title: 'Shiroguma Squeeze',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
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

  final pages = const [
    HomeScreen(),
    PatientsScreen(),
    PatientDataScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
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
}
