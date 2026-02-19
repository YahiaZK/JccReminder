import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jcc_reminder/models/equipment.dart';
import 'package:jcc_reminder/models/maintenance_record.dart';
import 'package:jcc_reminder/screens/maintenance_detail_screen.dart';
import 'package:jcc_reminder/services/firestore_service.dart';
import 'package:jcc_reminder/services/auth_service.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final Equipment equipment;
  final MaintenanceRecord? maintenanceToEdit;

  const AddMaintenanceScreen({
    super.key,
    required this.equipment,
    this.maintenanceToEdit,
  });

  bool get isEditing => maintenanceToEdit != null;

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _lastHoursController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.maintenanceToEdit != null) {
      final record = widget.maintenanceToEdit!;
      _nameController.text = record.type;
      _limitController.text = record.hoursLimit.toString();
      _lastHoursController.text = record.lastHours.toString();
      _selectedDate = record.lastDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _lastHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMaintenance() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a maintenance date.')),
      );
      return;
    }

    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final maintenanceData = {
      'type': _nameController.text.trim(),
      'hours_limit': int.tryParse(_limitController.text.trim()) ?? 0,
      'last_hours': double.tryParse(_lastHoursController.text.trim()) ?? 0.0,
      'last_date': Timestamp.fromDate(_selectedDate!),
      'created_at': widget.isEditing
          ? widget.maintenanceToEdit!.createdAt
          : Timestamp.now(),
    };

    try {
      final docRef = await _firestoreService.addOrUpdateMaintenance(
        equipmentId: widget.equipment.id,
        userId: userId,
        data: maintenanceData,
        maintenanceId: widget.maintenanceToEdit?.id,
      );

      final savedDoc = await docRef.get();
      final savedRecord = MaintenanceRecord.fromFirestore(savedDoc);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceDetailScreen(
              maintenance: savedRecord,
              equipment: widget.equipment,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Maintenance' : 'Add Maintenance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Name',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter maintenance name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limitController,
                  decoration: const InputDecoration(
                    labelText: 'Hours Until Next',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter hours limit' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Working Hours (at maintenance)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Enter working hours at maintenance'
                      : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 16),
                    const Text('Last Maintenance Date:'),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickDate,
                      child: Text(
                        _selectedDate != null
                            ? DateFormat.yMMMd().format(_selectedDate!)
                            : 'Select Date',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveMaintenance,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SAVE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
