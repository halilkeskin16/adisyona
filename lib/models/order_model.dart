// lib/models/order_model.dart dosyanız
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      tableId: map['tableId'] ?? '',
      tableName: map['tableName'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      companyId: map['companyId'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      status: map['status'] ?? 'pending',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String?,
      paymentDate: map['paymentDate'] as Timestamp?,
      kitchenCompletedAt: map['kitchenCompletedAt'] as Timestamp?,
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
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String status;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.status,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
    };
  }
}