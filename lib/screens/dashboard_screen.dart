import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jcc_reminder/models/equipment.dart';
import 'package:jcc_reminder/screens/add_equipment_screen.dart';
import 'package:jcc_reminder/screens/equipment_info_screen.dart';
import 'package:jcc_reminder/screens/settings_screen.dart';
import 'package:jcc_reminder/services/auth_service.dart';
import 'package:jcc_reminder/services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late final Stream<List<Equipment>> _equipmentStream;

  @override
  void initState() {
    super.initState();
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _equipmentStream = _firestoreService.getEquipmentStream(userId);
    } else {
      _equipmentStream = Stream.value([]);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEquipmentScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Dashboard')),
      body: StreamBuilder<List<Equipment>>(
        stream: _equipmentStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Dashboard Stream Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final equipmentList = snapshot.data ?? [];

          if (equipmentList.isEmpty) {
            return const Center(
              child: Text(
                'No equipment found.\nTap the "Add" button to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: equipmentList.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final equipment = equipmentList[index];
              return _EquipmentListItem(equipment: equipment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(1),
        tooltip: 'Add Equipment',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.dashboard),
              color: _selectedIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              onPressed: () => _onItemTapped(0),
              tooltip: 'Dashboard',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              color: _selectedIndex == 2
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              onPressed: () => _onItemTapped(2),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentListItem extends StatelessWidget {
  const _EquipmentListItem({required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    Widget leadingImage;
    if (equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty) {
      leadingImage = Image.network(
        equipment.imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: 48,
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('lib/assets/buldozer.png', height: 48, width: 48);
        },
      );
    } else {
      leadingImage = Image.asset(
        'lib/assets/buldozer.png',
        height: 48,
        width: 48,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: leadingImage,
        ),
        title: Text(
          equipment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${equipment.driver}\n${equipment.model}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EquipmentInfoScreen(equipment: equipment),
            ),
          );
        },
      ),
    );
  }
}
