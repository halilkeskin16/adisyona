import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/area_model.dart'; // Mevcut AreaModel'ınızın yolu
import '../../models/table_model.dart'; // Mevcut TableModel'ınızın yolu
import '../../providers/auth_provider.dart'; // Mevcut AuthProvider'ınızın yolu

class AreaTableManagementScreen extends StatefulWidget {
  const AreaTableManagementScreen({super.key});

  @override
  State<AreaTableManagementScreen> createState() => _AreaTableManagementScreenState();
}

class _AreaTableManagementScreenState extends State<AreaTableManagementScreen> {
  // Metin kontrolcüleri ve durum değişkenleri
  final TextEditingController _areaNameController = TextEditingController();
  final TextEditingController _tableNameController = TextEditingController();
  String? _selectedAreaId; // Masa eklenecek bölgenin ID'si
  List<Area> _areas = []; // Tanımlı bölgeler listesi
  List<TableModel> _tables = []; // Tanımlı masalar listesi

  bool _isAddingArea = false; // Bölge ekleme yüklenme durumu
  bool _isAddingTable = false; // Masa ekleme yüklenme durumu
  String? _resultMessage; // İşlem sonuç mesajı

  @override
  void initState() {
    super.initState();
    _loadAreasAndTables(); // Ekran yüklendiğinde bölgeleri ve masaları çek
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    _tableNameController.dispose();
    super.dispose();
  }

  // Bölgeleri ve masaları Firestore'dan çeken metod
  Future<void> _loadAreasAndTables() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user; // Oturum açmış kullanıcıyı al

    if (user == null || user.companyId == null) {
      // Kullanıcı veya şirket ID'si yoksa hata mesajı göster
      setState(() {
        _resultMessage = "Hata: Kullanıcı bilgileri veya şirket ID'si eksik.";
      });
      return;
    }

    try {
      // Şirkete özel bölgeleri çek
      final areaSnapshot = await FirebaseFirestore.instance
          .collection('areas')
          .where('companyId', isEqualTo: user.companyId)
          .get();

      // Şirkete özel masaları çek
      final tableSnapshot = await FirebaseFirestore.instance
          .collection('tables')
          .where('companyId', isEqualTo: user.companyId)
          .get();

      setState(() {
        _areas = areaSnapshot.docs
            .map((doc) => Area.fromMap(doc.id, doc.data()))
            .toList();

        _tables = tableSnapshot.docs
            .map((doc) => TableModel.fromMap(doc.id, doc.data()))
            .toList();

        // Eğer daha önce seçili bir bölge ID'si varsa ve bu bölge silindiyse null yap
        if (_selectedAreaId != null && !_areas.any((area) => area.id == _selectedAreaId)) {
          _selectedAreaId = null;
        }
        // Eğer hiçbir bölge seçili değilse ve bölgeler varsa ilkini seç
        if (_selectedAreaId == null && _areas.isNotEmpty) {
          _selectedAreaId = _areas.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Bölgeler ve masalar yüklenirken sorun oluştu: $e";
      });
    }
  }

