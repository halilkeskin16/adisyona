// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order_model.dart'; // OrderModel ve OrderItem'ı buradan import etmeli!

class OrderProvider with ChangeNotifier {
  List<OrderItem> _selectedItems = [];
  List<OrderItem> _itemsSelectedForPayment = []; // Ödeme için seçilen ürünler
  double _totalPrice = 0.0;
  bool _isLoading = false;
  String? _message;
  String? _currentOrderId;
  List<OrderModel> _orders = []; // Siparişleri tutacak liste
  StreamSubscription<QuerySnapshot>? _orderSubscription; // Sipariş dinleyicisi

  // Seçili ürünler için ödeme
  final Set<OrderItem> _selectedItemsForPayment = {};

  List<OrderItem> get selectedItems => _selectedItems;
  double get totalPrice => _totalPrice;
  bool get isLoading => _isLoading;
  String? get message => _message;
  String? get currentOrderId => _currentOrderId;

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  OrderProvider() {
    _calculateTotalPrice();
  }

  void _calculateTotalPrice() {
    _totalPrice = _selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    notifyListeners();
  }

  // Ödeme için ürün seçme metodları
  bool isItemSelectedForPayment(OrderItem item) {
    return _selectedItemsForPayment.any((selected) =>
        selected.productId == item.productId &&
        selected.quantity == item.quantity);
  }

  void toggleItemSelectionForPayment(OrderItem item) {
    if (isItemSelectedForPayment(item)) {
      _selectedItemsForPayment.removeWhere((selected) =>
          selected.productId == item.productId &&
          selected.quantity == item.quantity);
    } else {
      _selectedItemsForPayment.add(item);
    }
    notifyListeners();
  }

  List<OrderItem> getSelectedItemsForPayment() {
    return _selectedItemsForPayment.toList();
  }

  void clearSelectedItemsForPayment() {
    _selectedItemsForPayment.clear();
    notifyListeners();
  }

