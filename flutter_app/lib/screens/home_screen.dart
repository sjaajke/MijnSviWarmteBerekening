import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'input_screen.dart';
import 'components_screen.dart';
import 'results_screen.dart';
import 'explanation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    InputScreen(),
    ComponentsScreen(),
    ResultsScreen(),
    ExplanationScreen(),
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Invoer',
    ),
    NavigationDestination(
      icon: Icon(Icons.electrical_services_outlined),
      selectedIcon: Icon(Icons.electrical_services),
      label: 'Componenten',
    ),
    NavigationDestination(
      icon: Icon(Icons.thermostat_outlined),
      selectedIcon: Icon(Icons.thermostat),
      label: 'Resultaten',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Uitleg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IEC TR 60890:2022'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            tooltip: context.watch<ThemeNotifier>().mode == ThemeMode.dark
                ? 'Lichte weergave'
                : 'Donkere weergave',
            icon: Icon(
              context.watch<ThemeNotifier>().mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeNotifier>().toggle(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _destinations,
      ),
    );
  }
}
