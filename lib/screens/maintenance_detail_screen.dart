import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jcc_reminder/models/equipment.dart';
import 'package:jcc_reminder/models/maintenance_record.dart';
import 'package:jcc_reminder/screens/add_maintenance_screen.dart';
import 'package:jcc_reminder/services/auth_service.dart';
import 'package:jcc_reminder/services/firestore_service.dart';
import 'package:jcc_reminder/utils/maintenance_utils.dart';
import 'package:jcc_reminder/widgets/confirm_dialog.dart';

class MaintenanceDetailScreen extends StatelessWidget {
  final MaintenanceRecord maintenance;
  final Equipment equipment;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  MaintenanceDetailScreen({
    super.key,
    required this.maintenance,
    required this.equipment,
  });

  Future<void> _onDelete(BuildContext context) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in to delete.')),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Maintenance',
      content: 'Are you sure you want to delete this maintenance record?',
      confirmText: 'Delete',
    );

    if (confirmed && context.mounted) {
      try {
        await _firestoreService.deleteMaintenance(
          equipmentId: equipment.id,
          maintenanceId: maintenance.id,
          userId: userId,
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(maintenance.type),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Maintenance',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMaintenanceScreen(
                    equipment: equipment,
                    maintenanceToEdit: maintenance,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailCard(context),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMaintenanceScreen(
                      equipment: equipment,
                      maintenanceToEdit: maintenance,
                    ),
                  ),
                );
              },
              child: const Text('EDIT'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _onDelete(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('DELETE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    final nextMaintenanceDate = calculateNextMaintenanceDate(
      lastMaintenanceDate: maintenance.lastDate,
      hoursLimit: maintenance.hoursLimit,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Maintenance Type', maintenance.type),
            const Divider(),
            _buildDetailRow(
              context,
              'Last Maintenance Date',
              DateFormat.yMMMMd().format(maintenance.lastDate),
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Last Hours Reading',
              '${maintenance.lastHours} hrs',
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Maintenance Interval',
              '${maintenance.hoursLimit} hrs',
            ),
            const Divider(thickness: 1.5, height: 32),
            _buildDetailRow(
              context,
              'Next Estimated Maintenance',
              DateFormat.yMMMMd().format(nextMaintenanceDate),
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            value,
            style: isHighlight
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
