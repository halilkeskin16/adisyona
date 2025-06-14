import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// DİKKAT: Bu dosyadaki geçici OrderItem ve AppUser modeli tanımları KALDIRILDI.
// Lütfen OrderItem ve AppUser sınıflarının tanımının sadece kendi model dosyalarında olduğundan emin olun.


class OrderFormScreen extends StatefulWidget {
  final String tableId;
  final String tableName;

  const OrderFormScreen({
    super.key,
    required this.tableId,
    required this.tableName,
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;
  OrderProvider? _orderProviderInstance; // OrderProvider örneğini saklamak için yeni değişken
  ProductProvider? _productProviderInstance; // ProductProvider örneğini saklamak için yeni değişken


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      _productProviderInstance = Provider.of<ProductProvider>(context, listen: false); // ProductProvider örneğini burada al
      _orderProviderInstance = Provider.of<OrderProvider>(context, listen: false); // OrderProvider örneğini burada al

      if (user != null && user.companyId != null) {
        // WidgetsBinding.instance.addPostFrameCallback kullanarak kodu bir sonraki kare çizildikten sonra çalıştır
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Ürün ve kategorileri yükle
          await _productProviderInstance!.fetchData(user.companyId!);
          // Masaya ait mevcut siparişi yükle
          await _orderProviderInstance!.fetchOrderForTable(tableId: widget.tableId, companyId: user.companyId!);
        });
      }

