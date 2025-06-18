import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // AuthProvider'ınızın yolu
import '../../models/user_model.dart'; // AppUser modelinizin yolu

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  // Metin kontrolcüleri
  final TextEditingController _staffNameController = TextEditingController();
  final TextEditingController _staffPhoneController = TextEditingController();
  final TextEditingController _staffPasswordController = TextEditingController();

  bool _isLoading = false; // Yüklenme durumu
  String? _resultMessage; // İşlem sonucu mesajı (başarı/hata)

  List<AppUser> _staffList = []; // Personel listesi

  @override
  void initState() {
    super.initState();
    _fetchStaffList(); // Ekran yüklendiğinde mevcut personeli çek
  }

  @override
  void dispose() {
    _staffNameController.dispose();
    _staffPhoneController.dispose();
    _staffPasswordController.dispose();
    super.dispose();
  }

  // Mevcut personeli Firestore'dan çeken metod
  Future<void> _fetchStaffList() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null; // Önceki mesajı temizle
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null || currentUser.companyId == null) {
      setState(() {
        _resultMessage = "Hata: Şirket bilgisi bulunamadı.";
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: currentUser.companyId)
          .where('role', isEqualTo: 'garson') // Sadece 'garson' rolündekileri çek
          .get();

      setState(() {
        _staffList = snapshot.docs
            .map((doc) => AppUser.fromMap(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Personel listesi yüklenirken sorun oluştu: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Yeni personel ekleme metod
  Future<void> _addStaff() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null; // Önceki mesajı temizle
    });

    final phone = _staffPhoneController.text.trim();
    final password = _staffPasswordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      setState(() {
        _resultMessage = "Telefon numarası ve şifre boş bırakılamaz.";
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _resultMessage = "Şifre en az 6 karakter olmalıdır.";
        _isLoading = false;
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null || currentUser.companyId == null) {
      setState(() {
        _resultMessage = "Hata: Şirket bilgisi bulunamadı. Personel eklenemedi.";
        _isLoading = false;
      });
      return;
    }

    try {
      // AuthService üzerinden yeni garsonu kaydet
      // AuthService'in register metodunun AppUser döndürdüğünü varsayıyorum
      await authProvider.register(
        phone,
        password,
        'garson', // Rolü 'garson' olarak ayarla
        currentUser.companyId!, // Mevcut admin'in şirket ID'sini ata
      );

      // Başarılı olursa form alanlarını temizle ve listeyi güncelle
      setState(() {
        _resultMessage = "Personel başarıyla eklendi.";
        _staffNameController.clear();
        _staffPhoneController.clear();
        _staffPasswordController.clear();
      });
      await _fetchStaffList(); // Personel listesini yeniden yükle
    } catch (e) {
      setState(() {
        _resultMessage = "Hata oluştu: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Personel Yönetimi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
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

              // Personel Adı
              _buildTextField(
                controller: _staffNameController,
                labelText: "Personel Adı (İsteğe Bağlı)",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Telefon Numarası
              _buildTextField(
                controller: _staffPhoneController,
                labelText: "Telefon Numarası",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Şifre
              _buildTextField(
                controller: _staffPasswordController,
                labelText: "Şifre",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Sonuç Mesajı
              if (_resultMessage != null) _buildResultMessage(colorScheme, _resultMessage!),
              const SizedBox(height: 12),

              // Personel Ekle Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addStaff,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add, color: Colors.white),
                  label: Text(
                    _isLoading ? "Ekleniyor..." : "Personel Ekle",
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

              Divider(color: colorScheme.onSurface.withValues(alpha: 0.2), thickness: 1),
              const SizedBox(height: 20),

              // Kayıtlı Personel Listesi Başlığı
              Text(
                "Kayıtlı Personel",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Personel Listesi
              _staffList.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        "Henüz kayıtlı personel bulunmamaktadır.",
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    )
                  : _isLoading && _staffList.isEmpty
                      ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(), // İç kaydırmayı devre dışı bırak
                          itemCount: _staffList.length,
                          itemBuilder: (context, index) {
                            final staff = _staffList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              color: colorScheme.surfaceContainerHighest,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.badge, color: colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            staff.phone ?? staff.email ?? "Adı Belirtilmemiş", // Telefon veya e-posta ile göster
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            "Rol: ${staff.role == 'garson' ? 'Garson' : staff.role}", // Rolü Türkçe göster
                                            style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // İsteğe bağlı olarak silme veya düzenleme butonu eklenebilir
                                    // IconButton(
                                    //   icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                    //   onPressed: () { /* Silme işlemi */ },
                                    // ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  // Ortak TextField stilini oluşturan yardımcı metod (Önceki ekranlardan kopyalandı)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        prefixIcon: icon != null ? Icon(icon, color: colorScheme.primary.withValues(alpha: 0.7)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1), // Daha açık bir arka plan rengi
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      cursorColor: colorScheme.primary,
      maxLines: maxLines,
    );
  }

  // Hata/Başarı mesajını gösteren yardımcı metod (Önceki ekranlardan kopyalandı)
  Widget _buildResultMessage(ColorScheme colorScheme, String message) {
    bool isError = message.startsWith("Hata");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colorScheme.error.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? colorScheme.error : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? colorScheme.error : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? colorScheme.error : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
