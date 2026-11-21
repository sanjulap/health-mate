import 'package:flutter/material.dart';

import 'add_edit_record_screen.dart';
import 'dashboard_screen.dart';
import 'record_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationScreenState>();
  }

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void switchTab(int index) {
    if (index < 0 || index > 1) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> openAddRecord() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditRecordScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [const DashboardScreen(), const RecordListScreen()];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
