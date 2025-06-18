// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class OrderModel {
  final String id;
  final String tableId;
  final String tableName;
  final List<OrderItem> items;
  final String companyId;
  final Timestamp? createdAt;
  final String status; // örnek: pending, preparing, served
  final double totalAmount;
  final String? paymentMethod;
  final Timestamp? paymentDate;
  final Timestamp? kitchenCompletedAt;
  final String? staffId;
  final bool? isReadyForService; // <<< YENİ EKLENDİ: Mutfakta servise hazır mı?

  OrderModel({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.items,
    required this.companyId,
    this.createdAt,
    required this.status,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentDate,
    this.kitchenCompletedAt,
    this.staffId,
    this.isReadyForService, // <<< CONSTRUCTOR'A EKLENDİ
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      tableId: map['tableId'] as String? ?? '',
      tableName: map['tableName'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      companyId: map['companyId'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      status: map['status'] as String? ?? 'pending',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String?,
      paymentDate: map['paymentDate'] as Timestamp?,
      kitchenCompletedAt: map['kitchenCompletedAt'] as Timestamp?,
      staffId: map['staffId'] as String?,
      isReadyForService: map['isReadyForService'] as bool?, // <<< fromMap'TEN OKUNDU
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableName': tableName,
      'items': items.map((item) => item.toMap()).toList(),
      'companyId': companyId,
      'createdAt': createdAt,
      'status': status,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'kitchenCompletedAt': kitchenCompletedAt,
      'staffId': staffId,
      'isReadyForService': isReadyForService, // <<< toMap'E EKLENDİ
    };
  }
}

class OrderItem {
  final String uniqueId;
  final String productId;
  final String name;
  final double price;
  int quantity;
  String? status;
  String? note;

  OrderItem({
    String? uniqueId,
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.status,
    this.note,
  }) : uniqueId = uniqueId ?? const Uuid().v4();

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      uniqueId: map['uniqueId'] as String? ?? const Uuid().v4(),
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uniqueId': uniqueId,
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
      'note': note,
    };
  }
}
