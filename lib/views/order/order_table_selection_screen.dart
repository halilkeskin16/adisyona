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

      setState(() {
        _areas = areaSnap.docs.map((doc) => Area.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
        _tables = tableSnap.docs.map((doc) => TableModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      debugPrint('Hata: $e');
    }
  }

  List<TableModel> get _filteredTables {
    if (_selectedAreaId == 'all') return _tables;
    return _tables.where((t) => t.areaId == _selectedAreaId).toList();
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
                  crossAxisCount: 2, // 2'li grid
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final table = _filteredTables[index];
                  final areaName = _areas.firstWhere((a) => a.id == table.areaId, orElse: () => Area(id: '', name: '' , companyId: '')).name;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => OrderFormScreen(tableId: table.id, tableName: table.name),
                      ));
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: colorScheme.surfaceVariant,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_bar, size: 40, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              table.name,
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(areaName, style: textTheme.bodySmall),
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
