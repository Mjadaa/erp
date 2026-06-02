import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_models.dart';

Future<void> printSalesInvoice(SalesInvoice invoice) async {
  final regularFont = await PdfGoogleFonts.cairoRegular();
  final boldFont = await PdfGoogleFonts.cairoBold();
  final fmt = NumberFormat('#,##0.##');

  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      textDirection: pw.TextDirection.rtl,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(invoice.invoiceNumber,
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColors.blue800)),
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.date,
                      style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 11,
                          color: PdfColors.grey600)),
                ],
              ),
              pw.Text('فاتورة مبيعات',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 26,
                      color: PdfColors.blue900)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200, thickness: 2),
          pw.SizedBox(height: 12),

          // ── Customer + Status ───────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('العميل:',
                      style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 10,
                          color: PdfColors.grey600)),
                  pw.Text(invoice.customerName ?? '-',
                      style:
                          pw.TextStyle(font: boldFont, fontSize: 14)),
                ],
              ),
              _statusBadge(invoice.status, boldFont),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Items table ─────────────────────────────────────────────────
          pw.Container(
            color: PdfColors.blue800,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 7),
            child: pw.Row(
              children: [
                pw.Expanded(
                    flex: 4,
                    child: pw.Text('المنتج',
                        style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.white,
                            fontSize: 10))),
                pw.SizedBox(
                    width: 44,
                    child: pw.Text('الكمية',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.white,
                            fontSize: 10))),
                pw.SizedBox(
                    width: 70,
                    child: pw.Text('سعر الوحدة',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.white,
                            fontSize: 10))),
                pw.SizedBox(
                    width: 44,
                    child: pw.Text('خصم%',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.white,
                            fontSize: 10))),
                pw.SizedBox(
                    width: 70,
                    child: pw.Text('الإجمالي',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.white,
                            fontSize: 10))),
              ],
            ),
          ),
          ...invoice.items.asMap().entries.map((e) {
            final item = e.value;
            final bg =
                e.key.isEven ? PdfColors.grey100 : PdfColors.white;
            return pw.Container(
              color: bg,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              child: pw.Row(
                children: [
                  pw.Expanded(
                      flex: 4,
                      child: pw.Text(item.productName,
                          style: pw.TextStyle(
                              font: regularFont, fontSize: 11))),
                  pw.SizedBox(
                      width: 44,
                      child: pw.Text('${item.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              font: regularFont, fontSize: 11))),
                  pw.SizedBox(
                      width: 70,
                      child: pw.Text(fmt.format(item.unitPrice),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              font: regularFont, fontSize: 11))),
                  pw.SizedBox(
                      width: 44,
                      child: pw.Text(
                          '${item.discount.toStringAsFixed(0)}%',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 11,
                              color: PdfColors.grey600))),
                  pw.SizedBox(
                      width: 70,
                      child: pw.Text(fmt.format(item.total),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 11,
                              color: PdfColors.blue800))),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),

          // ── Totals ──────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 240,
                child: pw.Column(
                  children: [
                    _totalLine('المجموع الفرعي:',
                        fmt.format(invoice.totalAmount + invoice.discount),
                        regularFont, boldFont),
                    if (invoice.discount > 0)
                      _totalLine('الخصم:',
                          '- ${fmt.format(invoice.discount)}',
                          regularFont, boldFont,
                          valueColor: PdfColors.red600),
                    pw.Divider(color: PdfColors.grey300),
                    _totalLine('الإجمالي:', fmt.format(invoice.totalAmount),
                        boldFont, boldFont,
                        size: 14, valueColor: PdfColors.blue800),
                    _totalLine('المدفوع:', fmt.format(invoice.paidAmount),
                        regularFont, boldFont,
                        valueColor: PdfColors.green700),
                    _totalLine('المتبقي:',
                        fmt.format(invoice.remainingAmount),
                        regularFont, boldFont,
                        valueColor: invoice.remainingAmount > 0
                            ? PdfColors.red600
                            : PdfColors.green700),
                  ],
                ),
              ),
            ],
          ),

          // ── Notes ───────────────────────────────────────────────────────
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ملاحظات:',
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                  pw.SizedBox(height: 3),
                  pw.Text(invoice.notes!,
                      style: pw.TextStyle(
                          font: regularFont, fontSize: 11)),
                ],
              ),
            ),
          ],

          pw.Spacer(),

          // ── Footer ──────────────────────────────────────────────────────
          pw.Divider(color: PdfColors.grey300),
          pw.Center(
            child: pw.Text('شكراً لتعاملكم معنا',
                style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 12,
                    color: PdfColors.grey500)),
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) => doc.save(),
    name: invoice.invoiceNumber,
  );
}

pw.Widget _statusBadge(String status, pw.Font boldFont) {
  final isPaid = status == 'PAID';
  final isPartial = status == 'PARTIAL';
  final label =
      isPaid ? 'مدفوعة' : isPartial ? 'مدفوعة جزئياً' : 'غير مدفوعة';
  final fg = isPaid
      ? PdfColors.green800
      : isPartial
          ? PdfColors.amber800
          : PdfColors.red800;
  final bg = isPaid
      ? PdfColors.green100
      : isPartial
          ? PdfColors.amber100
          : PdfColors.red100;
  final border = isPaid
      ? PdfColors.green400
      : isPartial
          ? PdfColors.amber400
          : PdfColors.red400;

  return pw.Container(
    padding:
        const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius:
          const pw.BorderRadius.all(pw.Radius.circular(10)),
      border: pw.Border.all(color: border),
    ),
    child: pw.Text(label,
        style: pw.TextStyle(
            font: boldFont, fontSize: 11, color: fg)),
  );
}

pw.Widget _totalLine(
    String label, String value, pw.Font labelFont, pw.Font valueFont,
    {double size = 12, PdfColor? valueColor}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: labelFont,
                fontSize: size,
                color: PdfColors.grey600)),
        pw.Text(value,
            style: pw.TextStyle(
                font: valueFont, fontSize: size, color: valueColor)),
      ],
    ),
  );
}
