import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String name;
  final String driver;
  final String model;
  final String? imageUrl;
  final double workingHours;
  final DateTime createdAt;

  Equipment({
    required this.id,
    required this.name,
    required this.driver,
    required this.model,
    this.imageUrl,
    required this.workingHours,
    required this.createdAt,
  });

  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Equipment(
      id: doc.id,
      name: data['name'] ?? 'Unnamed',
      driver: data['driver'] ?? 'Unknown Driver',
      model: data['model'] ?? 'Unknown Model',
      imageUrl: data['image_url'],
      workingHours: (data['working_hours'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'driver': driver,
      'model': model,
      'image_url': imageUrl,
      'working_hours': workingHours,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
