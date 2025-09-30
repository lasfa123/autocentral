// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:autocentral/pigeon_definitions/user_api.g.dart'; // UserDetails

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de l'état d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  static User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // ------------------- Auth Email / Password -------------------

  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
        );

        await credential.user!.updateDisplayName('$firstName $lastName');
        return AuthResult.success();
      } else {
        return AuthResult.error('Erreur lors de la création du compte');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e));
    } catch (e) {
      return AuthResult.error('Une erreur inattendue s\'est produite: $e');
    }
  }

  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return AuthResult.success();
      } else {
        return AuthResult.error('Erreur de connexion');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e));
    } catch (e) {
      return AuthResult.error('Une erreur inattendue s\'est produite: $e');
    }
  }

  static Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Erreur lors de la déconnexion: $e');
    }
  }

  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e));
    } catch (e) {
      return AuthResult.error('Une erreur inattendue s\'est produite: $e');
    }
  }

  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        return AuthResult.success();
      }
      return AuthResult.error('Aucun utilisateur connecté');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e));
    } catch (e) {
      return AuthResult.error('Une erreur inattendue s\'est produite: $e');
    }
  }

  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  static Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult.success();
      }
      return AuthResult.error('Utilisateur non trouvé ou email déjà vérifié');
    } catch (e) {
      return AuthResult.error('Erreur lors de l\'envoi de l\'email: $e');
    }
  }

  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ------------------- Profil Utilisateur CORRIGÉ -------------------

  /// Récupérer le profil utilisateur depuis Firestore et retourner UserDetails
  static Future<UserDetails?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Aucun utilisateur connecté');
        return null;
      }

      debugPrint('🔍 Récupération profil pour UID: ${user.uid}');

      // Essayer de récupérer depuis Firestore
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          debugPrint('📄 Données Firestore récupérées: $data');

          // Validation et nettoyage des données
          final email = _cleanString(data['email']) ?? user.email;
          final firstName = _cleanString(data['firstName']);
          final lastName = _cleanString(data['lastName']);
          final photoUrl = _cleanString(data['photoUrl']) ?? user.photoURL;

          // Construction du displayName
          String? displayName;
          if (firstName != null && lastName != null) {
            displayName = '$firstName $lastName';
          } else if (firstName != null) {
            displayName = firstName;
          } else if (lastName != null) {
            displayName = lastName;
          } else {
            displayName = user.displayName;
          }

          // Création sécurisée de UserDetails
          final userDetails = UserDetails(
            uid: user.uid,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
          );

          debugPrint('✅ UserDetails créé depuis Firestore: ${userDetails.displayName}');
          return userDetails;
        } else {
          debugPrint('⚠️ Document Firestore vide, fallback vers Firebase Auth');
        }
      } catch (firestoreError) {
        debugPrint('❌ Erreur Firestore: $firestoreError');
        debugPrint('🔄 Fallback vers Firebase Auth');
      }

      // Fallback: Utiliser uniquement Firebase Auth
      final fallbackUserDetails = UserDetails(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );

      debugPrint('✅ UserDetails créé depuis Firebase Auth: ${fallbackUserDetails.displayName}');
      return fallbackUserDetails;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur critique getUserProfile: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Nettoyer et valider les strings depuis Firestore
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static Future<AuthResult> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'firstName': firstName,
          'lastName': lastName,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await user.updateDisplayName('$firstName $lastName');

        return AuthResult.success();
      }
      return AuthResult.error('Utilisateur non connecté');
    } catch (e) {
      return AuthResult.error('Erreur lors de la mise à jour: $e');
    }
  }

  static Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Profil utilisateur créé dans Firestore');
    } catch (e) {
      debugPrint('❌ Erreur création profil Firestore: $e');
      // Ne pas faire échouer la création du compte pour ça
    }
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse email';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cette adresse email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      case 'requires-recent-login':
        return 'Cette action nécessite une connexion récente';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}

// ------------------- Classe AuthResult -------------------

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  AuthResult.success() : isSuccess = true, errorMessage = null;
  AuthResult.error(this.errorMessage) : isSuccess = false;
}