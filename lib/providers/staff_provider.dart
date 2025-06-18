import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart'; // YENİ SERVİSİ IMPORT EDİN

class StaffProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  final FirestoreService _firestoreService = FirestoreService();

  StaffProvider(this._authProvider) {
    fetchStaff();
  }

  bool _isLoading = false;
  String? _resultMessage;
  List<AppUser> _staffList = [];

  // Getter'lar aynı kalıyor
  bool get isLoading => _isLoading;
  String? get resultMessage => _resultMessage;
  List<AppUser> get staffList => _staffList;

  Future<void> fetchStaff() async {
    _setLoading(true);
    final currentUser = _authProvider.user;
    if (currentUser?.companyId == null) {
      _setResultMessage("Hata: Şirket bilgisi bulunamadı.");
      _setLoading(false);
      return;
    }

    try {
      _staffList = await _firestoreService.getStaffForCompany(currentUser!.companyId!);
      _setResultMessage(null);
    } catch (e) {
      _setResultMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addStaff({
    required String name,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);

    if (phone.isEmpty || password.isEmpty || password.length < 6) {
      _setResultMessage("Hata: Girdiğiniz bilgileri kontrol edin (şifre en az 6 karakter).");
      _setLoading(false);
      return;
    }

    final currentUser = _authProvider.user;
    if (currentUser?.companyId == null) {
      _setResultMessage("Hata: Şirket bilginiz bulunamadı.");
      _setLoading(false);
      return;
    }

    try {
      await _authProvider.createStaffUser(
        phone: phone,
        password: password,
        role: 'garson',
        companyId: currentUser!.companyId!,
      );
      
      _setResultMessage("Başarılı: Personel başarıyla eklendi.");
      await fetchStaff();

    } catch (e) {
      if (e.toString().contains('phone-number-already-exists')) {
        _setResultMessage("Hata: Bu telefon numarası zaten kayıtlı.");
      } else {
        _setResultMessage("Hata: Personel eklenirken bir sorun oluştu.");
      }
    } finally {
      _setLoading(false);
    }
  }
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setResultMessage(String? message) {
    _resultMessage = message;
  }

  void clearMessage() {
    _resultMessage = null;
    notifyListeners();
  }
}