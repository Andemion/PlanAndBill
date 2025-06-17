import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String notes;
  final String status; // active, inactive, new
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.dateOfBirth,
    this.emergencyContact,
    this.emergencyPhone,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      dateOfBirth: map['dateOfBirth'] != null ? (map['dateOfBirth'] as Timestamp).toDate() : null,
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'new',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Client copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? emergencyPhone,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Client && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
