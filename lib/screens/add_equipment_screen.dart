import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jcc_reminder/models/equipment.dart';
import 'package:jcc_reminder/services/firestore_service.dart';
import 'package:jcc_reminder/services/auth_service.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Equipment? equipmentToEdit;
  const AddEquipmentScreen({super.key, this.equipmentToEdit});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _driverController = TextEditingController();
  final _modelController = TextEditingController();
  final _hoursController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.equipmentToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final equipment = widget.equipmentToEdit!;
      _nameController.text = equipment.name;
      _driverController.text = equipment.driver;
      _modelController.text = equipment.model;
      _hoursController.text = equipment.workingHours.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _driverController.dispose();
    _modelController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveEquipment() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: You must be logged in to save equipment.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final Map<String, dynamic> equipmentData = {
        'name': _nameController.text.trim(),
        'driver': _driverController.text.trim().isEmpty
            ? 'N/A'
            : _driverController.text.trim(),
        'model': _modelController.text.trim().isEmpty
            ? 'N/A'
            : _modelController.text.trim(),
        'working_hours': double.tryParse(_hoursController.text.trim()) ?? 0.0,
      };

      if (_isEditing) {
        final equipmentId = widget.equipmentToEdit!.id;
        String? newImageUrl;

        if (_imageFile != null) {
          newImageUrl = await _firestoreService.uploadImage(
            _imageFile!,
            equipmentId,
            userId,
          );
          equipmentData['image_url'] = newImageUrl;
        }

        await _firestoreService.updateEquipment(
          data: equipmentData,
          userId: userId,
          equipmentId: equipmentId,
        );
      } else {
        equipmentData['created_at'] = Timestamp.now();
        equipmentData['image_url'] = null;

        final newDocRef = await _firestoreService.addEquipment(
          equipmentData,
          userId,
        );

        if (_imageFile != null) {
          final imageUrl = await _firestoreService.uploadImage(
            _imageFile!,
            newDocRef.id,
            userId,
          );
          await newDocRef.update({'image_url': imageUrl});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Equipment ${_isEditing ? 'updated' : 'added'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        if (_isEditing) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error saving equipment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving equipment: $e')));
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
        title: Text(_isEditing ? 'Edit Equipment' : 'Add Equipment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_isEditing &&
                                        widget.equipmentToEdit?.imageUrl != null
                                    ? NetworkImage(
                                        widget.equipmentToEdit!.imageUrl!,
                                      )
                                    : null)
                                as ImageProvider?,
                      child:
                          _imageFile == null &&
                              (!_isEditing ||
                                  widget.equipmentToEdit?.imageUrl == null)
                          ? Icon(
                              Icons.add_a_photo,
                              color: Colors.grey[600],
                              size: 50,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _driverController,
                  decoration: const InputDecoration(labelText: 'Driver'),
                  validator: null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Chassis Number',
                  ),
                  validator: null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(labelText: 'Working Hours'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter working hours';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveEquipment,
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
                      : Text(_isEditing ? 'SAVE CHANGES' : 'SAVE EQUIPMENT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
