import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/invoice.dart';
import 'package:planandbill/models/client.dart';
import 'package:planandbill/services/client_service.dart';
import 'package:planandbill/services/invoice_service.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/theme/app_theme.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice; // For editing
  final String type; // 'invoice' or 'quote'
  final Client? initialClient;

  const CreateInvoiceScreen({
    super.key,
    this.invoice,
    this.type = 'invoice',
    this.initialClient,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _notesController = TextEditingController();

  Client? _selectedClient;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  List<InvoiceItem> _items = [];
  double _taxRate = 20.0; // Default 20% VAT
  bool _isLoading = false;
  String _currency = "€";
  String _type = "invoice";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clientService = Provider.of<ClientService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.user != null) {
        await clientService.fetchClients(authService.user!.id);
      }

      // Si édition
      if (widget.invoice != null) {
        _loadInvoiceData(clientService);
      }

      // Si client initial fourni
      if (widget.initialClient != null) {
        _selectedClient = widget.initialClient;
      }

      // Si création
      if (widget.invoice == null && _selectedClient != null) {
        await _generateNumber();
      }

      setState(() {}); // trigger UI update
    });
  }


  void _loadInvoiceData(ClientService clientService) {
    final invoice = widget.invoice!;
    _numberController.text = invoice.number;
    _date = invoice.date;
    _dueDate = invoice.dueDate;
    _items = List.from(invoice.items);
    _taxRate = invoice.taxRate;
    _notesController.text = invoice.notes;
    _selectedClient = clientService.getClientById(invoice.clientId);
    _currency = invoice.currency;
    _type = invoice.type;
    if (_currency == "CHF"){
      _taxRate = 0;
    }
  }

  Future<void> _generateNumber() async {
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    final clientService = Provider.of<ClientService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (_selectedClient == null || authService.user == null) return;

    final customNumber = await invoiceService.generateCustomInvoiceNumber(
      clientName: _selectedClient?.name ?? widget.invoice?.clientName ?? 'inconnu',
      userId: authService.user!.id,
    );


    setState(() {
      _numberController.text = customNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null
            ? 'New ${widget.type.toUpperCase()}'
            : 'Edit ${widget.type.toUpperCase()}'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveInvoice,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildClientSection(),
              const SizedBox(height: 24),
              _buildItemsSection(),
              const SizedBox(height: 24),
              _buildTotalsSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.type.toUpperCase()} Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Champ Numéro de facture
            TextFormField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: '${widget.type.toUpperCase()} Number *',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Sélecteur de date
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(_formatDate(_date)),
                  ],
                ),
              ),
            ),

            if (widget.type == 'invoice') ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? 'Due: ${_formatDate(_dueDate!)}'
                            : 'Set Due Date (Optional)',
                        style: TextStyle(
                          color: _dueDate != null ? null : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildClientSection() {
    return Consumer<ClientService>(
      builder: (context, clientService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Client>(
                  value: clientService.clients.contains(_selectedClient) ? _selectedClient : null,
                  decoration: const InputDecoration(
                    hintText: 'Select a client',
                    border: OutlineInputBorder(),
                  ),
                  items: clientService.clients.map((client) {
                    return DropdownMenuItem(
                      value: client,
                      child: Text(client.name),
                    );
                  }).toList(),
                  onChanged: (client) {
                    setState(() {
                      _selectedClient = client;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a client';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemRow(index, item);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, InvoiceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateItem(index, description: value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final qty = int.tryParse(value) ?? 1;
                      _updateItem(index, quantity: qty);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '${_currency ?? '€'}',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      _updateItem(index, unitPrice: price);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ${_currency} ${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    final subtotal = _calculateSubtotal();
    final taxAmount = subtotal * (_taxRate / 100);
    final total = subtotal + taxAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Tax Rate (%):'),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: _taxRate.toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _taxRate = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildTotalRow('Subtotal:', subtotal),
            _buildTotalRow('Tax (${_taxRate.toStringAsFixed(1)}%):', taxAmount),
            const Divider(),
            _buildTotalRow('Total:', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
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
            ' ${_currency} ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Additional notes or terms...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(
        description: '',
        quantity: 1,
        unitPrice: 0.0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, {String? description, int? quantity, double? unitPrice}) {
    setState(() {
      final item = _items[index];
      _items[index] = InvoiceItem(
        description: description ?? item.description,
        quantity: quantity ?? item.quantity,
        unitPrice: unitPrice ?? item.unitPrice,
      );
    });
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) {
      final priceHT = item.unitPrice / (1 + (_taxRate / 100));
      return sum + (priceHT * item.quantity);
    });
  }


  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _date = date;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _date.add(const Duration(days: 30)),
      firstDate: _date,
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final invoiceService = Provider.of<InvoiceService>(context, listen: false);
      final subtotal = _calculateSubtotal();
      final taxAmount = subtotal * (_taxRate / 100);
      final total = subtotal + taxAmount;

      final invoice = Invoice(
        id: widget.invoice?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: authService.user!.id,
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.name,
        number: _numberController.text,
        date: _date,
        dueDate: _dueDate,
        items: _items,
        subtotal: subtotal,
        taxRate: _taxRate,
        taxAmount: taxAmount,
        total: total,
        currency: _currency,
        status: 'draft',
        type: _type,
        notes: _notesController.text,
        createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      );

      bool success = await invoiceService.upsertInvoice(invoice);

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.type.toUpperCase()} saved successfully'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invoiceService.error ?? 'Failed to save ${widget.type}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
