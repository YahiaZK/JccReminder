import 'package:flutter/material.dart';
import 'package:jcc_reminder/models/equipment.dart';
import 'package:jcc_reminder/models/maintenance_record.dart';
import 'package:jcc_reminder/screens/add_equipment_screen.dart';
import 'package:jcc_reminder/screens/add_maintenance_screen.dart';
import 'package:jcc_reminder/screens/maintenance_detail_screen.dart';
import 'package:jcc_reminder/services/auth_service.dart';
import 'package:jcc_reminder/services/firestore_service.dart';
import 'package:jcc_reminder/widgets/confirm_dialog.dart';

class EquipmentInfoScreen extends StatelessWidget {
  final Equipment equipment;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  EquipmentInfoScreen({super.key, required this.equipment});

  void _onDelete(BuildContext context) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not logged in to delete.')),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Equipment',
      content:
          'Are you sure you want to delete "${equipment.name}"? This action cannot be undone.',
      confirmText: 'Delete',
    );

    if (confirmed && context.mounted) {
      try {
        await _firestoreService.deleteEquipment(equipment.id, userId);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Error deleting equipment: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete equipment: $e')),
          );
        }
      }
    }
  }

  void _onEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEquipmentScreen(equipmentToEdit: equipment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User not found. Please log in again.")),
      );
    }

    Widget equipmentImage;
    if (equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty) {
      equipmentImage = Image.network(
        equipment.imageUrl!,
        height: 64,
        width: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('lib/assets/buldozer.png', height: 64, width: 64),
      );
    } else {
      equipmentImage = Image.asset(
        'lib/assets/buldozer.png',
        height: 64,
        width: 64,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: () => _onDelete(context),
            tooltip: 'Delete Equipment',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: equipmentImage,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('Driver: ${equipment.driver}'),
                      Text('Chassis Number: ${equipment.model}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _onEdit(context),
                  tooltip: 'Edit Equipment',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Working Hours',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${equipment.workingHours} hrs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 40),
            Text(
              'Maintenance History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<MaintenanceRecord>>(
                stream: _firestoreService.getMaintenanceStream(
                  equipmentId: equipment.id,
                  userId: userId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No maintenance records yet.'),
                    );
                  }

                  final records = snapshot.data!;
                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final maintenance = records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            maintenance.type,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaintenanceDetailScreen(
                                  maintenance: maintenance,
                                  equipment: equipment,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('ADD MAINTENANCE'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMaintenanceScreen(equipment: equipment),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
