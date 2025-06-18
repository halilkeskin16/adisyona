// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // Timer için bu import gerekli

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/order_model.dart'; // OrderModel ve OrderItem'ı buradan alıyoruz!
import '../../providers/auth_provider.dart';

// ANA EKRAN WIDGET'I
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
      if (mounted) {
        setState(() {
          _companyId = user.companyId;
        });
      }
    }
  }

  Future<void> _markOrderKitchenCompleted(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'kitchenCompletedAt': FieldValue.serverTimestamp(),
        'isReadyForService': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sipariş mutfakta hazırlandı ve servise verildi!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Hata: Mutfak durumu güncellenemedi."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateOrderItemStatus(
      String orderId, OrderItem itemToUpdate, String newStatus) async {
    try {
      final orderDocRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
      final orderDoc = await orderDocRef.get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data() as Map<String, dynamic>;
      List<OrderItem> currentItems = (orderData['items'] as List)
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList();

      final itemIndex = currentItems
          .indexWhere((item) => item.uniqueId == itemToUpdate.uniqueId);

      if (itemIndex != -1) {
        currentItems[itemIndex] = currentItems[itemIndex].copyWith(status: newStatus);
      } else {
        return;
      }

      await orderDocRef.update({
        'items': currentItems.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Hata: Ürün durumu güncellenemedi."),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('companyId', isEqualTo: _companyId)
              .where('status', isEqualTo: 'pending')
              .where('isReadyForService', isEqualTo: false)
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
                  style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              );
            }

            final orders = snapshot.data!.docs.map((doc) {
              return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                // Her bir sipariş için kendi kendini güncelleyen OrderCard widget'ını kullanıyoruz
                return OrderCard(
                  order: order,
                  onCompleteOrder: _markOrderKitchenCompleted,
                  onUpdateItem: _updateOrderItemStatus,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KENDİ KENDİNİ GÜNCELLEYEN SİPARİŞ KARTI WIDGET'I
// -----------------------------------------------------------------------------

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final Function(String orderId) onCompleteOrder;
  final Function(String orderId, OrderItem item, String newStatus) onUpdateItem;

  const OrderCard({
    super.key,
    required this.order,
    required this.onCompleteOrder,
    required this.onUpdateItem,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Widget oluşturulduğunda bir zamanlayıcı başlat.
    // Bu zamanlayıcı her dakika başı setState çağırarak sürenin güncellenmesini sağlar.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Widget ekrandan kaldırıldığında zamanlayıcıyı mutlaka iptal et.
    // Bu, hafıza sızıntılarını (memory leak) önler.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final order = widget.order;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "🪑 Masa: ${order.tableName}",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Her yeniden çizimde bu fonksiyon tekrar çağrılır ve güncel süreyi hesaplar.
                Text(
                  "⏱️ ${timeago.format(order.createdAt?.toDate() ?? DateTime.now(), locale: 'tr')}",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            // Henüz hazır olmayan ürünleri listele
            ...order.items.where((item) => item.status != 'ready').map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.radio_button_unchecked, color: colorScheme.secondary, size: 22),
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
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          tooltip: "Bu ürünü hazır olarak işaretle",
                          onPressed: () => widget.onUpdateItem(order.id, item, 'ready'),
                        ),
                      ],
                    ),
                    if (item.note != null && item.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 34.0, top: 2.0),
                        child: Text(
                          "Not: ${item.note}",
                          style: textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            // Eğer tüm ürünler hazırlandıysa bir mesaj göster
            if (order.items.isNotEmpty && allItemsReady)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    "Tüm ürünler servise hazır! ✅",
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
                onPressed: allItemsReady ? () => widget.onCompleteOrder(order.id) : null,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  allItemsReady ? "Siparişi Mutfakta Tamamla" : "Tüm Ürünler Hazır Değil",
                  style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allItemsReady ? Colors.green : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade300,
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
  }
}