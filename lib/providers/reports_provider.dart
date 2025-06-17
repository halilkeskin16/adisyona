// lib/providers/reports/reports_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart'; // OrderModel ve OrderItem
// import '../models/user_model.dart'; // AppUser (personel isimleri için) - Zaten çekiliyor
// import 'package:intl/intl.dart'; // Tarih formatlama için - Sadece UI'da kullanılıyor

class ReportsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rapor filtreleri ve durumları
  String _selectedDateFilter = 'daily';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  bool _isLoading = false;
  String? _message; // Hata veya bilgi mesajı

  // Rapor verileri
  double _totalSales = 0.0;
  Map<String, double> _staffSales = {};
  Map<String, String> _staffNames = {}; // user ID -> user name (Firestore'dan çekilecek)
  Map<String, double> _tableSales = {};
  Map<String, double> _productSalesAmount = {};
  Map<String, int> _productSalesQuantity = {};
  Map<String, String> _productNames = {}; // product ID -> product name (Firestore'dan çekilecek)

  // Getters
  String get selectedDateFilter => _selectedDateFilter;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get message => _message;

  double get totalSales => _totalSales;
  Map<String, double> get staffSales => _staffSales;
  Map<String, String> get staffNames => _staffNames;
  Map<String, double> get tableSales => _tableSales;
  Map<String, double> get productSalesAmount => _productSalesAmount;
  Map<String, int> get productSalesQuantity => _productSalesQuantity;
  Map<String, String> get productNames => _productNames;

  // Kurucu metod: Başlangıçta notifyListeners çağırmıyoruz, veri çekme UI'dan tetiklenmeli.
  ReportsProvider();

  // Güvenli notifyListeners çağırma metodu
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Tarih aralığını günceller ve raporları yeniden çeker
  void updateDateRange(String filter, {DateTime? customStart, DateTime? customEnd}) {
    _selectedDateFilter = filter;
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    if (filter == 'daily') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else if (filter == 'weekly') {
      start = now.subtract(Duration(days: now.weekday - 1)); // Haftanın başlangıcı (Pazartesi)
      start = DateTime(start.year, start.month, start.day);
      end = now.add(Duration(days: 7 - now.weekday)); // Haftanın sonu (Pazar)
      end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    } else if (filter == 'monthly') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1)); // Ayın sonu
    } else { // 'custom'
      start = customStart ?? DateTime(now.year, now.month, now.day);
      end = customEnd ?? DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    }

    _startDate = start;
    _endDate = end;
    // Tarih aralığı güncellendiğinde raporları otomatik olarak çek.
    // companyId, ReportsScreen'den fetchReports'a iletilmelidir.
    // Şimdilik burada companyId'yi almıyoruz, fetchReports'a parametre olarak geçeceğiz.
    // this.fetchReports(companyId); // Bu, dışarıdan çağrılacağı için burada kaldırıldı.
    _safeNotifyListeners(); // Tarih aralığı değişti, UI'ı güncelle
  }

  // Kullanıcı isimlerini (personel isimlerini) Firestore'dan çeker
  Future<void> fetchUserNames(String companyId) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();
      
      Map<String, String> names = {};
      for (var doc in userSnapshot.docs) {
        names[doc.id] = doc.data()['name'] ?? doc.data()['phone'] ?? doc.data()['email'] ?? 'Bilinmeyen Personel';
      }
      _staffNames = names;
      _safeNotifyListeners(); // İsimler çekildiğinde UI'ı güncelle
    } catch (e) {
      print("Kullanıcı isimleri çekilirken hata oluştu: $e");
      _message = "Personel isimleri yüklenirken hata oluştu.";
      _safeNotifyListeners();
    }
  }

  // Ürün isimlerini Firestore'dan çeker
  Future<void> fetchProductNames(String companyId) async {
    try {
      final productSnapshot = await _firestore
          .collection('products')
          .where('companyId', isEqualTo: companyId)
          .get();
      
      Map<String, String> names = {};
      for (var doc in productSnapshot.docs) {
        names[doc.id] = doc.data()['name'] ?? 'Bilinmeyen Ürün';
      }
      _productNames = names;
      _safeNotifyListeners(); // Ürün isimleri çekildiğinde UI'ı güncelle
    } catch (e) {
      print("Ürün isimleri çekilirken hata oluştu: $e");
      _message = "Ürün isimleri yüklenirken hata oluştu.";
      _safeNotifyListeners();
    }
  }


  // Rapor verilerini Firestore'dan çeker ve hesaplar
  Future<void> fetchReports(String companyId) async {
    _isLoading = true;
    _message = null; // Mesajı temizle
    _totalSales = 0.0;
    _staffSales = {};
    _tableSales = {};
    _productSalesAmount = {};
    _productSalesQuantity = {};
    _safeNotifyListeners(); // Yüklenme durumunu bildir

    try {
      // ÖNEMLİ: Bu sorgu için Firebase konsolunda birleşik dizin oluşturmanız gerekebilir!
      // companyId (ascending), status (ascending), createdAt (descending)
      final querySnapshot = await _firestore
          .collection('orders')
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'completed') // Sadece tamamlanmış siparişler
          .where('createdAt', isGreaterThanOrEqualTo: _startDate)
          .where('createdAt', isLessThanOrEqualTo: _endDate)
          .orderBy('createdAt', descending: false) // 'descending: false' ile Artan sıralama (Ascending)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _message = "Bu dönem için hiç tamamlanmış sipariş bulunamadı.";
        _safeNotifyListeners();
        return;
      }

      for (var doc in querySnapshot.docs) {
        final order = OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        double orderTotal = order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

        _totalSales += orderTotal;

        // Personel bazında satışlar (OrderModel'de staffId alanı olmalı)
        String staffId = order.staffId ?? 'unknown_staff_id';
        _staffSales.update(staffId, (value) => value + orderTotal, ifAbsent: () => orderTotal);

        // Masa bazında satışlar
        _tableSales.update(order.tableName, (value) => value + orderTotal, ifAbsent: () => orderTotal);

        // Ürün bazında satışlar
        for (var item in order.items) {
          _productSalesAmount.update(item.productId, (value) => value + (item.price * item.quantity), ifAbsent: () => (item.price * item.quantity));
          _productSalesQuantity.update(item.productId, (value) => value + item.quantity, ifAbsent: () => item.quantity);
        }
      }
      _message = null; // Başarılı olursa mesajı temizle
    } catch (e) {
      _message = "Raporlar çekilirken hata oluştu: $e";
      print("Rapor çekme hatası: $e");
    } finally {
      _isLoading = false;
      _safeNotifyListeners(); // Yükleme bittiğini ve mesajı göstermek için notify
    }
  }

  // Provider durumunu temizler
  void clearReports() {
    _selectedDateFilter = 'daily';
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _isLoading = false;
    _message = null;
    _totalSales = 0.0;
    _staffSales = {};
    _tableSales = {};
    _productSalesAmount = {};
    _productSalesQuantity = {};
    // _staffNames ve _productNames temizlenmez, genel veridir
    _safeNotifyListeners();
  }
}
