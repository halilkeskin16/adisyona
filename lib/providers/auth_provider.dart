// providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Model yolunuzu doğrulayın
import '../services/auth_service.dart'; // Servis yolunuzu doğrulayın

// Giriş işleminin sonucunu temsil eden enum
enum AuthResult {
  success,
  successSuperAdmin,
  subscriptionExpired,
  userNotFound,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Public getter'lar
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Durum yönetimi için özel setter'lar
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

   Future<void> createStaffUser({
    required String phone,
    required String password,
    required String role,
    required String companyId,
  }) async {
    await _authService.register(
      phone: phone,
      password: password,
      role: role,
      companyId: companyId,
    );
  }
  Future<void> register(String phone, String password, String role, String companyId) async {
    await _authService.register(phone: phone, password: password, role: role, companyId: companyId);
  }
  Future<AuthResult> signIn(String identifier, String password) async {
    _setLoading(true);
    _setError(null); // Her yeni denemede eski hatayı temizle

    try {
      // Girdinin e-posta mı yoksa telefon mu olduğunu kontrol et
      if (identifier.contains('@')) {
        _user = await _authService.loginWithEmail(email: identifier, password: password);
      } else {
        _user = await _authService.login(phone: identifier, password: password);
      }

      // Kullanıcı bulunamadıysa veya şifre yanlışsa
      if (_user == null) {
        _setError("Kullanıcı bulunamadı veya bilgileriniz hatalı.");
        _setLoading(false);
        return AuthResult.userNotFound;
      }

      // Rol bazlı kontrol ve yönlendirme
      if (_user!.role == "super_admin") {
        _setLoading(false);
        return AuthResult.successSuperAdmin;
      }

      if (_user!.role == "admin" || _user!.role == "garson") {
        if (_user!.companyId == null || _user!.companyId!.isEmpty) {
          _setError("Kullanıcıya atanmış bir şirket bulunamadı.");
           _setLoading(false);
          return AuthResult.error;
        }

        // Firma abonelik kontrolünü burada yap
        final bool isCompanyValid = await _isCompanyValid(_user!.companyId!);
        if (!isCompanyValid) {
          // Kullanıcıyı null yapabiliriz ki uygulama içinde yetkisiz işlem yapamasın
          // _user = null; 
          _setError("Şirket aboneliğinizin süresi dolmuş.");
          _setLoading(false);
          return AuthResult.subscriptionExpired;
        }

        _setLoading(false);
        return AuthResult.success;
      }
      
      // Beklenmedik bir rol varsa
      _setError("Yetkisiz kullanıcı rolü. Lütfen yöneticinizle görüşün.");
      _user = null; // Yetkisiz kullanıcıyı sistemde tutma
      _setLoading(false);
      return AuthResult.error;

    } catch (e) {
      _user = null;
      _setError("Giriş sırasında bir hata oluştu: ${e.toString()}");
      _setLoading(false);
      return AuthResult.error;
    }
  }

  /// Firma geçerlilik süresi kontrolü (abonelik bitmiş mi?)
  /// Bu metodu private yaparak sadece Provider içinde kullanılmasını sağladım.
  Future<bool> _isCompanyValid(String companyId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null || !data.containsKey('validUntil')) return false;

      final validUntilTimestamp = data['validUntil'] as Timestamp?;
      if (validUntilTimestamp == null) return false;
      
      final validUntil = validUntilTimestamp.toDate();
      return DateTime.now().isBefore(validUntil);

    } catch (e) {
      // Hata durumunda güvenli tarafta kalıp geçersiz sayalım.
      print("Firma geçerlilik kontrolü hatası: $e");
      return false;
    }
  }

  /// Çıkış
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // Sadece UI'daki hata mesajını temizlemek için bir yardımcı metod.
  void clearError() {
      _errorMessage = null;
      notifyListeners();
  }
}