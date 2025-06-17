import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/table_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';

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
  OrderProvider? _orderProviderInstance;
  ProductProvider? _productProviderInstance;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      _productProviderInstance = Provider.of<ProductProvider>(context, listen: false);
      _orderProviderInstance = Provider.of<OrderProvider>(context, listen: false);

      if (user != null && user.companyId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _productProviderInstance!.fetchData(user.companyId!);
          await _orderProviderInstance!.fetchOrderForTable(tableId: widget.tableId, companyId: user.companyId!);
        });
      }

      _searchController.addListener(() {
        _productProviderInstance!.setSearchText(_searchController.text);
      });

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Ekran kapatıldığında OrderProvider'ın state'ini temizleme çağrısı buradan kaldırıldı.
    // Bu işlem artık sadece belirli bir işlem (ödeme, taşıma) başarıyla tamamlandığında
    // veya uygulamanın daha üst seviyelerinde yönetilecek.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tableName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context), color: Colors.white),
          if (orderProvider.selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              onPressed: orderProvider.isLoading ? null : () => _showTransferDialog(context, orderProvider, user),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "# ARAMA YAP / BARKOD OKUT #",
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kategoriler",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryGrid(colorScheme, productProvider),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ürünler",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
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
                        : _buildProductList(colorScheme, textTheme, productProvider, orderProvider),
              ),
              const SizedBox(height: 24),

              // Mesaj kutuları tamamen kaldırıldı, SnackBar'lar kullanılacak
              
              _buildOrderSummaryAndButtons(colorScheme, textTheme, orderProvider, user),
            ],
          ),
        ),
      ),
    );
  }

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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5 / 1,
      ),
      itemCount: productProvider.categories.length,
      itemBuilder: (context, index) {
        final category = productProvider.categories[index];
        final isSelected = productProvider.selectedCategoryId == category.id;
        return GestureDetector(
          onTap: () {
            productProvider.setSelectedCategory(category.id);
            _searchController.clear();
          },
          child: Card(
            elevation: isSelected ? 6 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2.0 : 1,
              ),
            ),
            color: isSelected ? colorScheme.primary.withOpacity(0.15) : colorScheme.surfaceContainerHighest,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
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
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: productProvider.filteredProducts.length,
      itemBuilder: (_, index) {
        final product = productProvider.filteredProducts[index];
        final bool isProductSelected = orderProvider.selectedItems.any((item) => item.productId == product.id && item.status != 'completed');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: GestureDetector(
            onTap: () => orderProvider.addProduct(OrderItem(
              productId: product.id,
              name: product.name,
              price: product.price,
              quantity: 1,
              status: 'pending',
              note: null,
            )),
            child: Card(
              elevation: isProductSelected ? 6 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isProductSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                  width: isProductSelected ? 2.0 : 1,
                ),
              ),
              color: isProductSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
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
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            product.description.isNotEmpty ? product.description : "Açıklama yok",
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${product.price.toStringAsFixed(2)} ₺',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 14,
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

  // _buildResultMessage metodu tamamen kaldırıldı.


  Widget _buildSelectedItemsList(ColorScheme colorScheme, TextTheme textTheme, OrderProvider orderProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: orderProvider.selectedItems.length,
      itemBuilder: (context, index) {
        final item = orderProvider.selectedItems[index];
        final isItemCompleted = item.status == 'completed';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isItemCompleted ? colorScheme.surfaceContainerHighest.withOpacity(0.7) : colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: orderProvider.isItemSelectedForPayment(item),
                      onChanged: isItemCompleted ? null : (bool? value) {
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
                              color: isItemCompleted ? Colors.grey.shade600 : colorScheme.onSurface,
                              fontSize: 13,
                              decoration: isItemCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          Text(
                            "${item.price.toStringAsFixed(2)} ₺",
                            style: textTheme.bodyMedium?.copyWith(
                              color: isItemCompleted ? Colors.grey.shade500 : colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isItemCompleted)
                      IconButton(
                        icon: Icon(Icons.note_add_outlined, color: colorScheme.secondary, size: 20),
                        onPressed: () => _showAddNoteDialog(context, item, orderProvider),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: isItemCompleted ? Colors.grey : colorScheme.error, size: 20),
                          onPressed: isItemCompleted ? null : () => orderProvider.decreaseQty(item),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        Text(
                          item.quantity.toString(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isItemCompleted ? Colors.grey.shade600 : colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: isItemCompleted ? Colors.grey : colorScheme.primary, size: 20),
                          onPressed: isItemCompleted ? null : () => orderProvider.increaseQty(item),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: isItemCompleted ? Colors.grey : colorScheme.error, size: 20),
                          onPressed: isItemCompleted ? null : () => orderProvider.removeItem(item),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 36.0, top: 4.0),
                      child: Text(
                        "Not: ${item.note}",
                        style: textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, OrderItem item, OrderProvider orderProvider) {
    final TextEditingController noteController = TextEditingController(text: item.note);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ürüne Not Ekle: ${item.name}', style: textTheme.titleLarge),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: 'Notunuzu buraya yazın',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            maxLines: 3,
            minLines: 1,
            keyboardType: TextInputType.multiline,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () {
                orderProvider.updateItemNote(item, noteController.text.trim());
                Navigator.pop(context);
              },
              child: Text('Kaydet', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            ),
          ],
        );
      },
    );
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Toplam",
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${orderProvider.totalPrice.toStringAsFixed(2)} ₺",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ödenen",
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${orderProvider.totalPaidAmount.toStringAsFixed(2)} ₺",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kalan",
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${orderProvider.totalRemainingAmount.toStringAsFixed(2)} ₺",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              if (orderProvider.selectedItems.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Seçili Ürünler",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
                    child: _buildSelectedItemsList(colorScheme, textTheme, orderProvider),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: orderProvider.isLoading
                      ? null
                      : () {
                          final unpaidItems = orderProvider.selectedItems.where((item) => item.status != 'completed').toList();
                          if (unpaidItems.isEmpty && orderProvider.selectedItems.isNotEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tüm ürünler zaten ödendi. Hesap Al butonu ile tamamlayın.')),
                            );
                            return;
                          }
                          if (unpaidItems.isEmpty && orderProvider.selectedItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen sipariş için ürün seçin.')),
                            );
                            return;
                          }

                          orderProvider.submitOrder(
                            tableId: widget.tableId,
                            tableName: widget.tableName,
                            companyId: user?.companyId ?? '',
                            staffId: user?.uid ?? '',
                            
                            onSuccess: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sipariş "${widget.tableName}" masasına gönderildi!'),
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                              }
                            },
                            onError: (msg) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg), backgroundColor: colorScheme.error),
                                );
                              }
                            },
                          );
                        },
                  icon: orderProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    "Siparişi Gönder",
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: orderProvider.isLoading
                      ? null
                      : () {
                          final selectedItems = orderProvider.getSelectedItemsForPayment();
                          if (selectedItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen ödenecek ürünleri seçin')),
                            );
                            return;
                          }
                          _showPaymentDialog(selectedItems, colorScheme, textTheme, orderProvider);
                        },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    "Hesap Al",
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Hesap al butonu için farklı renk
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(List<OrderItem> selectedItems, ColorScheme colorScheme, TextTheme textTheme, OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (context) {
        final totalPaymentAmount = orderProvider.calculateTotalPrice(selectedItems);
        return AlertDialog(
          title: Text(
            'Ödeme Yöntemi Seçin',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seçili Ürünler:',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...selectedItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item.name} x${item.quantity} - ${(item.price * item.quantity).toStringAsFixed(2)} ₺',
                  style: textTheme.bodyMedium,
                ),
              )),
              const Divider(),
              Text(
                'Toplam Ödenecek: ${totalPaymentAmount.toStringAsFixed(2)} ₺',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment('Nakit', selectedItems, orderProvider);
              },
              child: Text('Nakit', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment('Kart', selectedItems, orderProvider);
              },
              child: Text('Kart', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment('Yemek Kartı', selectedItems, orderProvider);
              },
              child: Text('Yemek Kartı', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(String paymentMethod, List<OrderItem> selectedItems, OrderProvider orderProvider) async {
    try {
      await orderProvider.processPayment(paymentMethod, selectedItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme başarıyla tamamlandı (${paymentMethod})'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        if (orderProvider.totalRemainingAmount <= 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) { // Pop işlemini erteleyelim
            if (mounted) {
              Navigator.pop(context); // Sipariş ekranını kapat
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme işlemi sırasında hata oluştu: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  // MARK: - Masa Taşıma Diyalogları ve Fonksiyonları
  Future<void> _showTransferDialog(BuildContext context, OrderProvider orderProvider, AppUser? user) async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Taşınacak Ürünleri Seçin', style: textTheme.titleLarge),
          content: Consumer<OrderProvider>(
            builder: (context, provider, child) {
              final untransferredItems = provider.selectedItems.where((item) => item.status != 'completed').toList();
              if (untransferredItems.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text("Taşınacak ürün bulunmamaktadır.", style: textTheme.bodyLarge),
                  ),
                );
              }
              return SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.4,
                child: ListView.builder(
                  itemCount: untransferredItems.length,
                  itemBuilder: (context, index) {
                    final item = untransferredItems[index];
                    return CheckboxListTile(
                      title: Text(item.name, style: textTheme.titleMedium),
                      subtitle: Text('${item.quantity} adet - ${item.price.toStringAsFixed(2)} ₺', style: textTheme.bodyMedium),
                      value: provider.isItemSelectedForTransfer(item),
                      onChanged: (bool? value) {
                        provider.toggleItemSelectionForTransfer(item);
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('İptal', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
              onPressed: () {
                orderProvider.selectedItemsForTransfer.clear();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text('İleri', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
              onPressed: () {
                if (orderProvider.selectedItemsForTransfer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen taşınacak ürünleri seçin')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                _showTargetTableSelectionDialog(context, orderProvider, user);
              },
            ),
          ],
        );
      },
    );
  }
  
Future<void> _showTargetTableSelectionDialog(BuildContext context, OrderProvider orderProvider, AppUser? user) async {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  final TextTheme textTheme = Theme.of(context).textTheme;

  List<TableModel> availableTables = [];
  String? errorText;
  try {
    final tablesSnapshot = await FirebaseFirestore.instance
        .collection('tables')
        .where('companyId', isEqualTo: user?.companyId)
        .get();

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('companyId', isEqualTo: user?.companyId)
        .where('status', isEqualTo: 'pending')
        .get();

    final tablesWithOrders = ordersSnapshot.docs.map((doc) => doc['tableId'] as String).toSet();

    availableTables = tablesSnapshot.docs
        .map((doc) => TableModel.fromMap(doc.id, doc.data()))
        .where((table) => table.id != widget.tableId && !tablesWithOrders.contains(table.id))
        .toList();
  } catch (e) {
    errorText = "Masalar yüklenirken hata oluştu: $e";
  }

  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      if (errorText != null || availableTables.isEmpty) {
        return AlertDialog(
          title: Text('Hata', style: textTheme.titleLarge),
          content: Text(errorText ?? 'Taşınabilecek masa bulunamadı.', style: textTheme.bodyLarge),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Tamam', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
            ),
          ],
        );
      }

      return AlertDialog(
        title: Text('Hedef Masa Seçin', style: textTheme.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            itemCount: availableTables.length,
            itemBuilder: (_, index) {
              final table = availableTables[index];
              return ListTile(
                title: Text(table.name, style: textTheme.titleMedium),
                onTap: () async {
                  Navigator.of(dialogContext).pop();

                  try {
                    await orderProvider.transferItemsToTable(
                      sourceTableId: widget.tableId,
                      targetTableId: table.id,
                      companyId: user?.companyId ?? '',
                      staffId: user?.uid ?? '',
                      itemsToTransfer: orderProvider.selectedItemsForTransfer,
                      onSuccess: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Taşıma tamamlandı: ${table.name}'), backgroundColor: colorScheme.primary),
                          );

                          Future.delayed(Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          });
                        }
                      },
                      onError: (msg) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: colorScheme.error),
                          );
                        }
                      },
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('İşlem hatası: $e'), backgroundColor: colorScheme.error),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              orderProvider.selectedItemsForTransfer.clear();
              Navigator.of(dialogContext).pop();
            },
            child: Text('İptal', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
          ),
        ],
      );
    },
  );
}

}
