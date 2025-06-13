import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String tableId;
  final String tableName;
  final List<OrderItem> items;
  final String companyId;
  final DateTime createdAt;
  final String status; // örnek: pending, preparing, served

  OrderModel({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.items,
    required this.companyId,
    required this.createdAt,
    required this.status,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    return OrderModel(
      id: id,
      tableId: data['tableId'],
      tableName: data['tableName'],
      companyId: data['companyId'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>).map((item) => OrderItem.fromMap(item)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableName': tableName,
      'companyId': companyId,
      'createdAt': createdAt,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }
}
