// lib/views/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart'; // AuthProvider'ınızın yolu
import '../../providers/reports_provider.dart'; // Yeni ReportsProvider

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Rapor türü seçimi artık Dropdown tarafından kontrol ediliyor, bu yüzden _selectedReportType yerel state olarak kalır
  // 'total' kaldırıldığı için varsayılanı 'staff' olarak değiştirildi.
  String _selectedReportType = 'staff'; // 'staff', 'table', 'product'
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

      if (user != null && user.companyId != null) {
        await reportsProvider.fetchUserNames(user.companyId!);
        await reportsProvider.fetchProductNames(user.companyId!);
        reportsProvider.updateDateRange('daily'); // Varsayılan olarak günlük raporları yükle
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raporlar yüklenemedi: Şirket bilgisi eksik.')),
        );
      }
    });
  }

  String _getDateRangeText(ReportsProvider reportsProvider) {
    if (reportsProvider.selectedDateFilter == 'daily') {
      return DateFormat('dd MMMMEEEE').format(reportsProvider.startDate);
    } else if (reportsProvider.selectedDateFilter == 'weekly') {
      return "${DateFormat('dd MMMM').format(reportsProvider.startDate)} - ${DateFormat('dd MMMMEEEE').format(reportsProvider.endDate)}";
    } else if (reportsProvider.selectedDateFilter == 'monthly') {
      return DateFormat('MMMM yyyy').format(reportsProvider.startDate); // Yılı da dahil et
    } else { // 'custom'
      return "${DateFormat('dd.MM.yyyy').format(reportsProvider.startDate)} - ${DateFormat('dd.MM.yyyy').format(reportsProvider.endDate)}";
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context, ReportsProvider reportsProvider) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: reportsProvider.selectedDateFilter == 'custom' ? reportsProvider.startDate : DateTime.now(),
        end: reportsProvider.selectedDateFilter == 'custom' ? reportsProvider.endDate : DateTime.now().add(const Duration(days: 7)),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      final customEndDateTime = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59, 999);
      reportsProvider.updateDateRange('custom', customStart: pickedRange.start, customEnd: customEndDateTime);
    }
  }


  @override
  Widget build(BuildContext context) {
    final ColorScheme color = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final reportsProvider = Provider.of<ReportsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Raporlar",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: color.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: color.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // Tüm içeriği kaydırılabilir yap
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dönem Seçimi Dropdown'ı
              Text(
                "Dönem Seçimi",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              _buildDateFilterDropdown(color, textTheme, reportsProvider),
              const SizedBox(height: 12),
              // Özel tarih aralığı seçici buton (sadece 'custom' seçiliyse Dropdown altında belirir)
              if (reportsProvider.selectedDateFilter == 'custom')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: reportsProvider.isLoading ? null : () => _pickCustomDateRange(context, reportsProvider),
                    icon: Icon(Icons.calendar_today, color: color.primary),
                    label: Text(
                      _getDateRangeText(reportsProvider),
                      style: textTheme.bodyLarge?.copyWith(color: color.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Yükleme Durumu veya Hata Mesajı
              if (reportsProvider.isLoading)
                Center(child: CircularProgressIndicator(color: color.primary))
              else if (reportsProvider.message != null && reportsProvider.message!.isNotEmpty)
                Center(child: Text(reportsProvider.message!, style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7))))
              else
                const SizedBox.shrink(),
              const SizedBox(height: 16),

              // Toplam Satışlar Kartı
              _buildTotalSalesCard(color, textTheme, reportsProvider),
              const SizedBox(height: 24),

              // Rapor Türü Seçimi Dropdown'ı
              Text(
                "Rapor Türü",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              _buildReportTypeDropdown(color, textTheme, reportsProvider),
              const SizedBox(height: 24),

              // Filtrelenmiş rapor türüne göre listeyi göster
              // Expanded widget'ı kaldırıldı, çünkü ana Column zaten SingleChildScrollView içinde.
              // ListView.builder'lar shrinkWrap: true ve NeverScrollableScrollPhysics() ile kendi içeriklerine göre boyutlanacak.
              _buildReportContent(color, textTheme, reportsProvider),
            ],
          ),
        ),
      ),
    );
  }

  // Yeni: Tarih Filtreleme Dropdown'ı
  Widget _buildDateFilterDropdown(ColorScheme color, TextTheme textTheme, ReportsProvider reportsProvider) {
    return DropdownButtonFormField<String>(
      value: reportsProvider.selectedDateFilter,
      decoration: InputDecoration(
        labelText: "Dönem Seçin",
        labelStyle: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: color.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // İç padding
      ),
      items: const [
        DropdownMenuItem(value: 'daily', child: Text('Günlük')),
        DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
        DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
        DropdownMenuItem(value: 'custom', child: Text('Özel Aralık')),
      ],
      onChanged: (value) {
        if (value != null && reportsProvider.selectedDateFilter != value) {
          final user = Provider.of<AuthProvider>(context, listen: false).user; // AuthProvider'dan user al
          if (user != null && user.companyId != null) {
            reportsProvider.updateDateRange(value, 
              customStart: reportsProvider.startDate, // Mevcut tarihleri koru
              customEnd: reportsProvider.endDate,
            );
            // fetchReports updateDateRange içinde çağrılıyor
            reportsProvider.fetchReports(user.companyId!); // Tarih filtresi değişince raporları yeniden çek
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Raporlar yüklenemedi: Şirket bilgisi eksik.')),
            );
          }
        }
      },
      style: textTheme.bodyLarge?.copyWith(color: color.onSurface),
      dropdownColor: color.surface,
      isExpanded: true, // Genişletmek için
    );
  }

  Widget _buildReportTypeDropdown(ColorScheme color, TextTheme textTheme, ReportsProvider reportsProvider) {
    return DropdownButtonFormField<String>(
      value: _selectedReportType,
      decoration: InputDecoration(
        labelText: "Rapor Türü Seçin",
        labelStyle: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: color.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // İç padding
      ),
      items: const [
        // 'total' kaldırıldı
        DropdownMenuItem(value: 'staff', child: Text('Personel Satışları')),
        DropdownMenuItem(value: 'table', child: Text('Masa Satışları')),
        DropdownMenuItem(value: 'product', child: Text('Ürün Satışları')),
      ],
      onChanged: (value) {
        if (value != null && _selectedReportType != value) {
          setState(() {
            _selectedReportType = value;
          });
        }
      },
      style: textTheme.bodyLarge?.copyWith(color: color.onSurface),
      dropdownColor: color.surface,
      isExpanded: true,
    );
  }

  // Yeniden Faktörlendi: Toplam Satışlar Kartı
  Widget _buildTotalSalesCard(ColorScheme color, TextTheme textTheme, ReportsProvider reportsProvider) {
    return Card(
      elevation: 6,
      shadowColor: color.primary.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.bar_chart, size: 40, color: color.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toplam Satış",
                  style: textTheme.titleMedium?.copyWith(
                    color: color.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${reportsProvider.totalSales.toStringAsFixed(2)} ₺",
                  style: textTheme.headlineSmall?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  _getDateRangeText(reportsProvider),
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rapor içeriğini seçili türe göre gösterir
  Widget _buildReportContent(ColorScheme color, TextTheme textTheme, ReportsProvider reportsProvider) {
    if (reportsProvider.isLoading) {
      return Center(child: CircularProgressIndicator(color: color.primary));
    }
    // Eğer mesaj var ve rapor tiplerinin listesi boşsa mesajı göster
    if (reportsProvider.message != null && reportsProvider.message!.isNotEmpty &&
        reportsProvider.staffSales.isEmpty && reportsProvider.tableSales.isEmpty && reportsProvider.productSalesAmount.isEmpty) {
      return Center(child: Text(reportsProvider.message!, style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7))));
    }

    // 'total' seçeneği kaldırıldığı için, varsayılan olarak 'staff' veya boş bir SizedBox.shrink() döndürülebilir
    // Eğer reportsProvider.totalSales hala gösteriliyorsa, 'total' case'i kaldırılabilir.
    // Şimdilik 'total' case'i kaldırılıyor ve direkt 'staff' ya da boş dönüyoruz.
    // if (_selectedReportType == 'total') {
    //   return Center(
    //     child: Text(
    //       "Genel toplam yukarıdaki kartta gösterilmektedir.",
    //       style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7)),
    //     ),
    //   );
    // } 
    
    if (_selectedReportType == 'staff') {
      if (reportsProvider.staffSales.isEmpty) {
        return Center(child: Text("Personel satış verisi bulunamadı.", style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7))));
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reportsProvider.staffSales.keys.length,
        itemBuilder: (context, index) {
          String staffId = reportsProvider.staffSales.keys.elementAt(index);
          double sales = reportsProvider.staffSales[staffId]!;
          String staffName = reportsProvider.staffNames[staffId] ?? staffId;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            color: color.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.person, color: color.primary),
              title: Text(staffName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              trailing: Text("${sales.toStringAsFixed(2)} ₺", style: textTheme.titleMedium?.copyWith(color: color.secondary, fontWeight: FontWeight.bold)),
            ),
          );
        },
      );
    } else if (_selectedReportType == 'table') {
      if (reportsProvider.tableSales.isEmpty) {
        return Center(child: Text("Masa satış verisi bulunamadı.", style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7))));
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reportsProvider.tableSales.keys.length,
        itemBuilder: (context, index) {
          String tableName = reportsProvider.tableSales.keys.elementAt(index);
          double sales = reportsProvider.tableSales[tableName]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            color: color.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.table_bar, color: color.primary),
              title: Text(tableName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              trailing: Text("${sales.toStringAsFixed(2)} ₺", style: textTheme.titleMedium?.copyWith(color: color.secondary, fontWeight: FontWeight.bold)),
            ),
          );
        },
      );
    } else if (_selectedReportType == 'product') {
      if (reportsProvider.productSalesAmount.isEmpty) {
        return Center(child: Text("Ürün satış verisi bulunamadı.", style: textTheme.bodyLarge?.copyWith(color: color.onSurface.withOpacity(0.7))));
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reportsProvider.productSalesAmount.keys.length,
        itemBuilder: (context, index) {
          String productId = reportsProvider.productSalesAmount.keys.elementAt(index);
          double amount = reportsProvider.productSalesAmount[productId]!;
          int quantity = reportsProvider.productSalesQuantity[productId]!;
          String productName = reportsProvider.productNames[productId] ?? productId;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 2,
            color: color.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.fastfood, color: color.primary),
              title: Text(productName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text("${quantity} adet", style: textTheme.bodySmall?.copyWith(color: color.onSurface.withOpacity(0.7))),
              trailing: Text("${amount.toStringAsFixed(2)} ₺", style: textTheme.titleMedium?.copyWith(color: color.secondary, fontWeight: FontWeight.bold)),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
