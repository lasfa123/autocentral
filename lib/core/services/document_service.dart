// lib/core/services/document_service.dart
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document.dart';

class DocumentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload d’un document avec support de date d’expiration
  static Future<String?> uploadDocument({
    required String vehicleId,
    required String docType,
    required String fileName,
    required Uint8List fileData,
    DateTime? expiryDate, // ✅ nouveau paramètre
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final userId = user.uid;

    // 📁 Stockage du fichier
    final ref = _storage.ref().child('users/$userId/cars/$vehicleId/documents/$fileName');
    await ref.putData(fileData);
    final url = await ref.getDownloadURL();

    // 🗂️ Enregistrement dans Firestore
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(vehicleId)
        .collection('documents')
        .doc();

    await docRef.set({
      'type': docType,
      'name': fileName,
      'fileUrl': url,
      'dateAdded': Timestamp.now(),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate), // ✅ enregistré proprement
    });

    return url;
  }

  /// Récupération de tous les documents liés à un véhicule
  static Future<List<DocumentModel>> getDocuments(String vehicleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userId = user.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(vehicleId)
        .collection('documents')
        .orderBy('dateAdded', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Suppression d’un document
  static Future<void> deleteDocument({
    required String vehicleId,
    required String documentId,
    required String fileName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    // 🗑️ Supprimer le fichier
    final storageRef = _storage.ref().child('users/$userId/cars/$vehicleId/documents/$fileName');
    await storageRef.delete();

    // 🗑️ Supprimer la métadonnée Firestore
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(vehicleId)
        .collection('documents')
        .doc(documentId);
    await docRef.delete();
  }
}
