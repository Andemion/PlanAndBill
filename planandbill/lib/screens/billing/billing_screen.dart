import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/screens/billing/create_invoice_screen.dart';
import 'package:planandbill/screens/billing/invoice_details_screen.dart';
import 'package:planandbill/services/invoice_service.dart';
import 'package:planandbill/services/auth_service.dart';
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
      final invoiceService = Provider.of<InvoiceService>(context, listen: false);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateDocumentDialog();
        },
        backgroundColor: AppColors.forestGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        final monthlyRevenue = invoiceService.getMonthlyRevenue(currentMonth);
        final pendingInvoices = invoiceService.getPendingInvoices();
        final totalClients = Provider.of<AuthService>(context).user != null ?
        invoiceService.invoices.map((i) => i.clientId).toSet().length : 0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Reports',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Monthly Revenue',
                '€${monthlyRevenue.toStringAsFixed(2)}',
                _getMonthName(currentMonth.month),
                Icons.trending_up,
                AppColors.forestGreen,
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                'Pending Invoices',
                '€${pendingInvoices.fold(0.0, (sum, invoice) => sum + invoice.total).toStringAsFixed(2)}',
                '${pendingInvoices.length} invoices',
                Icons.pending_actions,
                AppColors.goldenYellow,
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                'Total Clients',
                totalClients.toString(),
                'Active clients',
                Icons.people,
                AppColors.peach,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _generateDetailedReport();
                },
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

  Widget _buildDocumentCard(BuildContext context, Invoice document, String type) {
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
                    '€${document.total.toStringAsFixed(2)}',
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

  Widget _buildReportCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      ) {
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
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('New Invoice'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateInvoiceScreen(type: 'invoice'),
                  ),
                ).then((result) {
                  if (result == true) {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
                    if (authService.user != null) {
                      invoiceService.fetchInvoicesForUser(authService.user!.id);
                    }
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('New Quote'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateInvoiceScreen(type: 'quote'),
                  ),
                ).then((result) {
                  if (result == true) {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
                    if (authService.user != null) {
                      invoiceService.fetchInvoicesForUser(authService.user!.id);
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generateDetailedReport() {
    // TODO: Implement PDF report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report generation feature coming soon!'),
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
}
