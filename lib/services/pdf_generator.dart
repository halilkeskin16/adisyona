import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/reports_provider.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateReport(ReportsProvider provider, String selectedReportType) async {
    final pdf = pw.Document();

    // PDF'te Türkçe karakterleri desteklemek için bir font ekliyoruz.
    // Projenizin assets klasörüne bir .ttf font dosyası (örneğin Google Fonts'tan NotoSans) ekleyin.
    // pubspec.yaml dosyasında da bu fontu tanımlamayı unutmayın.
    // fonts:
    //   - family: NotoSans
    //     fonts:
    //       - asset: assets/fonts/NotoSans-Regular.ttf
    //       - asset: assets/fonts/NotoSans-Bold.ttf
    //         weight: 700
    final font = await PdfGoogleFonts.notoSerifRegular();
    final boldFont = await PdfGoogleFonts.notoSerifBold();

    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    // Tarih aralığını belirleyelim
    String dateRangeText;
    if (provider.selectedDateFilter == 'daily') {
      dateRangeText = DateFormat('dd MMMM yyyy', 'tr_TR').format(provider.startDate);
    } else {
      dateRangeText =
          "${DateFormat('dd.MM.yyyy').format(provider.startDate)} - ${DateFormat('dd.MM.yyyy').format(provider.endDate)}";
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(context, dateRangeText),
          pw.SizedBox(height: 20),
          _buildTotalSales(context, provider),
          pw.SizedBox(height: 20),
          _buildReportContent(context, provider, selectedReportType),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context, String dateRangeText) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Satış Raporu', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
        pw.SizedBox(height: 8),
        pw.Text('Dönem: $dateRangeText'),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildTotalSales(pw.Context context, ReportsProvider provider) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Toplam Satış Tutarı:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.Text('${provider.totalSales.toStringAsFixed(2)} ₺',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.green700)),
        ],
      ),
    );
  }

  static pw.Widget _buildReportContent(pw.Context context, ReportsProvider provider, String selectedReportType) {
    switch (selectedReportType) {
      case 'staff':
        return _buildDataTable(
          context,
          'Personel Satışları',
          ['Personel Adı', 'Tutar'],
          provider.staffSales.entries.map((entry) {
            final name = provider.staffNames[entry.key] ?? entry.key;
            return [name, '${entry.value.toStringAsFixed(2)} ₺'];
          }).toList(),
        );
      case 'table':
        return _buildDataTable(
          context,
          'Masa Satışları',
          ['Masa Adı', 'Tutar'],
          provider.tableSales.entries.map((entry) {
            return [entry.key, '${entry.value.toStringAsFixed(2)} ₺'];
          }).toList(),
        );
      case 'product':
        return _buildDataTable(
          context,
          'Ürün Satışları',
          ['Ürün Adı', 'Tutar'],
          provider.productSalesAmount.entries.map((entry) {
            final name = provider.productNames[entry.key] ?? entry.key;
            return [name, '${entry.value.toStringAsFixed(2)} ₺'];
          }).toList(),
        );
      case 'total':
      default:
        return pw.Center(
          child: pw.Text('Genel toplam raporu yukarıda özetlenmiştir.', style: const pw.TextStyle(fontSize: 14)),
        );
    }
  }

  static pw.Widget _buildDataTable(pw.Context context, String title, List<String> headers, List<List<String>> data) {
    if (data.isEmpty) {
      return pw.Center(child: pw.Text('$title için veri bulunamadı.'));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 10),
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
          },
        ),
      ],
    );
  }
}