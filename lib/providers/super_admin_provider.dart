import 'package:flutter/material.dart';
import '../models/company_model.dart';
import '../services/firestore_service.dart';

class SuperAdminProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Durum (State) Değişkenleri
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _resultMessage;

  // UI'ın erişeceği getter'lar
  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get resultMessage => _resultMessage;

  SuperAdminProvider() {
    fetchCompanies(); // Provider oluşturulunca şirketleri otomatik çek
  }

  // Şirket listesini getiren metot
  Future<void> fetchCompanies() async {
    _setLoading(true);
    try {
      _companies = await _firestoreService.getCompanies();
      _setResultMessage(null); // Başarılı olunca eski hatayı temizle
    } catch (e) {
      _setResultMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Yeni şirket oluşturan metot
  Future<void> createCompany({
    required String companyName,
    required String adminPhone,
    required String adminPassword,
    required DateTime validUntil,
  }) async {
    _setLoading(true);
    try {
      await _firestoreService.createCompanyWithAdmin(
        companyName: companyName,
        adminPhone: adminPhone,
        adminPassword: adminPassword,
        validUntil: validUntil,
      );
      _setResultMessage("Firma ve admin başarıyla oluşturuldu.");
      await fetchCompanies(); // Listeyi yenile
    } catch (e) {
      _setResultMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Durum yönetimi için yardımcı metotlar
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setResultMessage(String? message) {
    _resultMessage = message;
  }
}