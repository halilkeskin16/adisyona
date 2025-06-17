import 'package:adisyona/views/order/order_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/area_model.dart';
import '../../models/table_model.dart';
import '../../providers/auth_provider.dart';

class OrderTableSelectionScreen extends StatefulWidget {
  const OrderTableSelectionScreen({super.key});

  @override
  State<OrderTableSelectionScreen> createState() => _OrderTableSelectionScreenState();
}

class _OrderTableSelectionScreenState extends State<OrderTableSelectionScreen> {
  List<Area> _areas = [];
  List<TableModel> _tables = [];
  String _selectedAreaId = 'all';
  Map<String, double> _tableOrders = {}; // Masa ID'si -> Toplam Sipariş Tutarı

  @override
  void initState() {
    super.initState();
    _loadAreasAndTables();
  }

  Future<void> _loadAreasAndTables() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.companyId == null) return;

    try {
      final areaSnap = await FirebaseFirestore.instance
          .collection('areas')
          .where('companyId', isEqualTo: user.companyId)
          .get();

      final tableSnap = await FirebaseFirestore.instance
          .collection('tables')
          .where('companyId', isEqualTo: user.companyId)
          .get();

      // Aktif siparişleri yükle
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('companyId', isEqualTo: user.companyId)
          .where('status', whereIn: ['pending', 'preparing', 'ready'])
          .get();

      // Her masa için toplam sipariş tutarını hesapla
      Map<String, double> tableOrders = {};
      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        final tableId = data['tableId'] as String;
        // totalAmount null olabilir, bu durumda items'dan hesapla
        double totalAmount = 0.0;
        if (data['totalAmount'] != null) {
          totalAmount = (data['totalAmount'] as num).toDouble();
        } else if (data['items'] != null) {
          // Eğer totalAmount yoksa items'dan hesapla
          final items = data['items'] as List;
          totalAmount = items.fold(0.0, (sum, item) {
            final price = (item['price'] as num).toDouble();
            final quantity = (item['quantity'] as num).toInt();
            return sum + (price * quantity);
          });
        }
        tableOrders[tableId] = (tableOrders[tableId] ?? 0) + totalAmount;
      }

      setState(() {
        _areas = areaSnap.docs.map((doc) => Area.fromMap(doc.id, doc.data())).toList();
        _tables = tableSnap.docs.map((doc) => TableModel.fromMap(doc.id, doc.data())).toList();
        _tableOrders = tableOrders;
      });
    } catch (e) {
      debugPrint('Hata: $e');
    }
  }

  List<TableModel> get _filteredTables {
    if (_selectedAreaId == 'all') return _tables;
    return _tables.where((t) => t.areaId == _selectedAreaId).toList();
  }

  Color _getTableColor(String tableId) {
    if (_tableOrders.containsKey(tableId)) {
      // Sipariş varsa kırmızı tonları
      return Colors.red.shade100;
    }
    // Sipariş yoksa yeşil tonları
    return Colors.green.shade100;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sipariş – Masa Seçimi"),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bölge Seçimi Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAreaId,
              decoration: const InputDecoration(labelText: 'Bölge Seç'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Tüm Bölgeler')),
                ..._areas.map((area) => DropdownMenuItem(value: area.id, child: Text(area.name))),
              ],
              onChanged: (value) {
                setState(() => _selectedAreaId = value ?? 'all');
              },
            ),
            const SizedBox(height: 20),

            // Masa Listesi Grid
            Expanded(
              child: GridView.builder(
                itemCount: _filteredTables.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final table = _filteredTables[index];
                  final areaName = _areas.firstWhere((a) => a.id == table.areaId, orElse: () => Area(id: '', name: '', companyId: '')).name;
                  final hasOrder = _tableOrders.containsKey(table.id);
                  final orderAmount = _tableOrders[table.id] ?? 0.0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => OrderFormScreen(tableId: table.id, tableName: table.name),
                      )).then((_) => _loadAreasAndTables()); // Geri dönüşte masaları yenile
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: _getTableColor(table.id),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasOrder ? Icons.table_restaurant : Icons.table_bar,
                              size: 40,
                              color: hasOrder ? Colors.red.shade700 : Colors.green.shade700,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              table.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasOrder ? Colors.red.shade900 : Colors.green.shade900,
                              ),
                            ),
                            Text(
                              areaName,
                              style: textTheme.bodySmall?.copyWith(
                                color: hasOrder ? Colors.red.shade900 : Colors.green.shade900,
                              ),
                            ),
                            if (hasOrder) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${orderAmount.toStringAsFixed(2)} ₺',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
