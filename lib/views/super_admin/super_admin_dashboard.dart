// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart'; // Bu dosyanın yolunu doğrulayın
import '../../providers/auth_provider.dart'; // Bu dosyanın yolunu doğrulayın
import 'package:intl/intl.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  // TextEditingController'lar ve diğer durum değişkenleri
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _adminPhoneController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  DateTime? _validUntil;
  bool _isLoading = false;
  String? _result;

  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    // Türkçe tarih formatı için intl paketini başlat
    Intl.defaultLocale = 'tr_TR';
    _fetchCompanies();
  }

  @override
  void dispose() {
    _firmNameController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  // Şirketleri Firestore'dan çeken metod
  Future<void> _fetchCompanies() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('companies').get();
      final list = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'validUntil': doc['validUntil']?.toDate(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _companies = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = "Şirketler yüklenirken hata oluştu.";
        });
      }
    }
  }

  // Yeni şirket ve admin oluşturan metod
  Future<void> _createCompanyWithAdmin() async {
    if (_firmNameController.text.trim().isEmpty ||
        _adminPhoneController.text.trim().isEmpty ||
        _adminPasswordController.text.trim().isEmpty ||
        _validUntil == null) {
      setState(() {
        _result = "Lütfen tüm alanları doldurun ve geçerlilik tarihi seçin.";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final companyName = _firmNameController.text.trim();
      final adminPhone = _adminPhoneController.text.trim();
      final adminPassword = _adminPasswordController.text.trim();

      final companyRef =
          await FirebaseFirestore.instance.collection('companies').add({
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

      await _fetchCompanies();
    } catch (e) {
      setState(() {
        _result = "Hata oluştu: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tarih seçiciyi açan metod
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _validUntil = picked;
      });
    }
  }

  // Çıkış onay penceresini gösteren metod
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Çıkış Yap'),
          content:
              const Text('Oturumu sonlandırmak istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Çıkış Yap'),
              onPressed: () async {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (mounted) {
                  // '/login' yolunuzu MaterialApp'ta tanımladığınızdan emin olun
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Gelecek özellikler için placeholder metotlar
  void _deactivateCompany(String companyId, String companyName) {
    // TODO: Firmayı pasife alma mantığı burada olacak.
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$companyName pasife alınacak.")));
  }

  void _deleteCompany(String companyId, String companyName) {
    // TODO: Firmayı silme mantığı burada olacak.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$companyName silinecek.")));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Süper Admin Paneli",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Çıkış Yap",
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yeni Firma Ekle",
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                  controller: _firmNameController,
                  labelText: "Firma Adı",
                  icon: Icons.business),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _adminPhoneController,
                  labelText: "Admin Telefon Numarası",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _adminPasswordController,
                  labelText: "Admin Şifresi",
                  icon: Icons.lock,
                  obscureText: true),
              const SizedBox(height: 16),
              _buildDateSelectionButton(colorScheme),
              const SizedBox(height: 24),
              if (_result != null) _buildResultMessage(colorScheme),
              const SizedBox(height: 12),
              _buildSaveCompanyButton(colorScheme),
              const SizedBox(height: 40),
              Divider(color: colorScheme.onSurface.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 20),
              Text(
                "Kayıtlı Firmalar",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildCompanyList(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon:
            icon != null ? Icon(icon, color: Theme.of(context).colorScheme.primary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      cursorColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDateSelectionButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: _pickDate,
      icon: const Icon(Icons.calendar_today),
      label: Text(
        _validUntil == null
            ? "Geçerlilik Tarihi Seç"
            : "Son Tarih: ${DateFormat('dd MMMM, yyyy').format(_validUntil!)}",
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildResultMessage(ColorScheme colorScheme) {
    bool isError = _result!.startsWith("Hata");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colorScheme.errorContainer : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? colorScheme.onErrorContainer : Colors.green.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _result!,
              style: TextStyle(
                color: isError ? colorScheme.onErrorContainer : Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveCompanyButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _createCompanyWithAdmin,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text(
                "Firmayı ve Admini Oluştur",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCompanyList(ColorScheme colorScheme) {
    if (_companies.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Text(
          "Henüz kayıtlı firma bulunmamaktadır.",
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final company = _companies[index];
        final companyId = company['id'];
        final companyName = company['name'];
        final dateFormatted = company['validUntil'] != null
            ? DateFormat('dd MMMM, yyyy').format(company['validUntil'])
            : 'Tanımsız';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.apartment, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Son Tarih: $dateFormatted",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'deactivate') {
                      _deactivateCompany(companyId, companyName);
                    } else if (value == 'delete') {
                      _deleteCompany(companyId, companyName);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'deactivate',
                      child: ListTile(
                        leading: Icon(Icons.pause_circle_outline),
                        title: Text('Pasife Al'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Sil', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}