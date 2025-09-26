// lib/core/models/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    this.firstName,
    this.lastName,
    this.createdAt,
    this.updatedAt,
  });

  /// Nom complet
  String get fullName {
    if ((firstName ?? '').isEmpty && (lastName ?? '').isEmpty) {
      return email;
    }
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  /// Initiales pour l'avatar
  String get initials {
    final f = (firstName?.isNotEmpty ?? false) ? firstName![0] : '';
    final l = (lastName?.isNotEmpty ?? false) ? lastName![0] : '';
    return (f + l).toUpperCase().isNotEmpty ? (f + l).toUpperCase() : email[0].toUpperCase();
  }

  /// Convertir Firestore → modèle
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir FirebaseUser + FirestoreData → modèle
  factory AppUser.fromFirebase(User user, {Map<String, dynamic>? profile}) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      firstName: profile?['firstName'],
      lastName: profile?['lastName'],
      createdAt: (profile?['createdAt'] as Timestamp?)?.toDate() ?? user.metadata.creationTime,
      updatedAt: (profile?['updatedAt'] as Timestamp?)?.toDate() ?? user.metadata.lastSignInTime,
    );
  }

  /// Convertir modèle → Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
