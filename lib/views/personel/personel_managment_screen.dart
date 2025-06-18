import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/staff_provider.dart'; // StaffProvider'ınızın yolu

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _staffPhoneController = TextEditingController();
  final TextEditingController _staffPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StaffProvider>(context, listen: false).fetchStaff();
    });
  }

  @override
  void dispose() {
    _staffNameController.dispose();
    _staffPhoneController.dispose();
    _staffPasswordController.dispose();
    super.dispose();
  }

  void _handleAddStaff() {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    staffProvider.addStaff(
      name: _staffNameController.text.trim(),
      phone: _staffPhoneController.text.trim(),
      password: _staffPasswordController.text.trim(),
    ).then((_) {
      if (staffProvider.resultMessage?.startsWith("Başarılı") ?? false) {
        _staffNameController.clear();
        _staffPhoneController.clear();
        _staffPasswordController.clear();
        // ignore: use_build_context_synchronously
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Consumer<StaffProvider>(
      builder: (context, staffProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Personel Yönetimi",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: colorScheme.primary,
            elevation: 2,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Yeni Personel Ekle",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _staffNameController,
                    labelText: "Personel Adı Soyadı",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _staffPhoneController,
                    labelText: "Telefon Numarası",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _staffPasswordController,
                    labelText: "Şifre",
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  if (staffProvider.resultMessage != null)
                    _buildResultMessage(colorScheme, staffProvider.resultMessage!),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: staffProvider.isLoading ? null : _handleAddStaff,
                      icon: staffProvider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        staffProvider.isLoading ? "Ekleniyor..." : "Personel Ekle",
                        style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Divider(color: colorScheme.onSurface.withValues(alpha: 0.1), thickness: 1),
                  const SizedBox(height: 20),

                  Text(
                    "Kayıtlı Personel",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personel Listesi
                  _buildStaffList(context, staffProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Personel listesini oluşturan yardımcı metod.
  Widget _buildStaffList(BuildContext context, StaffProvider staffProvider) {
    if (staffProvider.isLoading && staffProvider.staffList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (staffProvider.staffList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Henüz kayıtlı personel bulunmamaktadır.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: staffProvider.staffList.length,
      itemBuilder: (context, index) {
        final staff = staffProvider.staffList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: Icon(Icons.badge_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(staff.phone ?? "Geçersiz Tel", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: const Text("Rol: Garson"),
            // İsteğe bağlı: Silme veya düzenleme butonu buraya eklenebilir.
            // trailing: IconButton(
            //   icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            //   onPressed: () { /* Silme işlemi için provider'daki metodu çağır */ },
            // ),
          ),
        );
      },
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        prefixIcon: icon != null ? Icon(icon, color: colorScheme.primary.withValues(alpha: 0.7)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainer.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      cursorColor: colorScheme.primary,
    );
  }

  /// Hata/Başarı mesajını gösteren yardımcı metod.
  Widget _buildResultMessage(ColorScheme colorScheme, String message) {
    // Mesajın içeriğine göre hata mı başarı mı olduğuna karar veriyoruz.
    bool isError = message.toLowerCase().startsWith("hata");
    Color messageColor = isError ? colorScheme.error : Colors.green;
    IconData messageIcon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: messageColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: messageColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(messageIcon, color: messageColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: messageColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}