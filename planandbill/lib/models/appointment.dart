import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String clientId;
  final String clientName;
  final String type;
  final DateTime date;
  final String time;
  final int duration; // in minutes
  final String location;
  final String notes;
  final double? fee;
  final String status; // scheduled, completed, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.clientName,
    required this.type,
    required this.date,
    required this.time,
    required this.duration,
    required this.location,
    required this.notes,
    this.fee,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'type': type,
      'date': Timestamp.fromDate(date),
      'time': time,
      'duration': duration,
      'location': location,
      'notes': notes,
      'fee': fee,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      type: map['type'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      duration: map['duration'] ?? 60,
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      fee: map['fee']?.toDouble(),
      status: map['status'] ?? 'scheduled',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Appointment copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? clientName,
    String? type,
    DateTime? date,
    String? time,
    int? duration,
    String? location,
    String? notes,
    double? fee,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      type: type ?? this.type,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
