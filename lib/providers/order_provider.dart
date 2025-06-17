// lib/providers/order_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/order_model.dart'; // OrderModel ve OrderItem'ı buradan import etmeli!
import '../models/sales_record_model.dart'; // <<< YENİ: SalesRecord modelini import etmeli!

class OrderProvider with ChangeNotifier {
  List<OrderItem> _selectedItems = []; // Masadaki tüm sipariş öğeleri
  List<OrderItem> _selectedItemsForPayment = []; // Ödeme için seçilen öğeler
  List<OrderItem> _selectedItemsForTransfer = []; // Taşıma için seçilen öğeler
  
  double _totalPrice = 0.0; // Tüm masanın toplamı
  double _totalPaidAmount = 0.0; // Masada ödenen toplam tutar
  bool _isLoading = false;
  String? _message;
  String? _currentOrderId;
  OrderModel? _currentOrderModel; // Masanın mevcut aktif siparişinin modeli

  List<OrderItem> get selectedItems => _selectedItems;
  List<OrderItem> get selectedItemsForPayment => _selectedItemsForPayment;
  List<OrderItem> get selectedItemsForTransfer => _selectedItemsForTransfer;
  
  double get totalPrice => _totalPrice;
  double get totalPaidAmount => _totalPaidAmount;
  double get totalRemainingAmount => _totalPrice - _totalPaidAmount;
  bool get isLoading => _isLoading;
  String? get message => _message;
  String? get currentOrderId => _currentOrderId;
  OrderModel? get currentOrderModel => _currentOrderModel;

