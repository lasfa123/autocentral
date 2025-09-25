// Document model
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String type; // assurance, visite, carte_grise, etc.
  final String name;
  final String fileUrl;
  final DateTime dateAdded;
  final DateTime? expiryDate;

  DocumentModel({
    required this.id,
    required this.type,
    required this.name,
    required this.fileUrl,
    required this.dateAdded,
    this.expiryDate,
  });

  // Convertir Firestore -> DocumentModel
  factory DocumentModel.fromMap(Map<String, dynamic> map, String docId) {
    return DocumentModel(
      id: docId,
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null,
    );
  }

  // Convertir DocumentModel -> Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'fileUrl': fileUrl,
      'dateAdded': Timestamp.fromDate(dateAdded),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
    };
  }
}
