import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autocentral/pigeon_definitions/user_api.g.dart'; // ton fichier Pigeon généré

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? preferences;
  final bool isEmailVerified;
  final String? phoneNumber;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
    this.preferences,
    this.isEmailVerified = false,
    this.phoneNumber,
  });

  // Convertir Firestore -> UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      preferences: map['preferences'] as Map<String, dynamic>?,
      isEmailVerified: map['isEmailVerified'] ?? false,
      phoneNumber: map['phoneNumber'],
    );
  }

  // Convertir UserModel -> Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'preferences': preferences,
      'isEmailVerified': isEmailVerified,
      'phoneNumber': phoneNumber,
    };
  }

  // Créer une copie avec des modifications
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    bool? isEmailVerified,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

UserModel userDetailsToUserModel(UserDetails details) {
  return UserModel(
    id: details.uid ?? '',           // éviter null
    email: details.email ?? '',      // éviter null
    displayName: details.displayName,
    photoUrl: details.photoUrl,
    createdAt: DateTime.now(),
    updatedAt: null,
    isEmailVerified: false,
    preferences: {},
  );
}
