import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRecord {
  final String id;
  final String type;
  final int hoursLimit;
  final DateTime lastDate;
  final double lastHours;
  final DateTime createdAt;

  MaintenanceRecord({
    required this.id,
    required this.type,
    required this.hoursLimit,
    required this.lastDate,
    required this.lastHours,
    required this.createdAt,
  });

  factory MaintenanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MaintenanceRecord(
      id: doc.id,
      type: data['type'] ?? 'Unknown Type',
      hoursLimit: (data['hours_limit'] as num?)?.toInt() ?? 0,
      lastDate: (data['last_date'] as Timestamp).toDate(),
      lastHours: (data['last_hours'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'hours_limit': hoursLimit,
      'last_date': Timestamp.fromDate(lastDate),
      'last_hours': lastHours,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
