import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final DateTime? validUntil;

  Company({
    required this.id,
    required this.name,
    this.validUntil,
  });

  factory Company.fromMap(String id, Map<String, dynamic> data) {
    return Company(
      id: id,
      name: data['name'],
      validUntil: data['validUntil'] != null ? (data['validUntil'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'validUntil': validUntil,
    };
  }
}
