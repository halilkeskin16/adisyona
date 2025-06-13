import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart'; // Mevcut CategoryModel'ınızın yolu
import '../../models/product_model.dart'; // Mevcut ProductModel'ınızın yolu
import '../../providers/auth_provider.dart'; // Mevcut AuthProvider'ınızın yolu

class ProductManagementView extends StatefulWidget {
  const ProductManagementView({super.key});

  @override
  State<ProductManagementView> createState() => _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView> {
  // Metin kontrolcüleri ve durum değişkenleri
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();

  String? _selectedCategoryId; // Ürün eklenecek kategorinin ID'si

  List<Category> _categories = []; // Tanımlı kategoriler listesi
  List<Product> _products = []; // Tanımlı ürünler listesi

  bool _isAddingCategory = false; // Kategori ekleme yüklenme durumu
  bool _isAddingProduct = false; // Ürün ekleme yüklenme durumu
  String? _resultMessage; // İşlem sonuç mesajı

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndProducts(); // Ekran yüklendiğinde kategori ve ürünleri çek
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    super.dispose();
  }

  // Kategorileri ve ürünleri Firestore'dan çeken metod
  Future<void> _loadCategoriesAndProducts() async {
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
      // Şirkete özel kategorileri çek
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('companyId', isEqualTo: user.companyId)
          .get();

      // Şirkete özel ürünleri çek
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('companyId', isEqualTo: user.companyId)
          .get();

      setState(() {
        _categories = categorySnapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        _products = productSnapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        // Eğer daha önce seçili bir kategori ID'si varsa ve bu kategori silindiyse null yap
        if (_selectedCategoryId != null && !_categories.any((cat) => cat.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
        // Eğer hiçbir kategori seçili değilse ve kategoriler varsa ilkini seç
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Kategori ve ürünler yüklenirken sorun oluştu: $e";
      });
      print("Error loading categories and products: $e");
    }
  }

  // Yeni kategori ekleme metod
  Future<void> _addCategory() async {
    setState(() {
      _isAddingCategory = true;
      _resultMessage = null;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.companyId == null) {
      setState(() {
        _resultMessage = "Hata: Kullanıcı bilgileri veya şirket ID'si eksik.";
        _isAddingCategory = false;
      });
      return;
    }

    final name = _categoryNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _resultMessage = "Hata: Kategori adı boş olamaz.";
        _isAddingCategory = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('categories').add({
        'name': name,
        'companyId': user.companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _categoryNameController.clear();
      await _loadCategoriesAndProducts();
      setState(() {
        _resultMessage = "Kategori başarıyla eklendi.";
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Kategori eklenirken sorun oluştu: $e";
      });
    } finally {
      setState(() => _isAddingCategory = false);
    }
  }

  // Yeni ürün ekleme metod
  Future<void> _addProduct() async {
    setState(() {
      _isAddingProduct = true;
      _resultMessage = null;
    });

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.companyId == null) {
      setState(() {
        _resultMessage = "Hata: Kullanıcı bilgileri veya şirket ID'si eksik.";
        _isAddingProduct = false;
      });
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _resultMessage = "Hata: Lütfen bir kategori seçin.";
        _isAddingProduct = false;
      });
      return;
    }

    final name = _productNameController.text.trim();
    final desc = _productDescriptionController.text.trim();
    final price = double.tryParse(_productPriceController.text.trim());

    if (name.isEmpty || price == null || price <= 0) {
      setState(() {
        _resultMessage = "Hata: Ürün adı ve geçerli bir fiyat giriniz.";
        _isAddingProduct = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'description': desc,
        'price': price,
        'categoryId': _selectedCategoryId,
        'companyId': user.companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _productNameController.clear();
      _productDescriptionController.clear();
      _productPriceController.clear();
      await _loadCategoriesAndProducts();
      setState(() {
        _resultMessage = "Ürün başarıyla eklendi.";
      });
    } catch (e) {
      setState(() {
        _resultMessage = "Hata: Ürün eklenirken sorun oluştu: $e";
      });
    } finally {
      setState(() => _isAddingProduct = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ürün ve Kategori Yönetimi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Yeni Kategori Ekle Bölümü
              Text(
                "Yeni Kategori Ekle",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _categoryNameController,
                      labelText: "Kategori Adı (Örn: Tatlılar)",
                      icon: Icons.category_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    onPressed: _addCategory,
                    label: "Ekle",
                    isLoading: _isAddingCategory,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Yeni Ürün Ekle Bölümü
              Text(
                "Yeni Ürün Ekle",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(colorScheme), // Kategori seçimi dropdown'ı
              const SizedBox(height: 16),
              _buildTextField(
                controller: _productNameController,
                labelText: "Ürün Adı (Örn: Latte)",
                icon: Icons.fastfood_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _productDescriptionController,
                labelText: "Açıklama (İsteğe Bağlı)",
                icon: Icons.description_outlined,
                maxLines: 2, // Açıklama için daha fazla satır
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _productPriceController,
                labelText: "Fiyat (₺)",
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                onPressed: _addProduct,
                label: "Ürün Ekle",
                isLoading: _isAddingProduct,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 32),

              // İşlem sonucu mesajı
              if (_resultMessage != null) _buildResultMessage(colorScheme),
              const SizedBox(height: 24),

              Divider(color: colorScheme.onSurface.withOpacity(0.2)),
              const SizedBox(height: 20),

              // Tanımlı Kategoriler ve Ürünler Bölümü
              Text(
                "Tüm Ürünler",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              _buildProductsList(colorScheme, textTheme), // Ürün listesi

              const SizedBox(height: 20), // Alt kısımda boşluk
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
    int maxLines = 1, // Yeni eklenen özellik
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
      cursorColor: Theme.of(context).colorScheme.primary,
      maxLines: maxLines, // TextField'ın maksimum satır sayısını ayarla
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
        backgroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text(
              label,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  // Kategori seçimi dropdown'ı için yardımcı metod
  Widget _buildCategoryDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
      decoration: InputDecoration(
        labelText: "Kategori Seç",
        prefixIcon: Icon(Icons.menu_book_outlined, color: colorScheme.primary.withOpacity(0.7)), // Kategori ikonu
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      ),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      dropdownColor: colorScheme.surface,
    );
  }

  // Hata/Başarı mesajını gösteren yardımcı metod
  Widget _buildResultMessage(ColorScheme colorScheme) {
    bool isError = _resultMessage!.startsWith("Hata");
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

  // Ürünleri listeleyen yardımcı metod
  Widget _buildProductsList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_products.isEmpty && _categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Henüz tanımlı kategori veya ürün bulunmamaktadır. Lütfen yukarıdan yeni bir kategori ve ürün ekleyin.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      );
    }
    if (_products.isEmpty && _categories.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Seçili kategorilerde henüz ürün bulunmamaktadır. Lütfen yukarıdan yeni bir ürün ekleyin.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Kaydırma özelliğini kapat
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final category = _categories.firstWhere(
          (c) => c.id == product.categoryId,
          orElse: () => Category(id: '', name: 'Bilinmeyen Kategori', companyId: ''),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${product.price.toStringAsFixed(2)} ₺",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // İsteğe bağlı olarak düzenle/sil gibi aksiyon butonları eklenebilir
              ],
            ),
          ),
        );
      },
    );
  }
}
