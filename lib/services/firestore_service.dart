import 'package:adisyona/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<List<Company>> getCompanies() async {
    try {
      final snapshot = await _db.collection('companies').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => Company.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Şirketler yüklenemedi: $e');
    }
  }

  Future<void> createCompanyWithAdmin({
    required String companyName,
    required String adminPhone,
    required String adminPassword,
    required DateTime validUntil,
  }) async {
    try {
      final companyRef = await _db.collection('companies').add({
        'name': companyName,
        'createdAt': FieldValue.serverTimestamp(),
        'validUntil': validUntil,
        'isActive': true,
      });

      await _authService.register(
        phone: adminPhone,
        password: adminPassword,
        role: 'admin',
        companyId: companyRef.id,
      );
    } catch (e) {
      throw Exception('Firma ve admin oluşturulurken hata oluştu: $e');
    }
  }

  Future<List<AppUser>> getStaffForCompany(String companyId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'garson')
          .get();
      
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print("Hata - getStaffForCompany: $e");
      throw Exception('Personel listesi yüklenemedi.');
    }
  }
}