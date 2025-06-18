import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    this.validUntil,
    this.createdAt,
    this.isActive = true,
  });

  factory Company.fromMap(String id, Map<String, dynamic> data) {
    return Company(
      id: id,
      name: data['name'] ?? '',
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}