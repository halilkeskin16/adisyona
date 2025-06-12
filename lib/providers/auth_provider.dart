import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;

  AppUser? get user => _user;

  bool get isLoggedIn => _user != null;

  /// Telefon + şifre giriş
  Future<void> login(String phone, String password) async {
    _user = await _authService.login(phone: phone, password: password);
    notifyListeners();
  }

  /// Telefon + şifre ile kayıt
  Future<void> register(String phone, String password, String role, String companyId) async {
    _user = await _authService.register(
      phone: phone,
      password: password,
      role: role,
      companyId: companyId,
    );
    notifyListeners();
  }

  /// Süper admin e-posta + şifre ile giriş
  Future<void> loginWithEmail(String email, String password) async {
    _user = await _authService.loginWithEmail(
      email: email,
      password: password,
    );
    notifyListeners();
  }

  /// Firma geçerlilik süresi kontrolü (abonelik bitmiş mi?)
  Future<bool> isCompanyValid(String companyId) async {
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    if (!doc.exists) return false;

    final validUntil = doc.data()?['validUntil']?.toDate();
    if (validUntil == null) return false;

    return DateTime.now().isBefore(validUntil);
  }

  /// Çıkış
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
