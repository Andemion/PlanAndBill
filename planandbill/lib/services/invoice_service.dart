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

    final allInvoices = querySnapshot.docs
        .map((doc) => Invoice.fromMap(doc.data()))
        .toList();

    _invoices = querySnapshot.docs
        .map((doc) => Invoice.fromMap(doc.data()))
        .toList();

    notifyListeners();

    return _invoices;
  }

  // Create new invoice
  Future<bool> upsertInvoice(Invoice invoice) async {
    try {
      final docRef = _firestore.collection('invoices').doc(invoice.id);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Le document existe => on le met à jour
        await docRef.update(invoice.toMap());
      } else {
        // Le document n'existe pas => on le crée
        await docRef.set(invoice.toMap());
      }

      return true;
    } catch (e) {
      print('Error in upsertInvoice: $e');
      return false;
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
    String typeLabel = 'facture',
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

    return '$typeLabel-$dateStr-$countStr-$cleanedName';
  }

}
