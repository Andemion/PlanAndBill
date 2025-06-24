import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:planandbill/models/appointment.dart';
import 'package:planandbill/services/notification_service.dart';

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get appointments for a user
  Future<void> fetchAppointments(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: false)
          .get();

      _appointments = querySnapshot.docs
          .map((doc) => Appointment.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get appointments for a specific date
  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments.where((appointment) {
      return appointment.date.year == date.year &&
          appointment.date.month == date.month &&
          appointment.date.day == date.day;
    }).toList();
  }

  // Create new appointment
  Future<bool> createAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());

      _appointments.add(appointment);
      _appointments.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();

      final isEnabled = await NotificationService.getNotificationsEnabled();
      if (isEnabled && appointment.date.isAfter(DateTime.now())) {
        await NotificationService.scheduleAppointmentNotification(appointment);
      }


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

  // Update appointment
  Future<bool> updateAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAppointment = appointment.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(updatedAppointment.toMap());

      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
        _appointments.sort((a, b) => a.date.compareTo(b.date));
      }
      notifyListeners();

      final isEnabled = await NotificationService.getNotificationsEnabled();
      if (isEnabled && updatedAppointment.date.isAfter(DateTime.now())) {
        await NotificationService.scheduleAppointmentNotification(updatedAppointment);
      }

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

  // Delete appointment
  Future<bool> deleteAppointment(String appointmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      _appointments.removeWhere((a) => a.id == appointmentId);

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

  // Get upcoming appointments
  List<Appointment> getUpcomingAppointments({int limit = 5}) {
    final now = DateTime.now();
    return _appointments
        .where((appointment) => appointment.date.isAfter(now))
        .take(limit)
        .toList();
  }
}
