class AppUser {
  final String uid;
  final String? phone;
  final String? email;
  final String role;
  final String? companyId;

  AppUser({
    required this.uid,
    this.phone,
    this.email,
    required this.role,
    this.companyId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      phone: data['phone'],
      email: data['email'],
      role: data['role'],
      companyId: data['companyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'role': role,
      'companyId': companyId,
    };
  }
}