  // Yeni bölge ekleme metod
  Future<void> _addArea() async {
    setState(() {
      _isAddingArea = true;
      _resultMessage = null;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.companyId == null) {
      setState(() {
        _resultMessage = "Hata: Kullanıcı bilgileri veya şirket ID'si eksik.";
        _isAddingArea = false;
      });
      return;
    }

    final name = _areaNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _resultMessage = "Hata: Bölge adı boş olamaz.";
        _isAddingArea = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('areas').add({
        'name': name,
        'companyId': user.companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _areaNameController.clear();
      await _loadAreasAndTables();
      setState(() {
        _resultMessage = "Bölge başarıyla eklendi.";
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Bölge eklenirken sorun oluştu: $e";
      });
    } finally {
      setState(() => _isAddingArea = false);
    }
  }

  // Yeni masa ekleme metod
  Future<void> _addTable() async {
    setState(() {
      _isAddingTable = true;
      _resultMessage = null;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.companyId == null) {
      setState(() {
        _resultMessage = "Hata: Kullanıcı bilgileri veya şirket ID'si eksik.";
        _isAddingTable = false;
      });
      return;
    }

    if (_selectedAreaId == null) {
      setState(() {
        _resultMessage = "Hata: Lütfen bir bölge seçin.";
        _isAddingTable = false;
      });
      return;
    }

    final name = _tableNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _resultMessage = "Hata: Masa adı boş olamaz.";
        _isAddingTable = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tables').add({
        'name': name,
        'areaId': _selectedAreaId,
        'companyId': user.companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _tableNameController.clear();
      await _loadAreasAndTables();
      setState(() {
        _resultMessage = "Masa başarıyla eklendi.";
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Masa eklenirken sorun oluştu: $e";
      });
    } finally {
      setState(() => _isAddingTable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Panel – Bölge & Masa",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true, // Başlığı ortala
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface, // Temanın arka plan rengini kullan
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yeni Bölge Ekle Bölümü
              Text(
                "Yeni Bölge Ekle",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _areaNameController,
                      labelText: "Bölge Adı (Örn: Bahçe)",
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    onPressed: _addArea,
                    label: "Ekle",
                    isLoading: _isAddingArea,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Yeni Masa Ekle Bölümü
              Text(
                "Yeni Masa Ekle",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildAreaDropdown(colorScheme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _tableNameController,
                      labelText: "Masa Adı (Örn: Masa 1)",
                      icon: Icons.table_restaurant_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    onPressed: _addTable,
                    label: "Ekle",
                    isLoading: _isAddingTable,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // İşlem sonucu mesajı
              if (_resultMessage != null) _buildResultMessage(colorScheme),
              const SizedBox(height: 24),

              Divider(color: colorScheme.onSurface.withValues(alpha: 0.2), thickness: 1),
              const SizedBox(height: 20),

              // Tanımlı Bölgeler ve Masalar Bölümü
              Text(
                "Tanımlı Bölgeler ve Masalar",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildAreasAndTablesList(colorScheme, textTheme),
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
        prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
      cursorColor: Theme.of(context).colorScheme.primary,
    );
  }

  // Ortak aksiyon butonu stili oluşturan yardımcı metod
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required bool isLoading,
    required ColorScheme colorScheme,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary, // Buton rengi
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Dikeyde TextField ile aynı
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Yuvarlatılmış kenarlar
        ),
        elevation: 3, // Gölge ekle
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text(
              label,
              style: TextStyle(
                color: colorScheme.onPrimary, // Metin rengi
                fontSize: 16, // Metin boyutu
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  // Bölge seçimi dropdown'ı için yardımcı metod
  Widget _buildAreaDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _selectedAreaId,
      items: _areas.map((area) {
        return DropdownMenuItem<String>(
          value: area.id,
          child: Text(area.name),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedAreaId = val),
      decoration: InputDecoration(
        labelText: "Bölge Seç",
        prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
      ),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      dropdownColor: colorScheme.surface, // Dropdown menü arka plan rengi
    );
  }

  // Hata/Başarı mesajını gösteren yardımcı metod
  Widget _buildResultMessage(ColorScheme colorScheme) {
    bool isError = _resultMessage!.startsWith("Hata");
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
              _resultMessage!,
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

  // Bölgeleri ve Masaları listeleyen yardımcı metod
  Widget _buildAreasAndTablesList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_areas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Henüz tanımlı bölge bulunmamaktadır. Lütfen yukarıdan yeni bir bölge ekleyin.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Kaydırma özelliğini kapat
      itemCount: _areas.length,
      itemBuilder: (context, index) {
        final area = _areas[index];
        final areaTables = _tables.where((t) => t.areaId == area.id).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4, // Daha belirgin gölge
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Daha yuvarlak kenarlar
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            collapsedBackgroundColor: colorScheme.surface, // Kartın varsayılan arka planı
            backgroundColor: colorScheme.surface, // Açıkken arka plan
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              area.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary, // Bölge adını tema renginde göster
              ),
            ),
            subtitle: Text(
              "${areaTables.length} Masa",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            children: areaTables.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: Text(
                        "Bu bölgeye henüz masa tanımlanmamıştır.",
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    )
                  ]
                : areaTables
                    .map((t) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                          leading: Icon(Icons.chair_alt, color: colorScheme.secondary), // Masa ikonu
                          title: Text(
                            t.name,
                            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                          ),
                          // İsteğe bağlı olarak masa durumunu gösterebiliriz
                          // trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ))
                    .toList(),
          ),
        );
      },
    );
  }
}
