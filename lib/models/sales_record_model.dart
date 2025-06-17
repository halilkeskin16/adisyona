// lib/models/sales_record_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesRecord {
  final String id; 
  final String orderId;
  final String companyId;
  final String staffId; 
  final String tableId;
  final String tableName;
  final double totalAmount; 
  final String paymentMethod;
  final Timestamp transactionDate; 
  final List<Map<String, dynamic>> itemsSummary;

  SalesRecord({
    required this.id,
    required this.orderId,
    required this.companyId,
    required this.staffId,
    required this.tableId,
    required this.tableName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.transactionDate,
    required this.itemsSummary,
  });

  factory SalesRecord.fromMap(String id, Map<String, dynamic> map) {
    return SalesRecord(
      id: id,
      orderId: map['orderId'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      tableName: map['tableName'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'unknown',
      transactionDate: map['transactionDate'] as Timestamp? ?? Timestamp.now(),
      itemsSummary: (map['itemsSummary'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'companyId': companyId,
      'staffId': staffId,
      'tableId': tableId,
      'tableName': tableName,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'transactionDate': transactionDate,
      'itemsSummary': itemsSummary,
    };
  }
}