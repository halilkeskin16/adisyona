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

  // Siparişin mutfakta tamamlandığını işaretler (ana durumu 'pending' olarak bırakır)
  Future<void> _markOrderKitchenCompleted(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'kitchenCompletedAt': FieldValue.serverTimestamp(), // Mutfak tamamlanma zamanı
        'isReadyForService': true, // Mutfakta servise hazır işaretle
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş mutfakta hazırlandı ve servise verildi!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      print("Mutfak durumu güncellenirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: Mutfak durumu güncellenemedi."),
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
          item.uniqueId == itemToUpdate.uniqueId); // uniqueId üzerinden bul

      if (itemIndex != -1) {
        // OrderItem'ın status alanının final olmaması gerekiyor
        currentItems[itemIndex] = OrderItem(
          uniqueId: currentItems[itemIndex].uniqueId,
          productId: currentItems[itemIndex].productId,
          name: currentItems[itemIndex].name,
          price: currentItems[itemIndex].price,
          quantity: currentItems[itemIndex].quantity,
          status: newStatus,
          note: currentItems[itemIndex].note, // Notu koru
        );
      } else {
        print("Hata: Güncellenecek ürün sipariş listesinde bulunamadı.");
        return;
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'items': currentItems.map((e) => e.toMap()).toList(),
      });
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
              .where('status', isEqualTo: 'pending') // Ana durumu 'pending' olmalı
              .where('isReadyForService', isEqualTo: false) // Sadece mutfakta henüz hazır olmayanları göster
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
                            // Masa isminin taşmasını engellemek için Expanded kullanıldı
                            Expanded(
                              child: Text(
                                "🪑 Masa: ${order.tableName}",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis, // Metin taşarsa üç nokta göster
                                maxLines: 1, // Tek satırda kalmasını sağla
                              ),
                            ),
                            const SizedBox(width: 8), // Masa adı ile zaman arasında boşluk
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
                        ...order.items.where((item) => item.status != 'ready').map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column( // Ürün ve notu için Column
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
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
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.done,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _updateOrderItemStatus(
                                        order.id,
                                        item,
                                        'ready',
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.note != null && item.note!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 34.0, top: 4.0), // İkon ve metinle hizala
                                    child: Text(
                                      "Not: ${item.note}",
                                      style: textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            // Mutfak onayını _markOrderKitchenCompleted ile yapıyoruz
                            onPressed: allItemsReady
                                ? () => _markOrderKitchenCompleted(order.id)
                                : null,
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: Text(
                              allItemsReady ? "Siparişi Mutfakta Tamamla" : "Tüm Ürünler Hazır Değil",
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
