// lib/models/order_model.dart dosyanız
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
      items: (data['items'] as List<dynamic>).map((item) => OrderItem.fromMap(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableName': tableName,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt), // Firestore'a Timestamp olarak kaydet
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
  String? status; // <<< BURADAKİ FINAL KALDIRILDI VE ALAN EKLENDİ

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.status, // <<< CONSTRUCTOR'A EKLENDİ
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'status': status, // <<< toMap METODUNA EKLENDİ
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String, // String cast eklendi
      name: map['name'] as String, // String cast eklendi
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(), // int cast eklendi
      status: map['status'] as String?, // <<< fromMap METODUNA EKLENDİ
    );
  }
}