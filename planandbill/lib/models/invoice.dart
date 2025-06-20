import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final String currency;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.currency = '€',
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'currency': currency,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '€',
    );
  }
}

class Invoice {
  final String id;
  final String userId;
  final String clientId;
  final String clientName;
  final String number;
  final DateTime date;
  final DateTime? dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  final String status; // draft, sent, paid, overdue
  final String type; // invoice, quote
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.clientName,
    required this.number,
    required this.date,
    this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.currency,
    required this.total,
    required this.status,
    required this.type,
    required this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'number': number,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'currency': currency,
      'total': total,
      'status': status,
      'type': type,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      number: map['number'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromMap(item))
          .toList() ?? [],
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '€',
      total: map['total']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'draft',
      type: map['type'] ?? 'invoice',
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Invoice copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? clientName,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? currency,
    String? status,
    String? type,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      number: number ?? this.number,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
