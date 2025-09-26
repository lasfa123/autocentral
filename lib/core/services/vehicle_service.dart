// lib/core/services/vehicle_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/vehicle.dart';

class VehicleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference pour l'utilisateur actuel
  static CollectionReference? get _userVehiclesCollection {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('cars');
  }

  // Obtenir tous les véhicules de l'utilisateur (Stream temps réel)
  static Stream<List<CarModel>> getUserVehicles() {
    final collection = _userVehiclesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList())
        .handleError((error) {
      print('Erreur lors du chargement des véhicules: $error');
      return <CarModel>[];
    });
  }

  // Obtenir tous les véhicules de l'utilisateur (Future pour usage ponctuel)
  static Future<List<CarModel>> getUserVehiclesList() async {
    final collection = _userVehiclesCollection;
    if (collection == null) return [];

    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des véhicules: $e');
      return [];
    }
  }

  // Ajouter un véhicule
  static Future<VehicleResult> addVehicle(CarModel vehicle, {Uint8List? imageData}) async {
    final collection = _userVehiclesCollection;
    if (collection == null) {
      return VehicleResult.error('Utilisateur non connecté');
    }

    try {
      // Vérifier si le véhicule existe déjà (par plaque d'immatriculation)
      final existingVehicle = await collection
          .where('licensePlate', isEqualTo: vehicle.licensePlate)
          .get();

      if (existingVehicle.docs.isNotEmpty) {
        return VehicleResult.error('Un véhicule avec cette plaque d\'immatriculation existe déjà');
      }

      String? photoUrl;

      // Upload de la photo si fournie
      if (imageData != null) {
        final uploadResult = await _uploadVehiclePhoto(vehicle.licensePlate, imageData);
        if (uploadResult.isSuccess) {
          photoUrl = uploadResult.data;
        } else {
          return VehicleResult.error('Erreur lors de l\'upload de la photo: ${uploadResult.errorMessage}');
        }
      }

      // Créer le véhicule avec la photo URL
      final vehicleData = vehicle.copyWith(photoUrl: photoUrl).toMap();
      vehicleData['createdAt'] = FieldValue.serverTimestamp();
      vehicleData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await collection.add(vehicleData);

      return VehicleResult.success(data: docRef.id);
    } catch (e) {
      return VehicleResult.error('Erreur lors de l\'ajout du véhicule: $e');
    }
  }

  // Mettre à jour un véhicule
  static Future<VehicleResult> updateVehicle(String vehicleId, CarModel vehicle, {Uint8List? imageData}) async {
    final collection = _userVehiclesCollection;
    if (collection == null) {
      return VehicleResult.error('Utilisateur non connecté');
    }

    try {
      // Vérifier si le véhicule existe
      final doc = await collection.doc(vehicleId).get();
      if (!doc.exists) {
        return VehicleResult.error('Véhicule non trouvé');
      }

      String? photoUrl = vehicle.photoUrl;

      // Upload de la nouvelle photo si fournie
      if (imageData != null) {
        final uploadResult = await _uploadVehiclePhoto(vehicle.licensePlate, imageData);
        if (uploadResult.isSuccess) {
          // Supprimer l'ancienne photo si elle existe
          if (vehicle.photoUrl != null) {
            await _deleteVehiclePhoto(vehicle.photoUrl!);
          }
          photoUrl = uploadResult.data;
        } else {
          return VehicleResult.error('Erreur lors de l\'upload de la photo: ${uploadResult.errorMessage}');
        }
      }

      // Mettre à jour le véhicule
      final vehicleData = vehicle.copyWith(photoUrl: photoUrl).toMap();
      vehicleData['updatedAt'] = FieldValue.serverTimestamp();

      await collection.doc(vehicleId).update(vehicleData);

      return VehicleResult.success();
    } catch (e) {
      return VehicleResult.error('Erreur lors de la mise à jour du véhicule: $e');
    }
  }

  // Supprimer un véhicule
  static Future<VehicleResult> deleteVehicle(String vehicleId) async {
    final collection = _userVehiclesCollection;
    if (collection == null) {
      return VehicleResult.error('Utilisateur non connecté');
    }

    try {
      // Récupérer le véhicule pour obtenir l'URL de la photo
      final doc = await collection.doc(vehicleId).get();
      if (!doc.exists) {
        return VehicleResult.error('Véhicule non trouvé');
      }

      final vehicleData = doc.data() as Map<String, dynamic>;
      final photoUrl = vehicleData['photoUrl'] as String?;

      // Supprimer la photo si elle existe
      if (photoUrl != null) {
        await _deleteVehiclePhoto(photoUrl);
      }

      // Supprimer tous les documents associés
      final documentsCollection = collection.doc(vehicleId).collection('documents');
      final documentsSnapshot = await documentsCollection.get();

      for (final docDoc in documentsSnapshot.docs) {
        final docData = docDoc.data();
        final fileUrl = docData['fileUrl'] as String?;

        // Supprimer le fichier du storage
        if (fileUrl != null) {
          await _deleteFileFromStorage(fileUrl);
        }

        // Supprimer le document de Firestore
        await docDoc.reference.delete();
      }

      // Supprimer le véhicule
      await collection.doc(vehicleId).delete();

      return VehicleResult.success();
    } catch (e) {
      return VehicleResult.error('Erreur lors de la suppression du véhicule: $e');
    }
  }

  // Obtenir un véhicule par ID
  static Future<CarModel?> getVehicleById(String vehicleId) async {
    final collection = _userVehiclesCollection;
    if (collection == null) return null;

    try {
      final doc = await collection.doc(vehicleId).get();
      if (doc.exists) {
        return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du véhicule: $e');
      return null;
    }
  }

  // Obtenir les véhicules avec des échéances proches (30 jours)
  static Future<List<CarModel>> getVehiclesWithUpcomingExpirations({int daysThreshold = 30}) async {
    final vehicles = await getUserVehiclesList();
    final now = DateTime.now();
    final thresholdDate = now.add(Duration(days: daysThreshold));

    return vehicles.where((vehicle) {
      final insuranceExpiring = vehicle.insuranceExpiry.isBefore(thresholdDate);
      final inspectionExpiring = vehicle.inspectionExpiry.isBefore(thresholdDate);
      return insuranceExpiring || inspectionExpiring;
    }).toList();
  }

  // Obtenir les véhicules avec des échéances expirées
  static Future<List<CarModel>> getVehiclesWithExpiredDocuments() async {
    final vehicles = await getUserVehiclesList();
    final now = DateTime.now();

    return vehicles.where((vehicle) {
      final insuranceExpired = vehicle.insuranceExpiry.isBefore(now);
      final inspectionExpired = vehicle.inspectionExpiry.isBefore(now);
      return insuranceExpired || inspectionExpired;
    }).toList();
  }

  // Rechercher des véhicules
  static Future<List<CarModel>> searchVehicles(String query) async {
    final vehicles = await getUserVehiclesList();
    final queryLower = query.toLowerCase();

    return vehicles.where((vehicle) {
      return vehicle.brand.toLowerCase().contains(queryLower) ||
          vehicle.model.toLowerCase().contains(queryLower) ||
          vehicle.licensePlate.toLowerCase().contains(queryLower) ||
          vehicle.registrationNumber.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Obtenir des statistiques sur les véhicules
  static Future<VehicleStats> getVehicleStats() async {
    try {
      final vehicles = await getUserVehiclesList();
      final now = DateTime.now();

      int totalVehicles = vehicles.length;
      int expiredDocuments = 0;
      int upcomingExpirations = 0;
      double totalMileage = 0;
      int oldestYear = DateTime.now().year;
      int newestYear = 0;

      for (final vehicle in vehicles) {
        // Calculs sur les échéances
        if (vehicle.insuranceExpiry.isBefore(now) || vehicle.inspectionExpiry.isBefore(now)) {
          expiredDocuments++;
        }

        final thirtyDaysFromNow = now.add(const Duration(days: 30));
        if (vehicle.insuranceExpiry.isBefore(thirtyDaysFromNow) ||
            vehicle.inspectionExpiry.isBefore(thirtyDaysFromNow)) {
          upcomingExpirations++;
        }

        // Calculs sur les années et kilométrage
        totalMileage += vehicle.mileage;
        if (vehicle.year < oldestYear) oldestYear = vehicle.year;
        if (vehicle.year > newestYear) newestYear = vehicle.year;
      }

      return VehicleStats(
        totalVehicles: totalVehicles,
        expiredDocuments: expiredDocuments,
        upcomingExpirations: upcomingExpirations,
        averageMileage: totalVehicles > 0 ? totalMileage / totalVehicles : 0,
        oldestVehicleYear: totalVehicles > 0 ? oldestYear : 0,
        newestVehicleYear: totalVehicles > 0 ? newestYear : 0,
      );
    } catch (e) {
      return VehicleStats(
        totalVehicles: 0,
        expiredDocuments: 0,
        upcomingExpirations: 0,
        averageMileage: 0,
        oldestVehicleYear: 0,
        newestVehicleYear: 0,
      );
    }
  }

  // Méthodes privées pour la gestion des fichiers

  static Future<VehicleResult> _uploadVehiclePhoto(String licensePlate, Uint8List imageData) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return VehicleResult.error('Utilisateur non connecté');

      final fileName = 'vehicle_${licensePlate}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/vehicles/$fileName');

      await ref.putData(imageData);
      final downloadUrl = await ref.getDownloadURL();

      return VehicleResult.success(data: downloadUrl);
    } catch (e) {
      return VehicleResult.error('Erreur lors de l\'upload: $e');
    }
  }

  static Future<void> _deleteVehiclePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Erreur lors de la suppression de la photo: $e');
    }
  }

  static Future<void> _deleteFileFromStorage(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Erreur lors de la suppression du fichier: $e');
    }
  }
}

// Classes pour les résultats et statistiques
class VehicleResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? data;

  VehicleResult.success({this.data}) : isSuccess = true, errorMessage = null;
  VehicleResult.error(this.errorMessage) : isSuccess = false, data = null;
}

class VehicleStats {
  final int totalVehicles;
  final int expiredDocuments;
  final int upcomingExpirations;
  final double averageMileage;
  final int oldestVehicleYear;
  final int newestVehicleYear;

  VehicleStats({
    required this.totalVehicles,
    required this.expiredDocuments,
    required this.upcomingExpirations,
    required this.averageMileage,
    required this.oldestVehicleYear,
    required this.newestVehicleYear,
  });
}