// lib/core/services/document_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class DocumentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Limite Firestore : 1MB par document
  static const int maxFileSize = 1024 * 1024; // 1MB

  /// Upload d'un document encodé en Base64 (sans Firebase Storage)
  static Future<String?> uploadDocument({
    required String vehicleId,
    required String docType,
    required String fileName,
    required Uint8List fileData,
    DateTime? expiryDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Utilisateur non connecté");
      }

      if (fileData.isEmpty) {
        throw Exception("Aucun fichier sélectionné pour l'upload");
      }

      // Vérifier la taille du fichier
      if (fileData.length > maxFileSize) {
        throw Exception(
            "Fichier trop volumineux (${_formatFileSize(fileData.length)}). "
                "Maximum autorisé : ${_formatFileSize(maxFileSize)}.\n"
                "Pour des fichiers plus volumineux, passez au forfait Firebase Blaze."
        );
      }

      final userId = user.uid;

      // Encoder en Base64
      print('Encodage du fichier en Base64...');
      final base64Data = base64Encode(fileData);
      print('Fichier encodé : ${_formatFileSize(base64Data.length)} caractères');

      // Nettoyer le nom du fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '';
      final baseName = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      final safeBaseName = baseName
          .trim()
          .replaceAll(RegExp(r'[^\w\-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');

      final safeFileName = '${safeBaseName}_$timestamp$extension';

      // Enregistrer dans Firestore
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(vehicleId)
          .collection('documents')
          .doc();

      final docData = {
        'type': docType,
        'name': fileName,
        'storageName': safeFileName,
        'fileData': base64Data, // Données encodées
        'contentType': _getContentType(extension),
        'dateAdded': FieldValue.serverTimestamp(),
        'fileSize': fileData.length,
        if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate),
      };

      print('Enregistrement dans Firestore...');
      await docRef.set(docData);
      print('Document enregistré avec ID: ${docRef.id}');

      return docRef.id;
    } on FirebaseException catch (e) {
      print('Erreur Firebase: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'permission-denied':
          throw Exception('Permissions insuffisantes. Vérifiez les règles Firestore.');
        case 'unavailable':
          throw Exception('Service Firestore temporairement indisponible.');
        case 'unauthenticated':
          throw Exception('Non authentifié. Reconnectez-vous.');
        default:
          throw Exception('Erreur Firebase: ${e.message}');
      }
    } catch (e) {
      print('Erreur inattendue: $e');
      rethrow;
    }
  }

  /// Récupération de tous les documents liés à un véhicule
  static Future<List<DocumentModel>> getDocuments(String vehicleId) async {
    try {
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
    } catch (e) {
      print('Erreur récupération documents: $e');
      return [];
    }
  }

  /// Récupération des données brutes d'un document
  static Future<Uint8List?> getDocumentData(String vehicleId, String documentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cars')
          .doc(vehicleId)
          .collection('documents')
          .doc(documentId)
          .get();

      if (!doc.exists) {
        print('Document introuvable');
        return null;
      }

      final base64Data = doc.data()?['fileData'] as String?;
      if (base64Data == null) {
        print('Pas de données dans le document');
        return null;
      }

      print('Décodage du fichier...');
      return base64Decode(base64Data);
    } catch (e) {
      print('Erreur récupération données: $e');
      return null;
    }
  }

  /// Téléchargement d'un document (alias pour compatibilité)
  static Future<Uint8List?> downloadDocument(String vehicleId, String documentId) async {
    return getDocumentData(vehicleId, documentId);
  }

  /// Suppression d'un document
  static Future<void> deleteDocument({
    required String vehicleId,
    required String documentId,
    required String fileName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userId = user.uid;

      // Supprimer le document Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(vehicleId)
          .collection('documents')
          .doc(documentId)
          .delete();

      print('Document supprimé de Firestore');
    } catch (e) {
      print('Erreur suppression document: $e');
      rethrow;
    }
  }

  /// Obtenir le type MIME selon l'extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Formater la taille d'un fichier
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Obtenir la taille totale des documents d'un véhicule
  static Future<int> getTotalDocumentsSize(String vehicleId) async {
    try {
      final documents = await getDocuments(vehicleId);
      return documents.fold<int>(
        0,
            (sum, doc) {
          // Utiliser fileSize si disponible dans le modèle
          return sum + 0; // Ajustez selon votre modèle DocumentModel
        },
      );
    } catch (e) {
      print('Erreur calcul taille: $e');
      return 0;
    }
  }

  /// Vérifier si un fichier est trop volumineux
  static bool isFileSizeValid(int fileSize) {
    return fileSize <= maxFileSize;
  }

  /// Obtenir la taille maximale autorisée
  static String getMaxFileSizeFormatted() {
    return _formatFileSize(maxFileSize);
  }

/// Compresser une image si elle est trop volumineuse (optionnel)
/// Note: Nécessite le package flutter_image_compress

  static Future<Uint8List?> compressImage(Uint8List imageData) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageData,
        minHeight: 1920,
        minWidth: 1080,
        quality: 85,
      );
      return Uint8List.fromList(result);
    } catch (e) {
      print('Erreur compression: $e');
      return null;
    }
  }

}