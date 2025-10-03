// Document model
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String vehicleId; // ✅ Ajouté pour relier le document à un véhicule
  final String type; // assurance, visite, carte_grise, etc.
  final String name;
  final String fileUrl;
  final String? base64Data;
  final DateTime dateAdded;
  final DateTime? expiryDate;

  DocumentModel({
    required this.id,
    required this.vehicleId, // ✅ nouveau champ
    required this.type,
    required this.name,
    required this.fileUrl,
    this.base64Data,
    required this.dateAdded,
    this.expiryDate,
  });

  // Convertir Firestore -> DocumentModel
  factory DocumentModel.fromMap(Map<String, dynamic> map, String docId) {
    return DocumentModel(
      id: docId,
      vehicleId: map['vehicleId'] ?? '', // ✅ récupérer depuis Firestore
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      base64Data: map['fileData'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
      expiryDate: map['expiryDate'] != null
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
    );
  }

  // Convertir DocumentModel -> Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId, // ✅ inclure lors de l’enregistrement
      'type': type,
      'name': name,
      'fileUrl': fileUrl,
      if (base64Data != null) 'fileData': base64Data,
      'dateAdded': Timestamp.fromDate(dateAdded),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
    };
  }
}
