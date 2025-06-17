import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planandbill/models/app_user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AppUser? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  bool _gdprConsent = false;

  // Getters
  AppUser? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get gdprConsent => _gdprConsent;

  // Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _fetchUserData(currentUser.uid);
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For web
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final UserCredential userCredential = 
            await _auth.signInWithPopup(authProvider);
        
        if (userCredential.user != null) {
          await _handleSignInSuccess(userCredential.user!);
          return true;
        }
        return false;
      } 
      // For mobile
      else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return false;

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = 
            await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          await _handleSignInSuccess(userCredential.user!);
          return true;
        }
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle successful sign in
  Future<void> _handleSignInSuccess(User firebaseUser) async {
    // Check if user exists in Firestore
    final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    
    if (userDoc.exists) {
      // User exists, fetch their data
      await _fetchUserData(firebaseUser.uid);
    } else {
      // New user, create profile
      final newUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        gdprConsent: false,
        createdAt: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      _user = newUser;
      _gdprConsent = false;
    }
    
    _isAuthenticated = true;
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _user = AppUser.fromMap(userDoc.data()!);
        _gdprConsent = _user!.gdprConsent;
      }
    } catch (e) {
      _error = 'Failed to fetch user data: ${e.toString()}';
    }
  }

  // Update GDPR consent
  Future<void> updateGdprConsent(bool consent) async {
    if (_user == null) return;
    
    try {
      await _firestore.collection('users').doc(_user!.id).update({
        'gdprConsent': consent,
        'gdprConsentDate': DateTime.now().toIso8601String(),
      });
      
      _gdprConsent = consent;
      _user = _user!.copyWith(gdprConsent: consent);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update GDPR consent: ${e.toString()}';
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _isAuthenticated = false;
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request data export (GDPR right to data portability)
  Future<Map<String, dynamic>> exportUserData() async {
    if (_user == null) return {};
    
    try {
      // Get user data
      final userData = await _firestore.collection('users').doc(_user!.id).get();
      
      // Get user appointments
      final appointments = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: _user!.id)
          .get();
      
      // Get user clients
      final clients = await _firestore
          .collection('clients')
          .where('userId', isEqualTo: _user!.id)
          .get();
      
      // Get user invoices
      final invoices = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: _user!.id)
          .get();
      
      // Compile all data
      return {
        'user': userData.data(),
        'appointments': appointments.docs.map((doc) => doc.data()).toList(),
        'clients': clients.docs.map((doc) => doc.data()).toList(),
        'invoices': invoices.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      _error = 'Failed to export data: ${e.toString()}';
      notifyListeners();
      return {};
    }
  }

  // Delete user account (GDPR right to erasure)
  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = _user!.id;
      
      // Delete user data from Firestore (appointments, clients, invoices)
      final batch = _firestore.batch();
      
      // Delete appointments
      final appointments = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in appointments.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete clients
      final clients = await _firestore
          .collection('clients')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in clients.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete invoices
      final invoices = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in invoices.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Commit the batch
      await batch.commit();
      
      // Delete user from Firebase Auth
      await _auth.currentUser?.delete();
      
      // Sign out
      await signOut();
      
      return true;
    } catch (e) {
      _error = 'Failed to delete account: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
