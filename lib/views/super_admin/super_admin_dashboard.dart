import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart'; // Bu dosyanın mevcut olduğunu varsayıyorum
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
    _fetchCompanies(); // Uygulama başladığında şirketleri getir
  }

  // Şirketleri Firestore'dan çeken metod
  Future<void> _fetchCompanies() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('companies').get();
      final list = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'validUntil': doc['validUntil']?.toDate(), // Timestamp'i DateTime'a çevir
        };
      }).toList();

      setState(() {
        _companies = list; // Şirket listesini güncelle
      });
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver veya logla
      print("Şirketler çekilirken hata oluştu: $e");
      setState(() {
        _result = "Şirketler yüklenirken hata oluştu.";
      });
    }
  }

  // Yeni firma ve admin oluşturan metod
  Future<void> _createCompanyWithAdmin() async {
    // Giriş alanlarının boş olup olmadığını kontrol et
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
      _isLoading = true; // Yükleniyor durumunu başlat
      _result = null; // Önceki sonucu temizle
    });

    try {
      final companyName = _firmNameController.text.trim();
      final adminPhone = _adminPhoneController.text.trim();
      final adminPassword = _adminPasswordController.text.trim();

      // Yeni şirket dokümanını Firestore'a ekle
      final companyRef = await FirebaseFirestore.instance.collection('companies').add({
        'name': companyName,
        'createdAt': FieldValue.serverTimestamp(), // Sunucu zaman damgası
        'validUntil': _validUntil,
      });

      final companyId = companyRef.id; // Oluşturulan şirketin ID'si

      // AuthService kullanarak yeni admin kullanıcısını kaydet
      final authService = AuthService(); // AuthService'i başlat
      await authService.register(
        phone: adminPhone,
        password: adminPassword,
        role: 'admin', // Rolü admin olarak ayarla
        companyId: companyId, // Şirket ID'sini ata
      );

      // Başarılı olursa form alanlarını temizle ve sonucu göster
      setState(() {
        _result = "Firma ve admin başarıyla oluşturuldu.";
        _firmNameController.clear();
        _adminPhoneController.clear();
        _adminPasswordController.clear();
        _validUntil = null;
      });

      await _fetchCompanies(); // Şirket listesini yeniden yükle
    } catch (e) {
      // Hata durumunda kullanıcıya hata mesajını göster
      setState(() {
        _result = "Hata oluştu: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false); // Yükleniyor durumunu bitir
    }
  }

  // Tarih seçiciyi açan metod
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)), // Varsayılan olarak 30 gün sonrası
      firstDate: DateTime.now(), // Başlangıç tarihi bugünden itibaren
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 yıl sonrasına kadar tarih seçimi
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // Tarih seçici rengini ayarla
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _validUntil = picked; // Seçilen tarihi kaydet
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerini ve metin stillerini tanımla
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Süper Admin Paneli",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: colorScheme.primary, // AppBar rengini ayarla
        elevation: 0, // Gölgeyi kaldır
      ),
      body: Container(
        // Arka plan rengini ve kenar yuvarlaklığını ayarla
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Yeni Firma Ekle" başlığı
              Text(
                "Yeni Firma Ekle",
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Firma Adı giriş alanı
              _buildTextField(
                controller: _firmNameController,
                labelText: "Firma Adı",
                icon: Icons.business,
              ),
              const SizedBox(height: 16),

              // Admin Telefon Numarası giriş alanı
              _buildTextField(
                controller: _adminPhoneController,
                labelText: "Admin Telefon Numarası",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Admin Şifresi giriş alanı
              _buildTextField(
                controller: _adminPasswordController,
                labelText: "Admin Şifresi",
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Geçerlilik Tarihi Seç butonu
              _buildDateSelectionButton(colorScheme),
              const SizedBox(height: 24),

              // Sonuç mesajı (Hata/Başarı)
              if (_result != null) _buildResultMessage(colorScheme),
              const SizedBox(height: 12),

              // "Firmayı Kaydet" butonu
              _buildSaveCompanyButton(colorScheme),
              const SizedBox(height: 40),

              // Ayrıcı çizgi
              Divider(color: colorScheme.onSurface.withOpacity(0.2)),
              const SizedBox(height: 20),

              // "Kayıtlı Firmalar" başlığı
              Text(
                "Kayıtlı Firmalar",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Şirket listesi
              _buildCompanyList(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // Ortak TextField stilini oluşturan yardımcı metod
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Yuvarlatılmış kenarlar
          borderSide: BorderSide.none, // Kenarlık çizgisini kaldır
        ),
        filled: true, // Alanın arka planını doldur
        fillColor: Theme.of(context).colorScheme.surface, // Arka plan rengi
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto, // Label davranışı
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // Odaklanıldığında ana renk
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      cursorColor: Theme.of(context).colorScheme.primary,
    );
  }

  // Tarih seçimi butonu için yardımcı metod
  Widget _buildDateSelectionButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _pickDate,
        icon: Icon(Icons.calendar_today, color: colorScheme.onPrimary),
        label: Text(
          _validUntil == null
              ? "Geçerlilik Tarihi Seç"
              : "Son Tarih: ${DateFormat('dd MMMM yyyy').format(_validUntil!)}",
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, // Buton rengi
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Yuvarlatılmış kenarlar
          ),
          elevation: 5, // Gölge ekle
        ),
      ),
    );
  }

  // Sonuç mesajını gösteren yardımcı metod
  Widget _buildResultMessage(ColorScheme colorScheme) {
    bool isError = _result!.startsWith("Hata");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colorScheme.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
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
              _result!,
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

  // Kaydet butonunu oluşturan yardımcı metod
  Widget _buildSaveCompanyButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createCompanyWithAdmin,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary, // İkincil buton rengi
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Yuvarlatılmış kenarlar
          ),
          elevation: 5, // Gölge ekle
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
            : Text(
                "Firmayı Kaydet",
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Şirket listesini oluşturan yardımcı metod
  Widget _buildCompanyList(ColorScheme colorScheme) {
    if (_companies.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          "Henüz kayıtlı firma bulunmamaktadır.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true, // Listeyi içeriğine göre boyutlandır
      physics: const NeverScrollableScrollPhysics(), // Scroll özelliğini devre dışı bırak
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final company = _companies[index];
        final dateFormatted = company['validUntil'] != null
            ? DateFormat('dd MMMM yyyy').format(company['validUntil'])
            : 'Tanımsız';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3, // Kartın gölgesi
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Yuvarlatılmış kenarlar
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // İkon veya renkli bir gösterge ekleyebiliriz
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
                        company['name'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Geçerlilik Tarihi: $dateFormatted",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Ekstra butonlar veya bilgiler eklenebilir (örneğin düzenle/sil)
              ],
            ),
          ),
        );
      },
    );
  }
}
