import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Süper admin email + şifre ile giriş
  Future<AppUser?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final snapshot =
        await _firestore.collection('users').doc(credential.user!.uid).get();

    if (!snapshot.exists) return null;

    return AppUser.fromMap(credential.user!.uid, snapshot.data()!);
  }

  /// Firma yöneticisi (admin) kullanıcıyı telefon + şifre ile kaydet
  Future<AppUser> register({
    required String phone,
    required String password,
    required String role,
    required String companyId,
  }) async {
    final fakeEmail = "$phone@example.com";
    final credential = await _auth.createUserWithEmailAndPassword(
      email: fakeEmail,
      password: password,
    );

    final user = AppUser(
      uid: credential.user!.uid,
      phone: phone,
      email: fakeEmail,
      role: role,
      companyId: companyId,
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  /// Firma yöneticisi giriş (telefon + şifre)
  Future<AppUser?> login({
    required String phone,
    required String password,
  }) async {
    final fakeEmail = "$phone@example.com";

    final credential = await _auth.signInWithEmailAndPassword(
      email: fakeEmail,
      password: password,
    );

    final snapshot =
        await _firestore.collection('users').doc(credential.user!.uid).get();

    if (!snapshot.exists) return null;

    return AppUser.fromMap(credential.user!.uid, snapshot.data()!);
  }

  /// Oturumu kapat
  Future<void> logout() async {
    await _auth.signOut();
  }
}
