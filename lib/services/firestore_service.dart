import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:jcc_reminder/models/equipment.dart';
import 'package:jcc_reminder/models/maintenance_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(
    File imageFile,
    String equipmentId,
    String userId,
  ) async {
    try {
      final ref = _storage.ref().child(
        'equipment_images/$userId/$equipmentId.jpg',
      );
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Stream<List<Equipment>> getEquipmentStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Equipment.fromFirestore(doc);
          }).toList(),
        );
  }

  Future<DocumentReference> addEquipment(
    Map<String, dynamic> data,
    String userId,
  ) async {
    return await _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .add(data);
  }

  Future<void> deleteEquipment(String equipmentId, String userId) async {
    final equipmentRef = _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .doc(equipmentId);

    final maintenanceSnapshot = await equipmentRef
        .collection('maintenance')
        .get();
    if (maintenanceSnapshot.docs.isNotEmpty) {
      WriteBatch batch = _db.batch();
      for (final doc in maintenanceSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _storage
        .ref()
        .child('equipment_images/$userId/$equipmentId.jpg')
        .delete()
        .catchError((e) {
          debugPrint('Could not delete image for $equipmentId: $e');
        });

    await equipmentRef.delete();
  }

  Future<void> updateEquipment({
    required Map<String, dynamic> data,
    required String userId,
    required String equipmentId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .doc(equipmentId)
        .update(data);
  }

  Stream<List<MaintenanceRecord>> getMaintenanceStream({
    required String equipmentId,
    required String userId,
  }) {
    final maintenanceCollection = _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .doc(equipmentId)
        .collection('maintenance');

    return maintenanceCollection
        .orderBy('last_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaintenanceRecord.fromFirestore(doc))
              .toList(),
        );
  }

  Future<DocumentReference> addOrUpdateMaintenance({
    required String equipmentId,
    required String userId,
    required Map<String, dynamic> data,
    String? maintenanceId,
  }) async {
    final collectionRef = _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .doc(equipmentId)
        .collection('maintenance');

    if (maintenanceId != null) {
      await collectionRef.doc(maintenanceId).update(data);
      return collectionRef.doc(maintenanceId);
    } else {
      return await collectionRef.add(data);
    }
  }

  Future<void> deleteMaintenance({
    required String equipmentId,
    required String maintenanceId,
    required String userId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('equipment')
        .doc(equipmentId)
        .collection('maintenance')
        .doc(maintenanceId)
        .delete();
  }
}
