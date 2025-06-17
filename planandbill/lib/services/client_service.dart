import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:planandbill/models/client.dart';

class ClientService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get clients for a user
  Future<void> fetchClients(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('clients')
          .where('userId', isEqualTo: userId)
          .orderBy('name')
          .get();

      _clients = querySnapshot.docs
          .map((doc) => Client.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new client
  Future<bool> createClient(Client client) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('clients')
          .doc(client.id)
          .set(client.toMap());

      _clients.add(client);
      _clients.sort((a, b) => a.name.compareTo(b.name));

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

  // Update client
  Future<bool> updateClient(Client client) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedClient = client.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('clients')
          .doc(client.id)
          .update(updatedClient.toMap());

      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = updatedClient;
        _clients.sort((a, b) => a.name.compareTo(b.name));
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

  // Delete client
  Future<bool> deleteClient(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('clients')
          .doc(clientId)
          .delete();

      _clients.removeWhere((c) => c.id == clientId);

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

  // Get client by ID
  Client? getClientById(String clientId) {
    try {
      return _clients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      return null;
    }
  }

  // Search clients
  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;

    final lowercaseQuery = query.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(lowercaseQuery) ||
          client.email.toLowerCase().contains(lowercaseQuery) ||
          client.phone.contains(query);
    }).toList();
  }
}
