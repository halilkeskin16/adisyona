import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _adminPhoneController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  DateTime? _validUntil;
  bool _isLoading = false;
  String? _result;

  Future<void> _createCompanyWithAdmin() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final companyName = _firmNameController.text.trim();
      final adminPhone = _adminPhoneController.text.trim();
      final adminPassword = _adminPasswordController.text.trim();

      final companyRef = await FirebaseFirestore.instance.collection('companies').add({
        'name': companyName,
        'createdAt': FieldValue.serverTimestamp(),
        'validUntil': _validUntil,
      });

      final companyId = companyRef.id;

      final authService = AuthService();
      await authService.register(
        phone: adminPhone,
        password: adminPassword,
        role: 'admin',
        companyId: companyId,
      );

      setState(() {
        _result = "Firma ve admin başarıyla oluşturuldu.";
        _firmNameController.clear();
        _adminPhoneController.clear();
        _adminPasswordController.clear();
        _validUntil = null;
      });
    } catch (e) {
      setState(() {
        _result = "Hata oluştu: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _validUntil = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Süper Admin Paneli")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Yeni Firma Ekle", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextField(
                controller: _firmNameController,
                decoration: const InputDecoration(labelText: "Firma Adı", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adminPhoneController,
                decoration: const InputDecoration(labelText: "Admin Telefon Numarası", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adminPasswordController,
                decoration: const InputDecoration(labelText: "Admin Şifresi", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickDate,
                child: Text(_validUntil == null
                    ? "Geçerlilik Tarihi Seç"
                    : "Son Tarih: ${_validUntil!.toLocal()}".split(' ')[0]),
              ),
              const SizedBox(height: 24),
              if (_result != null)
                Text(
                  _result!,
                  style: TextStyle(color: _result!.startsWith("Hata") ? Colors.red : Colors.green),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCompanyWithAdmin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Firmayı Kaydet"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
