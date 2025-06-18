// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/company_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/super_admin_provider.dart';

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

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'tr_TR';
  }

  @override
  void dispose() {
    _firmNameController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  // Yeni şirket oluşturma işlemini başlatan metot
  void _handleCreateCompany(BuildContext context) {
    if (_firmNameController.text.trim().isEmpty ||
        _adminPhoneController.text.trim().isEmpty ||
        _adminPasswordController.text.trim().isEmpty ||
        _validUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Lütfen tüm alanları doldurun ve tarih seçin."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Provider'daki metodu çağırıyoruz, dinleme (listen) kapalı olmalı
    final provider = Provider.of<SuperAdminProvider>(context, listen: false);
    provider.createCompany(
      companyName: _firmNameController.text.trim(),
      adminPhone: _adminPhoneController.text.trim(),
      adminPassword: _adminPasswordController.text.trim(),
      validUntil: _validUntil!,
    ).then((_) {
      if (provider.resultMessage != null && provider.resultMessage!.contains("başarıyla")) {
        _firmNameController.clear();
        _adminPhoneController.clear();
        _adminPasswordController.clear();
        setState(() {
          _validUntil = null;
        });
      }
    });
  }

  // Tarih seçici metodu
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
      setState(() { _validUntil = picked; });
    }
  }

  // Çıkış metodu
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Çıkış Yap'),
          content: const Text('Oturumu sonlandırmak istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Çıkış Yap'),
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }
  
  // Placeholder metotları
  void _deactivateCompany(String companyId, String companyName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$companyName pasife alınacak.")));
  }

  void _deleteCompany(String companyId, String companyName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$companyName silinecek.")));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<SuperAdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Süper Admin Paneli", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  Text("Yeni Firma Ekle", style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 24),
                  _buildTextField(controller: _firmNameController, labelText: "Firma Adı", icon: Icons.business),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _adminPhoneController, labelText: "Admin Telefon Numarası", icon: Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _adminPasswordController, labelText: "Admin Şifresi", icon: Icons.lock, obscureText: true),
                  const SizedBox(height: 16),
                  _buildDateSelectionButton(colorScheme),
                  const SizedBox(height: 24),
                  if (provider.resultMessage != null) _buildResultMessage(colorScheme, provider.resultMessage!),
                  const SizedBox(height: 12),
                  _buildSaveCompanyButton(colorScheme, provider.isLoading),
                  const SizedBox(height: 40),
                  Divider(color: colorScheme.onSurface.withValues(alpha: 0.1), thickness: 1),
                  const SizedBox(height: 20),
                  Text("Kayıtlı Firmalar", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  _buildCompanyList(provider.companies, provider.isLoading),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // YARDIMCI WIDGET METOTLARI
  
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
        prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).colorScheme.primary) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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
      label: Text(_validUntil == null ? "Geçerlilik Tarihi Seç" : "Son Tarih: ${DateFormat('dd MMMM, yyyy').format(_validUntil!)}"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1),
      ),
    );
  }

  Widget _buildResultMessage(ColorScheme colorScheme, String message) {
    bool isError = message.toLowerCase().contains("hata");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colorScheme.errorContainer : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? colorScheme.onErrorContainer : Colors.green.shade800),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: isError ? colorScheme.onErrorContainer : Colors.green.shade800, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSaveCompanyButton(ColorScheme colorScheme, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : () => _handleCreateCompany(context),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text("Firmayı ve Admini Oluştur", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCompanyList(List<Company> companies, bool isLoading) {
    if (companies.isEmpty) {
      if (isLoading) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Henüz kayıtlı firma bulunmamaktadır.")));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        final dateFormatted = company.validUntil != null ? DateFormat('dd MMMM, yyyy').format(company.validUntil!) : 'Tanımsız';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.apartment, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Son Tarih: $dateFormatted", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'deactivate') {
                      _deactivateCompany(company.id, company.name);
                    } else if (value == 'delete') {
                      _deleteCompany(company.id, company.name);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'deactivate', child: ListTile(leading: Icon(Icons.pause_circle_outline), title: Text('Pasife Al'))),
                    const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Sil', style: TextStyle(color: Colors.red)))),
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