  double calculateTotalPrice(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Mevcut siparişi getir
  OrderModel? get currentOrder {
    if (_currentOrderId == null) return null;
    return _orders.firstWhere(
      (order) => order.id == _currentOrderId,
      orElse: () => throw Exception('Sipariş bulunamadı'),
    );
  }

  void addProduct(OrderItem item) {
    final existingIndex = _selectedItems.indexWhere((element) => element.productId == item.productId);
    if (existingIndex != -1) {
      // Mevcut öğeyi güncellemek için yeni bir OrderItem oluştur.
      // Çünkü OrderItem'ın quantity'si mutable olsa da, listeyi yeniden atamak daha güvenlidir.
      final currentItem = _selectedItems[existingIndex];
      _selectedItems[existingIndex] = OrderItem(
        productId: currentItem.productId,
        name: currentItem.name,
        price: currentItem.price,
        quantity: currentItem.quantity + 1,
        status: currentItem.status,
      );
    } else {
      _selectedItems.add(item);
    }
    _calculateTotalPrice();
  }

  void increaseQty(OrderItem item) {
    final index = _selectedItems.indexOf(item);
    if (index != -1) {
      final currentItem = _selectedItems[index];
      _selectedItems[index] = OrderItem(
        productId: currentItem.productId,
        name: currentItem.name,
        price: currentItem.price,
        quantity: currentItem.quantity + 1,
        status: currentItem.status,
      );
      _calculateTotalPrice();
    }
  }

  void decreaseQty(OrderItem item) {
    final index = _selectedItems.indexOf(item);
    if (index != -1) {
      final currentItem = _selectedItems[index];
      if (currentItem.quantity > 1) {
        _selectedItems[index] = OrderItem(
          productId: currentItem.productId,
          name: currentItem.name,
          price: currentItem.price,
          quantity: currentItem.quantity - 1,
          status: currentItem.status,
        );
      } else {
        _selectedItems.removeAt(index);
      }
      _calculateTotalPrice();
    }
  }

  void removeItem(OrderItem item) {
    _selectedItems.removeWhere((element) => element.productId == item.productId);
    _calculateTotalPrice();
  }

  Future<void> fetchOrderForTable({required String tableId, required String companyId}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      // Önceki dinleyiciyi iptal et
      await _orderSubscription?.cancel();

      // Yeni dinleyici oluştur
      _orderSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('tableId', isEqualTo: tableId)
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: ['pending', 'preparing', 'ready'])
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final order = OrderModel.fromMap(doc.id, doc.data());
          _selectedItems = List<OrderItem>.from(order.items);
          _currentOrderId = order.id;
          _orders = [order];
          _calculateTotalPrice();
          notifyListeners();
        } else {
          _selectedItems = [];
          _currentOrderId = null;
          _orders = [];
          _calculateTotalPrice();
          notifyListeners();
        }
      });

      _message = "Order listener started.";
    } catch (e) {
      _message = "Error loading order for table: $e";
      print(_message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> processPayment(String paymentMethod, List<OrderItem> selectedItems) async {
    if (_currentOrderId == null) return;

    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(_currentOrderId).get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data() as Map<String, dynamic>;
      List<OrderItem> currentItems = (orderData['items'] as List)
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList();

      // Seçili ürünleri 'completed' olarak işaretle
      final updatedItems = currentItems.map((item) {
        if (selectedItems.any((selected) => 
            selected.productId == item.productId && 
            selected.quantity == item.quantity)) {
          return OrderItem(
            productId: item.productId,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            status: 'completed',
          );
        }
        return item;
      }).toList();

      // Tüm ürünler tamamlandıysa siparişi de tamamla
      final allItemsCompleted = updatedItems.every((item) => item.status == 'completed');

      // Ödeme işlemini gerçekleştir
      await FirebaseFirestore.instance.collection('orders').doc(_currentOrderId).update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
        if (allItemsCompleted) 'status': 'completed',
        'paymentMethod': paymentMethod,
        'paymentDate': FieldValue.serverTimestamp(),
      });

      // Seçili ürünleri temizle
      clearSelectedItemsForPayment();

      // Siparişi güncelle
      if (allItemsCompleted) {
        _orders.clear();
        _currentOrderId = null;
        _selectedItems.clear();
      } else {
        final updatedOrder = OrderModel.fromMap(_currentOrderId!, {
          ...orderData,
          'items': updatedItems.map((e) => e.toMap()).toList(),
        });
        _orders = [updatedOrder];
        _selectedItems = List<OrderItem>.from(updatedItems);
      }

      _calculateTotalPrice();
      notifyListeners();
    } catch (e) {
      print("Ödeme işlemi sırasında hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> submitOrder({
    required String tableId,
    required String tableName,
    required String companyId,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_selectedItems.isEmpty) {
      onError("Please select products to submit the order.");
      return;
    }

    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final orderData = {
        'tableId': tableId,
        'tableName': tableName,
        'items': _selectedItems.map((item) => item.toMap()).toList(),
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'totalAmount': _totalPrice, // Toplam tutarı ekle
      };

      if (_currentOrderId != null) {
        await FirebaseFirestore.instance.collection('orders').doc(_currentOrderId).update(orderData);
        _message = "Order updated successfully!";
      } else {
        final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);
        _currentOrderId = docRef.id;
        _message = "New order created successfully!";
      }

      onSuccess();
      // clearOrder() çağrısını kaldırdık, böylece sipariş masada kalacak

    } catch (e) {
      _message = "Error submitting order: $e";
      onError(_message!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearOrder() {
    _selectedItems.clear();
    _itemsSelectedForPayment.clear();
    _selectedItemsForPayment.clear();
    _totalPrice = 0.0;
    _currentOrderId = null;
    _orders.clear();
    _message = null;
    _isLoading = false;
    notifyListeners();
  }
}