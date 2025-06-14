import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/order_model.dart'; // OrderModel ve OrderItem'ı buradan alıyoruz!
import '../../providers/auth_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  String? _companyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyId();
    });
  }

  Future<void> _loadCompanyId() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null && user.companyId != null) {
      setState(() {
        _companyId = user.companyId;
      });
    } else {
      print("Mutfak Ekranı: Kullanıcı veya şirket ID'si bulunamadı.");
      // Kullanıcıya bilgi verebilir veya giriş ekranına yönlendirebilirsiniz
    }
  }

  // Siparişin ana durumunu güncelleme (örn: completed)
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'ready',
        'kitchenCompletedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş hazırlandı ve masaya gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Sipariş durumu güncellenirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: Sipariş durumu güncellenemedi."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Sipariş öğesinin (ürünün) durumunu güncelleme (ürün bazlı onaylama)
  Future<void> _updateOrderItemStatus(String orderId, OrderItem itemToUpdate, String newStatus) async {
    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data() as Map<String, dynamic>;
      List<OrderItem> currentItems = (orderData['items'] as List)
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList();

      final itemIndex = currentItems.indexWhere((item) =>
          item.productId == itemToUpdate.productId && item.quantity == itemToUpdate.quantity && item.name == itemToUpdate.name);

      if (itemIndex != -1) {
        currentItems[itemIndex] = OrderItem(
          productId: currentItems[itemIndex].productId,
          name: currentItems[itemIndex].name,
          price: currentItems[itemIndex].price,
          quantity: currentItems[itemIndex].quantity,
          status: newStatus,
        );

        // Tüm ürünler hazır olduğunda siparişin durumunu 'ready' olarak güncelle
        final allItemsReady = currentItems.every((item) => item.status == 'ready');
        if (allItemsReady) {
          await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
            'items': currentItems.map((e) => e.toMap()).toList(),
            'status': 'ready',
            'kitchenCompletedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
            'items': currentItems.map((e) => e.toMap()).toList(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${itemToUpdate.name} hazırlandı!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("Hata: Güncellenecek ürün sipariş listesinde bulunamadı.");
        return;
      }
    } catch (e) {
      print("Sipariş öğesi durumu güncellenirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: Ürün durumu güncellenemedi."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_companyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mutfak Ekranı"),
          backgroundColor: colorScheme.primary,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mutfak Ekranı",
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('companyId', isEqualTo: _companyId)
              .where('status', whereIn: ['pending', 'preparing']) // Sadece hazırlanmayı bekleyen siparişleri göster
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: colorScheme.primary));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Siparişler yüklenirken hata oluştu: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "Şu anda hazırlanmayı bekleyen sipariş yok. 🧑‍🍳",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                ),
              );
            }

            final orders = snapshot.data!.docs.map((doc) {
              return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                final allItemsReady = order.items.every((item) => item.status == 'ready');
                // isOrderPending ve isOrderPreparing kaldırıldı çünkü artık tek bir 'pending' durumu var.

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "🪑 Masa: ${order.tableName}",
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              "⏱️ ${timeago.format(order.createdAt?.toDate() ?? DateTime.now(), locale: 'tr')}",
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1),
                        // Sipariş öğeleri
                        ...order.items.where((item) => item.status != 'ready').map((item) { // Sadece hazır olmayanları göster
                          final isItemReady = item.status == 'ready'; // Bu kontrol burada mantıksızlaşıyor çünkü zaten hazır olmayanları filtreledik.
                                                                    // Ancak kod tutarlılığı için bırakılabilir veya kaldırılabilir.
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  // Artık sadece hazır olmayanları gösterdiğimiz için hep radio_button_unchecked olacak
                                  Icons.radio_button_unchecked,
                                  color: colorScheme.primary.withOpacity(0.7),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "${item.name} x${item.quantity}",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                      // decoration kaldırıldı çünkü hazır olmayanları gösteriyoruz
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon( // Sadece 'onayla' butonu olacak
                                    Icons.done,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _updateOrderItemStatus(
                                    order.id,
                                    item,
                                    'ready', // Direkt 'ready' durumuna geçiş
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        // Eğer hiç ürün kalmadıysa (hepsi hazırlandıysa), "Tüm Ürünler Hazır" mesajı gösterilebilir
                        if (order.items.every((item) => item.status == 'ready'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Center(
                              child: Text(
                                "Tüm ürünler hazır! ✅",
                                style: textTheme.bodyLarge?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Siparişi Tamamla butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: allItemsReady // Tüm öğeler hazırsa butonu etkinleştir
                                ? () => _updateOrderStatus(order.id, 'completed')
                                : null, // Değilse devre dışı bırak
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: Text(
                              allItemsReady ? "Siparişi Tamamla" : "Tüm Ürünler Hazır Değil",
                              style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allItemsReady ? Colors.green : colorScheme.onSurface.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
