import 'package:adisyona/views/dashboard/admin_dashboard.dart';
import 'package:adisyona/views/kitchen/kitchen_screen.dart';
import 'package:adisyona/views/order/order_table_selection_screen.dart';
import 'package:adisyona/views/personel/personel_managment_screen.dart';
import 'package:adisyona/views/reports/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // Mevcut AuthProvider'ınızın yolu
import 'product_management_view.dart'; // Ürün ve Kategori yönetimi ekranı
import '../auth/login_view.dart'; // LoginView'ı import ediyoruz

class AdminDashboardMenu extends StatefulWidget {
  const AdminDashboardMenu({super.key});

  @override
  State<AdminDashboardMenu> createState() => _AdminDashboardMenuState();
}

class _AdminDashboardMenuState extends State<AdminDashboardMenu> {
  // Menü öğelerini tanımlayan yardımcı sınıf


  // Çıkış onay diyaloğunu gösteren metod
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final ColorScheme color = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamaz
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Çıkış Onayı',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color.onSurface),
          ),
          content: Text(
            'Uygulamadan çıkış yapmak istediğinize emin misiniz?',
            style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.8)),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: <Widget>[
            TextButton(
              child: Text(
                'İptal',
                style: textTheme.labelLarge?.copyWith(color: color.primary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Diyaloğu kapat
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.error, // Hata rengiyle uyumlu buton
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Diyaloğu kapat
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout(); // Çıkış işlemini yap
                // Giriş ekranına MaterialPageRoute ile geri dön
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                );
              },
              child: Text(
                'Çıkış Yap',
                style: textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme color = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // AuthProvider'dan kullanıcı rolünü dinle
    final authProvider = Provider.of<AuthProvider>(context);
    final String userRole = authProvider.user?.role ?? 'guest'; // Kullanıcı rolünü al, yoksa 'guest'

    // Tüm menü öğeleri listesi
    final List<_MenuItem> allItems = [
      _MenuItem(
        title: 'Bölge & Masa',
        icon: Icons.chair_alt_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        ),
        requiredRole: 'admin', // Sadece adminler görebilir
      ),
      _MenuItem(
        title: 'Ürün & Kategori',
        icon: Icons.fastfood_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductManagementView()),
        ),
        requiredRole: 'admin', // Sadece adminler görebilir
      ),
      _MenuItem(
        title: 'Sipariş Al',
        icon: Icons.receipt_long,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderTableSelectionScreen()),
        ),
        requiredRole: 'all', // Admin ve Garson görebilir (veya 'garson' olarak kısıtlayabilirsiniz)
      ),
      _MenuItem(
        title: 'Mutfak',
        icon: Icons.kitchen_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const KitchenScreen(),
            ),
          );
        },
        requiredRole: 'all', // Admin ve Garson görebilir (veya 'garson' olarak kısıtlayabilirsiniz)
      ),
      _MenuItem(
        title: 'Personel Yönetimi',
        icon: Icons.people_alt_outlined,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen()));
        },
        requiredRole: 'admin', // Sadece adminler görebilir
      ),
      // İstatistik ve Raporlama (Admin Paneli)
      _MenuItem(
        title: 'Raporlar',
        icon: Icons.bar_chart,
        onTap: () {
          // Raporlama ekranına yönlendirme
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()), // Raporlama ekranı için uygun widget'ı kullanın
          );
        },
        requiredRole: 'admin',
      ),
    ];

    // Kullanıcının rolüne göre filtrelenmiş menü öğeleri
    final List<_MenuItem> filteredItems = allItems.where((item) {
      if (item.requiredRole == 'all') return true;
      return item.requiredRole == userRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Yönetim Paneli",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: color.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutConfirmationDialog(context), // Onay diyaloğunu çağır
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24), // Daha fazla padding
        child: GridView.builder(
          itemCount: filteredItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 sütun
            crossAxisSpacing: 18, // Daha fazla yatay boşluk
            mainAxisSpacing: 18, // Daha fazla dikey boşluk
            childAspectRatio: 1.1, // Öğelerin en/boy oranını ayarla
          ),
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(20), // Daha yuvarlak köşeler
              child: Card( // Kart bileşeni ile daha modern görünüm
                elevation: 8, // Kart gölgesi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: color.surface, // Kartın arka plan rengi
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 55, color: color.primary), // İkon boyutu
                    const SizedBox(height: 16), // Boşluk
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurface,
                        fontSize: 16, // Font boyutu
                      ),
                    ),
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
    final String requiredRole; // 'admin', 'garson', 'all' gibi roller

    _MenuItem({
      required this.title,
      required this.icon,
      required this.onTap,
      this.requiredRole = 'all', // Varsayılan olarak tüm roller görebilir
    });
  }