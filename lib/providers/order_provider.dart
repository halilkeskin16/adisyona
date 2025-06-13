import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<OrderItem> _selectedItems = [];
  bool _isLoading = false;
  String? _message;

  List<OrderItem> get selectedItems => _selectedItems;
  bool get isLoading => _isLoading;
  String? get message => _message;

  double get totalPrice =>
      _selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void addProduct(OrderItem item) {
    final index = _selectedItems.indexWhere((e) => e.productId == item.productId);
    if (index >= 0) {
      _selectedItems[index].quantity++;
    } else {
      _selectedItems.add(item);
    }
    notifyListeners();
  }

  void increaseQty(OrderItem item) {
    final index = _selectedItems.indexOf(item);
    if (index >= 0) {
      _selectedItems[index].quantity++;
      notifyListeners();
    }
  }

  void decreaseQty(OrderItem item) {
    final index = _selectedItems.indexOf(item);
    if (index >= 0) {
      if (_selectedItems[index].quantity > 1) {
        _selectedItems[index].quantity--;
      } else {
        _selectedItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(OrderItem item) {
    _selectedItems.removeWhere((e) => e.productId == item.productId);
    notifyListeners();
  }

  void clearOrder() {
    _selectedItems.clear();
    _message = null;
    notifyListeners();
  }

  Future<void> submitOrder({
    required String tableId,
    required String tableName,
    required String companyId,
    required VoidCallback onSuccess,
    required Function(String error) onError,
  }) async {
    if (_selectedItems.isEmpty) {
      onError("Lütfen ürün seçin.");
      return;
    }

    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final order = {
        'tableId': tableId,
        'tableName': tableName,
        'companyId': companyId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'items': _selectedItems.map((item) => item.toMap()).toList(),
      };

      await FirebaseFirestore.instance.collection('orders').add(order);
      _message = "Sipariş gönderildi!";
      clearOrder();
      onSuccess();
    } catch (e) {
      _message = "Sipariş gönderilirken hata: $e";
      onError(_message!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
