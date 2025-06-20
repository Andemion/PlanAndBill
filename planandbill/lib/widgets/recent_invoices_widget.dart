import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/services/invoice_service.dart';
import 'package:planandbill/models/invoice.dart';
import 'package:planandbill/screens/billing/invoice_details_screen.dart';

class RecentInvoicesWidget extends StatelessWidget {
  const RecentInvoicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceService>(
      builder: (context, invoiceService, child) {
        final invoices = invoiceService.getRecentInvoices();

        if (invoices.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No recent invoices'),
              ),
            ),
          );
        }

        return Column(
          children: invoices.map((invoice) => _buildInvoiceCard(context, invoice)).toList(),
        );
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InvoiceDetailsScreen(invoice: invoice),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      invoice.number,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatDate(invoice.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
