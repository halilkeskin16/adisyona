import 'package:adisyona/views/dashboard/admin_dashboard.dart';
import 'package:adisyona/views/order/order_table_selection_screen.dart';
import 'package:flutter/material.dart';
import 'product_management_view.dart';

class AdminDashboardMenu extends StatelessWidget {
  const AdminDashboardMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme color = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final List<_MenuItem> items = [
      _MenuItem(
        title: 'Bölge & Masa',
        icon: Icons.chair_alt_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        ),
      ),
      _MenuItem(
        title: 'Ürün & Kategori',
        icon: Icons.fastfood_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductManagementView()),
        ),
      ),
      _MenuItem(title: 'Sipariş', icon: Icons.receipt_long, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderTableSelectionScreen()))),
      // Gelecekte başka butonlar da ekleyebilirsin (örneğin raporlar, garson ekleme vs)
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yönetim Paneli"),
        centerTitle: true,
        backgroundColor: color.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 sütun
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: color.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.outline.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 48, color: color.primary),
                    const SizedBox(height: 12),
                    Text(item.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItem({required this.title, required this.icon, required this.onTap});
}
