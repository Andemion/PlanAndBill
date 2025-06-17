import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:planandbill/models/invoice.dart';

class InvoiceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  List<Invoice> get invoicesList => _invoices.where((i) => i.type == 'invoice').toList();
  List<Invoice> get quotesList => _invoices.where((i) => i.type == 'quote').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get invoice for a user
  Future<List<Invoice>> fetchInvoicesForUser(String userId, {int limit = 0}) async {
    final query = _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    final querySnapshot = limit > 0 ? await query.limit(limit).get() : await query.get();

    return querySnapshot.docs.map((doc) => Invoice.fromMap(doc.data())).toList();
  }

  // Create new invoice
  Future<bool> createInvoice(Invoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .set(invoice.toMap());

      _invoices.add(invoice);
      _invoices.sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedInvoice = invoice.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .update(updatedInvoice.toMap());

      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
        _invoices.sort((a, b) => b.date.compareTo(a.date));
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete invoice
  Future<bool> deleteInvoice(String invoiceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('invoices')
          .doc(invoiceId)
          .delete();

      _invoices.removeWhere((i) => i.id == invoiceId);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get recent invoices
  List<Invoice> getRecentInvoices({int limit = 5}) {
    return _invoices.take(limit).toList();
  }

  // Get monthly revenue
  double getMonthlyRevenue(DateTime month) {
    return _invoices
        .where((invoice) =>
    invoice.type == 'invoice' &&
        invoice.status == 'paid' &&
        invoice.date.year == month.year &&
        invoice.date.month == month.month)
        .fold(0.0, (sum, invoice) => sum + invoice.total);
  }

  // Get pending invoices
  List<Invoice> getPendingInvoices() {
    return _invoices
        .where((invoice) =>
    invoice.type == 'invoice' &&
        invoice.status == 'pending')
        .toList();
  }

  Future<String> generateCustomInvoiceNumber({
    required String clientName,
    required String userId,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final existingInvoices = await fetchInvoicesForUser(userId, limit: 1);

    final todayCount = existingInvoices
        .where((inv) =>
    inv.date.year == now.year &&
        inv.date.month == now.month &&
        inv.date.day == now.day)
        .length;

    final countStr = (todayCount + 1).toString().padLeft(3, '0');

    final cleanedName = clientName
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return 'facture-$dateStr-$countStr-$cleanedName';
  }

}
