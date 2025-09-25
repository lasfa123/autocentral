// Firestore document service
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document.dart';


class DocumentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadDocument({
    required String vehicleId,
    required String docType,
    required String fileName,
    required Uint8List fileData,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Stockage du fichier
    final ref = _storage.ref().child('users/$userId/cars/$vehicleId/documents/$fileName');
    await ref.putData(fileData);
    final url = await ref.getDownloadURL();

    // Enregistrement Firestore
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
    });

    return url;
  }

  static Future<List<DocumentModel>> getDocuments(String vehicleId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(vehicleId)
        .collection('documents')
        .get();

    return snapshot.docs
        .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