  OrderProvider() {
    _calculateTotals(shouldNotify: false); // Constructor'da initial calculation, notify yapma
  }

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) { // Listener olup olmadığını kontrol et
        notifyListeners();
      }
    });
  }

  // _calculateTotals metodunun notifyListeners'ı conditional hale getirildi
  void _calculateTotals({bool shouldNotify = true}) {
    _totalPrice = _selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    _totalPaidAmount = _selectedItems.where((item) => item.status == 'completed').fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    if (shouldNotify) {
      _safeNotifyListeners();
    }
  }

  // Ödeme için ürün seçimi
  bool isItemSelectedForPayment(OrderItem item) {
    return _selectedItemsForPayment.any((selected) => selected.uniqueId == item.uniqueId);
  }

  // Ödeme için ürün seçimini aç/kapa
  void toggleItemSelectionForPayment(OrderItem item) {
    if (item.status == 'completed') return;

    if (isItemSelectedForPayment(item)) {
      _selectedItemsForPayment.removeWhere((selected) => selected.uniqueId == item.uniqueId);
    } else {
      _selectedItemsForPayment.add(item);
    }
    _safeNotifyListeners();
  }

  // Taşıma için ürün seçimi
  bool isItemSelectedForTransfer(OrderItem item) {
    return _selectedItemsForTransfer.any((selected) => selected.uniqueId == item.uniqueId);
  }

  // Taşıma için ürün seçimini aç/kapa
  void toggleItemSelectionForTransfer(OrderItem item) {
    if (item.status == 'completed' || item.status == 'ready') {
      _message = "Ödenmiş veya mutfakta hazırlanmış ürünler taşınamaz.";
      _safeNotifyListeners();
      return;
    }

    if (isItemSelectedForTransfer(item)) {
      _selectedItemsForTransfer.removeWhere((selected) => selected.uniqueId == item.uniqueId);
    } else {
      _selectedItemsForTransfer.add(item);
    }
    _safeNotifyListeners();
  }

  // Ödeme için seçilen öğeleri döndürür
  List<OrderItem> getSelectedItemsForPayment() {
    return _selectedItemsForPayment.where((item) => item.status != 'completed').toList();
  }

  // Belirli bir öğe listesinin toplam fiyatını hesaplar (ödeme dialogu için kullanılabilir)
  double calculateTotalPrice(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // addProduct artık her zaman yeni bir OrderItem ekler (uniqueId ile)
  void addProduct(OrderItem item) {
    _selectedItems.add(item);
    _calculateTotals();
  }

  void increaseQty(OrderItem item) {
    final index = _selectedItems.indexWhere((element) => element.uniqueId == item.uniqueId);
    if (index != -1 && item.status != 'completed') {
      _selectedItems[index] = OrderItem(
        uniqueId: item.uniqueId,
        productId: item.productId,
        name: item.name,
        price: item.price,
        quantity: item.quantity + 1,
        status: item.status,
        note: item.note,
      );
      _calculateTotals();
    } else if (item.status == 'completed') {
      _message = "Bu ürün zaten ödendi, miktarı değiştirilemez.";
    }
    _safeNotifyListeners();
  }

  void decreaseQty(OrderItem item) {
    final index = _selectedItems.indexWhere((element) => element.uniqueId == item.uniqueId);
    if (index != -1 && item.status != 'completed') {
      if (item.quantity > 1) {
        _selectedItems[index] = OrderItem(
          uniqueId: item.uniqueId,
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity - 1,
          status: item.status,
          note: item.note,
        );
      } else {
        _selectedItems.removeAt(index);
        _selectedItemsForPayment.removeWhere((element) => element.uniqueId == item.uniqueId);
        _selectedItemsForTransfer.removeWhere((element) => element.uniqueId == item.uniqueId);
      }
      _calculateTotals();
    } else if (item.status == 'completed') {
      _message = "Bu ürün zaten ödendi, miktarı değiştirilemez veya silinemez.";
    }
    _safeNotifyListeners();
  }

  void removeItem(OrderItem item) {
    if (item.status == 'completed') {
      _message = "Bu ürün zaten ödendi, silinemez.";
      _safeNotifyListeners();
      return;
    }
    _selectedItems.removeWhere((element) => element.uniqueId == item.uniqueId);
    _selectedItemsForPayment.removeWhere((element) => element.uniqueId == item.uniqueId);
    _selectedItemsForTransfer.removeWhere((element) => element.uniqueId == item.uniqueId);
    _calculateTotals();
    _safeNotifyListeners();
  }

  // NEW: OrderItem'ın notunu güncelleyen metot
  void updateItemNote(OrderItem itemToUpdate, String? newNote) {
    final index = _selectedItems.indexWhere((element) => element.uniqueId == itemToUpdate.uniqueId);
    if (index != -1) {
      _selectedItems[index] = OrderItem(
        uniqueId: itemToUpdate.uniqueId,
        productId: itemToUpdate.productId,
        name: itemToUpdate.name,
        price: itemToUpdate.price,
        quantity: itemToUpdate.quantity,
        status: itemToUpdate.status,
        note: newNote,
      );
      _safeNotifyListeners();
    }
  }

  // Mevcut siparişi masa için getir
  Future<void> fetchOrderForTable({required String tableId, required String companyId}) async {
    _isLoading = true;
    _message = null;
    _selectedItems.clear();
    _selectedItemsForPayment.clear();
    _selectedItemsForTransfer.clear();
    _safeNotifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('tableId', isEqualTo: tableId)
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final order = OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        _selectedItems = List<OrderItem>.from(order.items);
        _currentOrderId = order.id;
        _currentOrderModel = order;
        _message = "Bu masa için mevcut sipariş yüklendi.";
      } else {
        _selectedItems = [];
        _currentOrderId = null;
        _currentOrderModel = null;
        _message = "Bu masa için aktif sipariş bulunamadı. Yeni bir sipariş başlatılıyor.";
      }
      _calculateTotals();
    } catch (e) {
      _message = "Masa siparişi yüklenirken hata oluştu: $e";
      print(_message);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Sipariş gönderme veya güncelleme
  Future<void> submitOrder({
    required String tableId,
    required String tableName,
    required String companyId,
    required String staffId,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_selectedItems.isEmpty) {
      onError("Lütfen sipariş göndermek için ürün seçin.");
      return;
    }

    _isLoading = true;
    _message = null;
    _safeNotifyListeners();

    try {
      final orderData = {
        'tableId': tableId,
        'tableName': tableName,
        'items': _selectedItems.map((item) => item.toMap()).toList(),
        'companyId': companyId,
        'createdAt': _currentOrderModel?.createdAt != null ? _currentOrderModel!.createdAt : FieldValue.serverTimestamp(),
        'status': _currentOrderModel?.status ?? 'pending',
        'totalAmount': _totalPrice,
        'staffId': staffId,
        'isReadyForService': _currentOrderModel?.isReadyForService ?? false,
      };

      if (_currentOrderId != null) {
        await FirebaseFirestore.instance.collection('orders').doc(_currentOrderId).update(orderData);
        _message = "Sipariş başarıyla güncellendi!";
      } else {
        final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);
        _currentOrderId = docRef.id;
        _message = "Yeni sipariş başarıyla oluşturuldu!";
      }

      onSuccess();
    } catch (e) {
      _message = "Sipariş gönderilirken hata oluştu: $e";
      onError(_message!);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Ödeme işlemi
  Future<void> processPayment(String paymentMethod, List<OrderItem> itemsToPay) async {
    if (_currentOrderId == null) {
      _message = "Hata: Ödeme yapılacak aktif sipariş bulunamadı.";
      _safeNotifyListeners();
      return;
    }
    if (itemsToPay.isEmpty) {
      _message = "Hata: Lütfen ödenecek ürünleri seçin.";
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _message = null;
    _safeNotifyListeners();

    try {
      final orderDocRef = FirebaseFirestore.instance.collection('orders').doc(_currentOrderId);
      final orderDoc = await orderDocRef.get();
      if (!orderDoc.exists) {
        _message = "Hata: Sipariş bulunamadı.";
        _safeNotifyListeners();
        return;
      }

      List<OrderItem> updatedItems = List<OrderItem>.from(_selectedItems);
      double paidAmountForThisTransaction = 0.0;

      for (var itemToPay in itemsToPay) {
        final index = updatedItems.indexWhere((element) => element.uniqueId == itemToPay.uniqueId);
        if (index != -1 && updatedItems[index].status != 'completed') {
          updatedItems[index] = OrderItem(
            uniqueId: updatedItems[index].uniqueId,
            productId: updatedItems[index].productId,
            name: updatedItems[index].name,
            price: updatedItems[index].price,
            quantity: updatedItems[index].quantity,
            status: 'completed',
            note: updatedItems[index].note,
          );
          paidAmountForThisTransaction += (itemToPay.price * itemToPay.quantity);
        }
      }

      bool allItemsCompletedInOrder = updatedItems.every((item) => item.status == 'completed');

      // Siparişi Firestore'da güncelle
      await orderDocRef.update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
        'paymentMethod': paymentMethod,
        'paymentDate': FieldValue.serverTimestamp(),
        'status': allItemsCompletedInOrder ? 'completed' : 'pending',
        'totalAmount': calculateTotalPrice(_selectedItems),
      });

      // Eğer tüm ürünler ödendiyse, sales_records'a kaydet
      if (allItemsCompletedInOrder && _currentOrderModel != null) {
        await FirebaseFirestore.instance.collection('sales_records').add(SalesRecord(
          id: '', // Firestore tarafından atanacak
          orderId: _currentOrderId!,
          companyId: _currentOrderModel!.companyId,
          staffId: _currentOrderModel!.staffId ?? 'unknown',
          tableId: _currentOrderModel!.tableId,
          tableName: _currentOrderModel!.tableName,
          totalAmount: _totalPrice,
          paymentMethod: paymentMethod,
          transactionDate: FieldValue.serverTimestamp() as Timestamp, // Timestamp FieldValue'dan cast
          itemsSummary: updatedItems.map((item) => {
            'productId': item.productId,
            'name': item.name,
            'quantity': item.quantity,
            'price': item.price,
          }).toList(),
        ).toMap());
      }


      _selectedItems = updatedItems;
      _selectedItemsForPayment.clear();
      _calculateTotals(); // Total hesaplar ve notify eder

      _message = "Ödeme başarıyla tamamlandı: ${paidAmountForThisTransaction.toStringAsFixed(2)} ₺";
    } catch (e) {
      _message = "Ödeme işlemi sırasında hata oluştu: $e";
      print(_message);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // NEW: Masa taşıma işlemi
  Future<void> transferItemsToTable({
    required String sourceTableId,
    required String targetTableId,
    required String companyId,
    required String staffId,
    required List<OrderItem> itemsToTransfer,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (itemsToTransfer.isEmpty) {
      onError("Lütfen taşınacak ürünleri seçin.");
      return;
    }
    if (sourceTableId == targetTableId) {
      onError("Ürünler aynı masaya taşınamaz.");
      return;
    }

    _isLoading = true;
    _message = null;
    _safeNotifyListeners();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      // Phase 1: Update Source Order (Remove transferred items)
      DocumentReference sourceOrderRef = FirebaseFirestore.instance.collection('orders').doc(_currentOrderId);
      List<OrderItem> remainingItems = List<OrderItem>.from(_selectedItems);
      remainingItems.removeWhere((item) => itemsToTransfer.any((tItem) => tItem.uniqueId == item.uniqueId));

      if (remainingItems.isEmpty) {
        batch.update(sourceOrderRef, {
          'items': [],
          'status': 'transferred_out',
          'totalAmount': 0.0,
          'transferredAt': FieldValue.serverTimestamp(),
          'transferredToTable': targetTableId,
        });
      } else {
        batch.update(sourceOrderRef, {
          'items': remainingItems.map((item) => item.toMap()).toList(),
          'totalAmount': calculateTotalPrice(remainingItems),
        });
      }

      // Phase 2: Update/Create Target Order
      QuerySnapshot targetOrderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('tableId', isEqualTo: targetTableId)
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (targetOrderSnapshot.docs.isNotEmpty) {
        DocumentReference targetOrderRef = targetOrderSnapshot.docs.first.reference;
        OrderModel targetOrder = OrderModel.fromMap(targetOrderSnapshot.docs.first.id, targetOrderSnapshot.docs.first.data() as Map<String, dynamic>);
        
        List<OrderItem> updatedTargetItems = List<OrderItem>.from(targetOrder.items);
        updatedTargetItems.addAll(itemsToTransfer); 

        batch.update(targetOrderRef, {
          'items': updatedTargetItems.map((item) => item.toMap()).toList(),
          'totalAmount': calculateTotalPrice(updatedTargetItems),
          'lastModifiedAt': FieldValue.serverTimestamp(),
        });
      } else {
        DocumentReference newOrderRef = FirebaseFirestore.instance.collection('orders').doc();
        
        final newOrderData = {
          'tableId': targetTableId,
          'tableName': (await FirebaseFirestore.instance.collection('tables').doc(targetTableId).get()).data()?['name'] ?? 'Bilinmeyen Masa',
          'items': itemsToTransfer.map((item) => item.toMap()).toList(),
          'companyId': companyId,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'totalAmount': calculateTotalPrice(itemsToTransfer),
          'staffId': staffId,
          'isReadyForService': false,
        };
        batch.set(newOrderRef, newOrderData);
      }

      await batch.commit();

      _message = "Ürünler başarıyla masaya taşındı!";
      onSuccess();
      clearOrder();

    } catch (e) {
      _message = "Masa taşıma işlemi sırasında hata oluştu: $e";
      onError(_message!);
      print("Masa taşıma hatası: $e");
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void clearOrder({bool shouldNotify = true}) {
    _selectedItems.clear();
    _selectedItemsForPayment.clear();
    _selectedItemsForTransfer.clear();
    _totalPrice = 0.0;
    _totalPaidAmount = 0.0;
    _currentOrderId = null;
    _message = null;
    _isLoading = false;
    _currentOrderModel = null;
    if (shouldNotify) {
      _safeNotifyListeners();
    }
  }
}
