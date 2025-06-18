
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import '../models/user_model.dart';

class StaffProvider with ChangeNotifier {
  final AuthProvider _authProvider; // AuthProvider'a erişim için

  StaffProvider(this._authProvider);

  bool _isLoading = false;
  String? _resultMessage;
  List<AppUser> _staffList = [];
  bool get isLoading => _isLoading;
  String? get resultMessage => _resultMessage;
  List<AppUser> get staffList => _staffList;

  Future<void> fetchStaff() async {
    _isLoading = true;
    _resultMessage = null;
    notifyListeners();

    final currentUser = _authProvider.user;
    if (currentUser?.companyId == null) {
      _resultMessage = "Hata: Şirket bilgisi bulunamadı.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: currentUser!.companyId)
          .where('role', isEqualTo: 'garson')
          .get();

      _staffList = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _resultMessage = "Hata: Personel listesi yüklenemedi: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni personel ekleme metodu
  Future<void> addStaff({
    required String name,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _resultMessage = null;
    notifyListeners();

    // Temel doğrulamalar
    if (phone.isEmpty || password.isEmpty) {
      _resultMessage = "Hata: Telefon numarası ve şifre boş bırakılamaz.";
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (password.length < 6) {
      _resultMessage = "Hata: Şifre en az 6 karakter olmalıdır.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    final currentUser = _authProvider.user;
    if (currentUser?.companyId == null) {
      _resultMessage = "Hata: Şirket bilginiz bulunamadığı için personel eklenemedi.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // AuthProvider'daki YENİ metodu kullanıyoruz
      await _authProvider.createStaffUser(
        phone: phone,
        password: password,
        role: 'garson',
        companyId: currentUser!.companyId!,
      );
      
      _resultMessage = "Başarılı: Personel başarıyla eklendi.";
      await fetchStaff();

    } catch (e) {
      // Firebase'den gelen yaygın hataları daha anlaşılır hale getirelim
      if (e.toString().contains('email-already-in-use') || e.toString().contains('phone-number-already-exists')) {
        _resultMessage = "Hata: Bu telefon numarası zaten kayıtlı.";
      } else {
        _resultMessage = "Hata: Personel eklenirken bir sorun oluştu.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UI'daki mesajı temizlemek için yardımcı metod
  void clearMessage() {
    _resultMessage = null;
    notifyListeners();
  }
}