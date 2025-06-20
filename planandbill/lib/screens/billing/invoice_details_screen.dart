import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/invoice.dart';
import 'package:planandbill/services/invoice_service.dart';
import 'package:planandbill/screens/billing/create_invoice_screen.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/services/pdf_service.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/services/email_service.dart';


class InvoiceDetailsScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.number),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateInvoiceScreen(
                    invoice: invoice,
                    type: invoice.type,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              if (invoice.type == 'quote')
                const PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      Icon(Icons.transform),
                      SizedBox(width: 8),
                      Text('Convert to Invoice'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'duplicate':
                  _duplicateInvoice(context);
                  break;
                case 'pdf':
                  _exportPDF(context);
                  break;
                case 'convert':
                  _convertToInvoice(context);
                  break;
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildClientCard(),
            const SizedBox(height: 16),
            _buildItemsCard(),
            const SizedBox(height: 16),
            _buildTotalsCard(),
            if (invoice.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoice.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    invoice.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(invoice.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              invoice.number,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(_formatDate(invoice.date)),
                    ],
                  ),
                ),
                if (invoice.dueDate != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Due Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(_formatDate(invoice.dueDate!)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill To',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              invoice.clientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // En-têtes
            Row(
              children: const [
                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            const Divider(),

            // Lignes d’items
            ...invoice.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.description)),
                  Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),

            const Divider(height: 32),

            // Total général
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal:', invoice.subtotal, invoice.currency),
            _buildTotalRow('Tax (${invoice.taxRate.toStringAsFixed(1)}%):', invoice.taxAmount, invoice.currency),
            const Divider(),
            _buildTotalRow('Total:', invoice.total, invoice.currency, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, String currency, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${currency} ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(invoice.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (invoice.status == 'draft') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markAsSent(context),
              icon: const Icon(Icons.send),
              label: const Text('Send my email'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (invoice.type == 'quote' && invoice.status == 'sent') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _convertToInvoice(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Convert to Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (invoice.status == 'sent' || invoice.status == 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markAsPaid(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _exportPDF(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
        ),
      ],
    );
  }

  void _duplicateInvoice(BuildContext context) {
    final duplicatedInvoice = invoice.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: '', // Will be generated in the form
      date: DateTime.now(),
      status: 'draft',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(
          invoice: duplicatedInvoice,
          type: invoice.type,
        ),
      ),
    );
  }

  void _exportPDF(BuildContext context) async {
    try {
      final pdfService = PdfService();
      final pdfData = await pdfService.generateInvoicePdf(invoice);

      // Show options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export PDF'),
          content: const Text('What would you like to do with the PDF?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                pdfService.printPdf(pdfData, invoice.number);
              },
              child: const Text('Print'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                pdfService.savePdf(pdfData, '${invoice.number}.pdf');
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  void _markAsSent(BuildContext context) async {
    try {
      final emailService = EmailService();
      final pdfService = PdfService();
      final pdfData = await pdfService.generateInvoicePdf(invoice);

      await emailService.shareInvoicePdf(pdfData, invoice);

      _updateStatus(context, 'sent');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'email : $e')),
      );
    }
  }

  void _markAsPaid(BuildContext context) {
    _updateStatus(context, 'paid');
  }

  void _updateStatus(BuildContext context, String newStatus) {
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    final updatedInvoice = invoice.copyWith(status: newStatus);

    invoiceService.upsertInvoice(updatedInvoice).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${invoice.type.toUpperCase()} marked as ${newStatus}')),
        );
        Navigator.of(context).pop(); // Go back to refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invoiceService.error ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${invoice.type.toUpperCase()}'),
        content: Text('Are you sure you want to delete ${invoice.number}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final invoiceService = Provider.of<InvoiceService>(context, listen: false);
              final success = await invoiceService.deleteInvoice(invoice.id);

              if (success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${invoice.type.toUpperCase()} deleted successfully')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(invoiceService.error ?? 'Failed to delete ${invoice.type}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.forestGreen;
      case 'sent':
      case 'pending':
        return AppColors.goldenYellow;
      case 'overdue':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _convertToInvoice(BuildContext context) async {
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Remplacer 'devis' par 'facture' dans le numéro
    final updatedNumber = invoice.number.replaceFirst(RegExp(r'^devis', caseSensitive: false), 'facture');

    final updatedInvoice = invoice.copyWith(
      type: 'invoice',
      number: updatedNumber,
    );

    final success = await invoiceService.upsertInvoice(updatedInvoice);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote converted to invoice')),
      );
      Navigator.of(context).pop(); // retour à l’écran précédent
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(invoiceService.error ?? 'Failed to convert quote'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}


