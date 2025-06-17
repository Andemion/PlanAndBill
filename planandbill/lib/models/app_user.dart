class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool gdprConsent;
  final DateTime? gdprConsentDate;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.gdprConsent,
    this.gdprConsentDate,
    required this.createdAt,
  });

  // Create a copy of the user with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? gdprConsent,
    DateTime? gdprConsentDate,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      gdprConsent: gdprConsent ?? this.gdprConsent,
      gdprConsentDate: gdprConsentDate ?? this.gdprConsentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert user to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'gdprConsent': gdprConsent,
      'gdprConsentDate': gdprConsentDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create user from Firestore map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      gdprConsent: map['gdprConsent'] ?? false,
      gdprConsentDate: map['gdprConsentDate'] != null 
          ? DateTime.parse(map['gdprConsentDate']) 
          : null,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}
