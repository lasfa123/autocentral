// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de l'état d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  static User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // Inscription avec email et mot de passe
  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Créer le compte utilisateur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Créer le profil utilisateur dans Firestore
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
        );

        // Mettre à jour le nom d'affichage
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

  // Connexion avec email et mot de passe
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

  // Déconnexion
  static Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Erreur lors de la déconnexion: $e');
    }
  }

  // Réinitialiser le mot de passe
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

  // Supprimer le compte
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Supprimer les données utilisateur de Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Supprimer le compte Firebase Auth
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

  // Vérifier si l'email est vérifié
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Envoyer un email de vérification
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

  // Recharger les informations utilisateur
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Obtenir le profil utilisateur depuis Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  static Future<AuthResult> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Mettre à jour Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'firstName': firstName,
          'lastName': lastName,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour le nom d'affichage Firebase Auth
        await user.updateDisplayName('$firstName $lastName');

        return AuthResult.success();
      }
      return AuthResult.error('Utilisateur non connecté');
    } catch (e) {
      return AuthResult.error('Erreur lors de la mise à jour: $e');
    }
  }

  // Créer le profil utilisateur dans Firestore
  static Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Gérer les erreurs Firebase Auth
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
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}

// Classe pour encapsuler les résultats d'authentification
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  AuthResult.success() : isSuccess = true, errorMessage = null;
  AuthResult.error(this.errorMessage) : isSuccess = false;
}// Firebase Auth service