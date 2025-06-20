import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/screens/billing/create_invoice_screen.dart';
import 'package:planandbill/screens/billing/invoice_details_screen.dart';
import 'package:planandbill/services/invoice_service.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/services/pdf_service.dart';
import 'package:planandbill/models/invoice.dart';


class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final invoiceService = Provider.of<InvoiceService>(
          context, listen: false);
      if (authService.user != null) {
        invoiceService.fetchInvoicesForUser(authService.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesTab(),
                _buildQuotesTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.forestGreen,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.forestGreen,
        tabs: const [
          Tab(text: 'Invoices'),
          Tab(text: 'Quotes'),
          Tab(text: 'Reports'),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return Consumer<InvoiceService>(
      builder: (context, invoiceService, child) {
        if (invoiceService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final invoices = invoiceService.invoicesList;

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No invoices yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first invoice to get started',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return _buildDocumentCard(context, invoice, 'invoice');
          },
        );
      },
    );
  }

  Widget _buildQuotesTab() {
    return Consumer<InvoiceService>(
      builder: (context, invoiceService, child) {
        if (invoiceService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final quotes = invoiceService.quotesList;

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No quotes yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first quote to get started',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return _buildDocumentCard(context, quote, 'quote');
          },
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return Consumer<InvoiceService>(
      builder: (context, invoiceService, child) {
        final currentMonth = DateTime.now();
        final invoices = invoiceService.invoices;

        final invoicesEUR = invoices.where((i) =>
        i.currency == '€' &&
            i.date.month == currentMonth.month &&
            i.date.year == currentMonth.year).toList();

        final invoicesCHF = invoices.where((i) =>
        i.currency == 'CHF' &&
            i.date.month == currentMonth.month &&
            i.date.year == currentMonth.year).toList();

        final monthlyRevenueEUR = invoicesEUR.fold(
            0.0, (sum, i) => sum + i.total);
        final monthlyRevenueCHF = invoicesCHF.fold(
            0.0, (sum, i) => sum + i.total);

        final pendingEUR = invoicesEUR
            .where((i) => i.status == 'sent')
            .toList();
        final pendingCHF = invoicesCHF
            .where((i) => i.status == 'sent')
            .toList();

        final totalClients = invoices
            .map((i) => i.clientId)
            .toSet()
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Reports',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 16),

              _buildReportCard(
                'Monthly Revenue',
                '€ ${monthlyRevenueEUR.toStringAsFixed(2)}',
                'CHF ${monthlyRevenueCHF.toStringAsFixed(2)}',
                _getMonthName(currentMonth.month),
                Icons.trending_up,
                AppColors.forestGreen,
              ),

              const SizedBox(height: 12),

              _buildReportCard(
                'Pending Invoices',
                '€ ${pendingEUR
                    .fold(0.0, (sum, i) => sum + i.total)
                    .toStringAsFixed(2)}',
                'CHF ${pendingCHF
                    .fold(0.0, (sum, i) => sum + i.total)
                    .toStringAsFixed(2)}',
                '${pendingEUR.length + pendingCHF.length} invoices',
                Icons.pending_actions,
                AppColors.goldenYellow,
              ),

              const SizedBox(height: 12),

              _buildReportCard(
                'Total Clients',
                totalClients.toString(),
                '', // Pas de deuxième ligne ici
                'Active clients',
                Icons.people,
                AppColors.peach,
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: () => _generateDetailedReport(context),
                icon: const Icon(Icons.file_download),
                label: const Text('Export Monthly Report'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(BuildContext context, Invoice document,
      String type) {
    final isInvoice = type == 'invoice';
    final icon = isInvoice ? Icons.receipt : Icons.description;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InvoiceDetailsScreen(invoice: document),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.forestGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      document.number,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(document.date),
                      style: TextStyle(
                        color: Colors.grey[500],
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
                    '${document.currency} ${document.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(document.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      document.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(document.status),
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildReportCard(String title,
      String line1,
      String line2,
      String subtitle,
      IconData icon,
      Color color,) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text(line1, style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(line2, style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.forestGreen;
      case 'pending':
      case 'sent':
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

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateDetailedReport(BuildContext context) async {
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final currentMonth = DateTime.now();

    // Données nécessaires
    final invoices = invoiceService.invoices.where((i) =>
    i.date.month == currentMonth.month && i.date.year == currentMonth.year
    ).toList();

    final totalClients = invoices.map((i) => i.clientId).toSet().length;

    final appointments = appointmentService.appointments.where((a) =>
    a.date.month == currentMonth.month && a.date.year == currentMonth.year
    ).toList();

    final totalAppointments = appointments.length;

    final pdfService = PdfService();
    final pdfData = await pdfService.generateMonthlyReportPdf(
      currentMonth,
      invoices,
      totalClients,
      totalAppointments,
    );

    // Afficher les options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Monthly Report'),
        content: const Text('What would you like to do with the report?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pdfService.printPdf(pdfData, 'monthly_report');
            },
            child: const Text('Print'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pdfService.savePdf(pdfData, 'monthly_report.pdf');
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
  }

}

