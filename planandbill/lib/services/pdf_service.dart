import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:planandbill/models/invoice.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Generate PDF for invoice
  Future<Uint8List> generateInvoicePdf(Invoice invoice, {String? businessName, String? businessAddress, String? businessPhone, String? businessEmail, String? businessTaxNumber}) async {
    final pdf = pw.Document();

    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Format dates
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName ?? 'Art Therapy Practice',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 24,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(businessAddress ?? '123 Therapy Street\n75001 Paris, France'),
                    pw.SizedBox(height: 5),
                    pw.Text('Phone: ${businessPhone ?? '+33 1 23 45 67 89'}'),
                    pw.Text('Email: ${businessEmail ?? 'contact@arttherapy.com'}'),
                    if (businessTaxNumber != null) pw.Text('Tax ID: $businessTaxNumber'),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        invoice.type.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        invoice.number,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Date: ${dateFormat.format(invoice.date)}'),
                      if (invoice.dueDate != null)
                        pw.Text('Due Date: ${dateFormat.format(invoice.dueDate!)}'),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Bill To
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(5),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    invoice.clientName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(font: fontBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Qty',
                        style: pw.TextStyle(font: fontBold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Unit Price',
                        style: pw.TextStyle(font: fontBold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(font: fontBold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),

                // Table Items
                ...invoice.items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.description),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        item.quantity.toString(),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '€${item.unitPrice.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '€${item.total.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 20),

            // Totals
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 150,
                        child: pw.Text('Subtotal:'),
                      ),
                      pw.Container(
                        width: 100,
                        child: pw.Text(
                          '€${invoice.subtotal.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 150,
                        child: pw.Text('Tax (${invoice.taxRate.toStringAsFixed(1)}%):'),
                      ),
                      pw.Container(
                        width: 100,
                        child: pw.Text(
                          '€${invoice.taxAmount.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Divider(color: PdfColors.grey),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 150,
                        child: pw.Text(
                          'Total:',
                          style: pw.TextStyle(font: fontBold),
                        ),
                      ),
                      pw.Container(
                        width: 100,
                        child: pw.Text(
                          '€${invoice.total.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: fontBold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Notes
            if (invoice.notes.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(5),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Notes:',
                      style: pw.TextStyle(font: fontBold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(invoice.notes),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 30),

            // Footer
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text('Thank you for your business!'),
                  pw.SizedBox(height: 5),
                  pw.Text('Payment is due within 30 days.'),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Generate PDF for monthly report
  Future<Uint8List> generateMonthlyReportPdf(
      DateTime month,
      List<Invoice> invoices,
      double totalRevenue,
      int totalClients,
      int totalAppointments,
      {String? businessName}
      ) async {
    final pdf = pw.Document();

    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Format dates
    final dateFormat = DateFormat('MMMM yyyy');
    final monthName = dateFormat.format(month);

    // Calculate statistics
    final paidInvoices = invoices.where((i) => i.status == 'paid').toList();
    final pendingInvoices = invoices.where((i) => i.status == 'pending' || i.status == 'sent').toList();
    final paidAmount = paidInvoices.fold(0.0, (sum, i) => sum + i.total);
    final pendingAmount = pendingInvoices.fold(0.0, (sum, i) => sum + i.total);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Monthly Financial Report',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    monthName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    businessName ?? 'Art Therapy Practice',
                    style: pw.TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Revenue',
                        style: pw.TextStyle(
                          font: fontBold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '€${totalRevenue.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Clients',
                        style: pw.TextStyle(
                          font: fontBold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        totalClients.toString(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Appointments',
                        style: pw.TextStyle(
                          font: fontBold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        totalAppointments.toString(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Invoice Summary
            pw.Text(
              'Invoice Summary',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Invoices: ${invoices.length}'),
                      pw.Text('Paid: ${paidInvoices.length}'),
                      pw.Text('Pending: ${pendingInvoices.length}'),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Paid Amount: €${paidAmount.toStringAsFixed(2)}'),
                      pw.Text('Pending Amount: €${pendingAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Invoices Table
            pw.Text(
              'Recent Invoices',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Invoice #',
                        style: pw.TextStyle(font: fontBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Client',
                        style: pw.TextStyle(font: fontBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Date',
                        style: pw.TextStyle(font: fontBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Status',
                        style: pw.TextStyle(font: fontBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(font: fontBold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),

                // Table Items - limit to 10 most recent
                ...invoices.take(10).map((invoice) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(invoice.number),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(invoice.clientName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(DateFormat('dd/MM/yyyy').format(invoice.date)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(invoice.status.toUpperCase()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '€${invoice.total.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text('Report generated on ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Print PDF
  Future<void> printPdf(Uint8List pdfData, String documentName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: documentName,
    );
  }

  // Save PDF
  Future<void> savePdf(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(bytes: pdfData, filename: fileName);
  }
}