      // Arama kontrolcüsünü ProductProvider'ın setSearchText metoduna bağla
      _searchController.addListener(() {
        _productProviderInstance!.setSearchText(_searchController.text); // Saklanan örneği kullan
      });

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Ekran kapatıldığında OrderProvider'ın state'ini temizle
    // Güvenli bir şekilde saklanan Provider örneği kullanılıyor ve WidgetsBinding kullanılarak ertelendi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderProviderInstance?.clearOrder();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = Provider.of<AuthProvider>(context, listen: false).user; // AppUser tipi için

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "İç Mekan / ${widget.tableName}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: false, // Sol hizala
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context), color: Colors.white),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView( // Tüm body içeriğini kaydırılabilir yap
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "# ARAMA YAP / BARKOD OKUT #",
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),

              // Kategoriler
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kategoriler",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                        fontSize: 18, // Font büyüklüğünü ayarladım
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryGrid(colorScheme, productProvider), // Kategori gridi
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ürünler
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ürünler",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                        fontSize: 18, // Font büyüklüğünü ayarladım
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Ürünler listesi
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4, // Ekran yüksekliğinin %40'ı kadar max yükseklik, kaydırma etkinleştirildi
                ),
                child: productProvider.isLoading && productProvider.filteredProducts.isEmpty && productProvider.categories.isNotEmpty
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : productProvider.filteredProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                productProvider.categories.isEmpty
                                    ? "Kategori bulunamadı. Lütfen önce kategori ekleyin."
                                    : "Bu kategoriye ait ürün bulunmamaktadır.",
                                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _buildProductList(colorScheme, textTheme, productProvider, orderProvider), // Filtrelenmiş ürünler
              ),
              const SizedBox(height: 24),

              // İşlem sonucu mesajı
              if (productProvider.message != null && productProvider.message!.isNotEmpty)
                _buildResultMessage(colorScheme, productProvider.message!),
              if (orderProvider.message != null && orderProvider.message!.isNotEmpty)
                _buildResultMessage(colorScheme, orderProvider.message!),
              const SizedBox(height: 24),

              // Sipariş Özeti ve Butonlar
              _buildOrderSummaryAndButtons(colorScheme, textTheme, orderProvider, user),
            ],
          ),
        ),
      ),
    );
  }

  // Kategorileri yan yana 2 tane olacak şekilde oluşturan yardımcı metod
  Widget _buildCategoryGrid(ColorScheme colorScheme, ProductProvider productProvider) {
    if (productProvider.categories.isEmpty) {
      return Center(
        child: Text(
          productProvider.isLoading ? "Kategoriler yükleniyor..." : "Henüz kategori tanımlanmamıştır.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true, // İçeriğine göre boyutlandır
      physics: const NeverScrollableScrollPhysics(), // İç kaydırmayı devre dışı bırak
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Her satırda 2 kategori
        mainAxisSpacing: 10, // Dikey boşluk
        crossAxisSpacing: 10, // Yatay boşluk
        childAspectRatio: 2.5 / 1, // Öğelerin en/boy oranı (daha geniş)
      ),
      itemCount: productProvider.categories.length,
      itemBuilder: (context, index) {
        final category = productProvider.categories[index];
        final isSelected = productProvider.selectedCategoryId == category.id;
        return GestureDetector(
          onTap: () {
            productProvider.setSelectedCategory(category.id);
            _searchController.clear(); // Kategori değişince aramayı temizle
          },
          child: Card(
            elevation: isSelected ? 6 : 2, // Seçiliyse daha belirgin gölge
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Daha az yuvarlak
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2.0 : 1,
              ),
            ),
            color: isSelected ? colorScheme.primary.withOpacity(0.15) : colorScheme.surfaceVariant,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // İç boşlukları ayarla
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13, // Font büyüklüğünü düşürdüm
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Ürünleri tek satırda listeler ve daha minimalist bir görünüm sağlar
  Widget _buildProductList(ColorScheme colorScheme, TextTheme textTheme, ProductProvider productProvider, OrderProvider orderProvider) {
    if (productProvider.filteredProducts.isEmpty) {
      return Center(
        child: Text(
          "Seçili kategori veya arama kriterlerine göre ürün bulunmamaktadır.",
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true, // İçeriğine göre boyutlandır
      physics: const ClampingScrollPhysics(), // İç kaydırmayı etkinleştir (Ürün listesi kendi içinde kaydırılabilir olacak)
      itemCount: productProvider.filteredProducts.length,
      itemBuilder: (_, index) {
        final product = productProvider.filteredProducts[index];
        final isProductSelected = orderProvider.selectedItems.any((item) => item.productId == product.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0), // Dikeyde boşluk
          child: GestureDetector(
            onTap: () => orderProvider.addProduct(OrderItem(
              productId: product.id,
              name: product.name,
              price: product.price,
              quantity: 1, // Yeni eklenen ürünün başlangıç miktarı
              status: 'pending', // Yeni sipariş öğesinin başlangıç durumu
            )), // Tıklama ile ürünü ekle/miktar artır
            child: Card(
              elevation: isProductSelected ? 6 : 3, // Seçiliyse daha belirgin gölge
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isProductSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                  width: isProductSelected ? 2.0 : 1,
                ),
              ),
              color: isProductSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // İç boşlukları ayarla
                child: Row( // Ürün bilgilerini yatayda sırala
                  children: [
                    // Resim için yer tutucu
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fastfood, color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: 14, // Font büyüklüğünü düşürdüm
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            product.description.isNotEmpty ? product.description : "Açıklama yok",
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 11, // Font büyüklüğünü düşürdüm
                            ),
                            maxLines: 1, // Minimalist için 1 satır
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12), // Fiyat ile metin arası boşluk
                    Text(
                      '${product.price.toStringAsFixed(2)} ₺',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 14, // Font büyüklüğünü düşürdüm
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Hata/Başarı mesajını gösteren yardımcı metod
  Widget _buildResultMessage(ColorScheme colorScheme, String message) {
    bool isError = message.startsWith("Hata");
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

  // Seçilen ürünleri ve toplam tutarı gösteren bölüm
  Widget _buildSelectedItemsList(ColorScheme colorScheme, TextTheme textTheme, OrderProvider orderProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: orderProvider.selectedItems.length,
      itemBuilder: (context, index) {
        final item = orderProvider.selectedItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Seçim kutusu
                Checkbox(
                  value: orderProvider.isItemSelectedForPayment(item),
                  onChanged: (bool? value) {
                    orderProvider.toggleItemSelectionForPayment(item);
                  },
                  activeColor: colorScheme.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "${item.price.toStringAsFixed(2)} ₺",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Miktar kontrol butonları
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: colorScheme.error, size: 20),
                      onPressed: () => orderProvider.decreaseQty(item),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    Text(
                      item.quantity.toString(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 20),
                      onPressed: () => orderProvider.increaseQty(item),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                      onPressed: () => orderProvider.removeItem(item),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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

  // Sipariş özeti ve butonları içeren sabit alt kısım
  Widget _buildOrderSummaryAndButtons(ColorScheme colorScheme, TextTheme textTheme, OrderProvider orderProvider, AppUser? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seçili ürünlerin listesi
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final selectedItems = orderProvider.getSelectedItemsForPayment();
              final totalAmount = orderProvider.calculateTotalPrice(selectedItems);
              
              return Column(
                children: [
                  // Seçili ürünler
                  ...orderProvider.selectedItems.map((item) {
                    final isCompleted = item.status == 'completed';
                    return CheckboxListTile(
                      title: Text(
                        item.name,
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        '${item.quantity} adet x ${item.price.toStringAsFixed(2)} TL',
                        style: TextStyle(
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      value: orderProvider.isItemSelectedForPayment(item),
                      onChanged: isCompleted ? null : (bool? value) {
                        orderProvider.toggleItemSelectionForPayment(item);
                      },
                      secondary: Text(
                        '${(item.price * item.quantity).toStringAsFixed(2)} TL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey : colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  // Toplam tutar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seçili Ürünler Toplamı:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${totalAmount.toStringAsFixed(2)} TL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                    if (orderProvider.selectedItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen en az bir ürün seçin')),
                      );
                      return;
                    }
                    orderProvider.submitOrder(
                      tableId: widget.tableId,
                      tableName: widget.tableName,
                      companyId: user?.companyId ?? '',
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sipariş "${widget.tableName}" masasına gönderildi!'),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      onError: (msg) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg), backgroundColor: colorScheme.error),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Siparişi Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                    final selectedItems = orderProvider.getSelectedItemsForPayment();
                    if (selectedItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen ödenecek ürünleri seçin')),
                      );
                      return;
                    }
                    _showPaymentDialog(selectedItems);
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Hesap Al'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(List<OrderItem> selectedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Yöntemi Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seçili Ürünler:'),
            const SizedBox(height: 8),
            ...selectedItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${item.name} x${item.quantity} - ${(item.price * item.quantity).toStringAsFixed(2)} TL'),
            )),
            const Divider(),
            Text(
              'Toplam: ${selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)} TL',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _processPayment('cash', selectedItems),
            child: const Text('Nakit'),
          ),
          ElevatedButton(
            onPressed: () => _processPayment('card', selectedItems),
            child: const Text('Kart'),
          ),
          ElevatedButton(
            onPressed: () => _processPayment('meal_card', selectedItems),
            child: const Text('Yemek Kartı'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String paymentMethod, List<OrderItem> selectedItems) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.processPayment(paymentMethod, selectedItems);

      if (mounted) {
        Navigator.pop(context); // Ödeme dialogunu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarıyla tamamlandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme işlemi sırasında hata oluştu: $e')),
        );
      }
    }
  }
}
