// lib/core/services/sync_service.dart
// Service de synchronisation des données
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../models/document.dart';
import 'vehicle_service.dart';
import 'document_service.dart';

class SyncService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static Timer? _syncTimer;
  static bool _isInitialized = false;
  static bool _isSyncing = false;

  /// Initialise le service de synchronisation
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
          (ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          // Connexion rétablie, lancer une sync
          syncAll();
        }
      },
    );

    // Programmer une synchronisation périodique (toutes les 30 minutes)
    _syncTimer = Timer.periodic(
      const Duration(minutes: 30),
          (timer) => syncAll(),
    );

    _isInitialized = true;
    debugPrint('🔄 SyncService initialisé');
  }

  /// Arrête le service de synchronisation
  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _isInitialized = false;
  }

  /// Lance une synchronisation complète
  static Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult.error('Synchronisation déjà en cours');
    }

    _isSyncing = true;

    try {
      debugPrint('🔄 Début de la synchronisation...');

      // Vérifier la connectivité
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return SyncResult.error('Pas de connexion internet');
      }

      // Synchroniser les véhicules
      final vehicleSync = await _syncVehicles();
      if (!vehicleSync.isSuccess) {
        return vehicleSync;
      }

      // Synchroniser les documents
      final documentSync = await _syncDocuments();
      if (!documentSync.isSuccess) {
        return documentSync;
      }

      // Mettre à jour la dernière synchronisation
      await _updateLastSyncTime();

      debugPrint('✅ Synchronisation terminée avec succès');
      return SyncResult.success();

    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation: $e');
      return SyncResult.error('Erreur de synchronisation: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronise les véhicules
  static Future<SyncResult> _syncVehicles() async {
    try {
      // Récupérer les véhicules depuis Firestore
      final vehicles = await VehicleService.getUserVehiclesList();

      // Sauvegarder en local
      await _saveVehiclesLocally(vehicles);

      // Traiter les opérations en attente
      await _processPendingVehicleOperations();

      return SyncResult.success();
    } catch (e) {
      return SyncResult.error('Erreur sync véhicules: $e');
    }
  }

  /// Synchronise les documents
  static Future<SyncResult> _syncDocuments() async {
    try {
      final vehicles = await VehicleService.getUserVehiclesList();

      for (final vehicle in vehicles) {
        // Récupérer les documents de chaque véhicule
        final documents = await DocumentService.getDocuments(vehicle.id);

        // Sauvegarder en local
        await _saveDocumentsLocally(vehicle.id, documents);
      }

      // Traiter les opérations de documents en attente
      await _processPendingDocumentOperations();

      return SyncResult.success();
    } catch (e) {
      return SyncResult.error('Erreur sync documents: $e');
    }
  }

  /// Sauvegarde les véhicules en local
  static Future<void> _saveVehiclesLocally(List<CarModel> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    final vehiclesJson = vehicles.map((v) => {
      'id': v.id,
      'brand': v.brand,
      'model': v.model,
      'licensePlate': v.licensePlate,
      'year': v.year,
      'mileage': v.mileage,
      'purchaseDate': v.purchaseDate.toIso8601String(),
      'insuranceExpiry': v.insuranceExpiry.toIso8601String(),
      'inspectionExpiry': v.inspectionExpiry.toIso8601String(),
      'registrationNumber': v.registrationNumber,
      'photoUrl': v.photoUrl,
    }).toList();

    await prefs.setString('cached_vehicles', json.encode(vehiclesJson));
    await prefs.setString('vehicles_cache_time', DateTime.now().toIso8601String());
  }

  /// Récupère les documents depuis le cache local
  static Future<List<DocumentModel>> getCachedDocuments(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsString = prefs.getString('cached_documents_$vehicleId');

      if (documentsString == null) return [];

      final documentsJson = json.decode(documentsString) as List;
      return documentsJson.map((json) => DocumentModel(
        id: json['id'],
        vehicleId: json['vehicleId'] ?? vehicleId, // ✅ Ajouté : important pour le constructeur
        type: json['type'],
        name: json['name'],
        fileUrl: json['fileUrl'],
        dateAdded: DateTime.parse(json['dateAdded']),
        expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      )).toList();
    } catch (e) {
      debugPrint('Erreur lecture cache documents: $e');
      return [];
    }
  }

  /// Récupère les véhicules depuis le cache local
  static Future<List<CarModel>> getCachedVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehiclesString = prefs.getString('cached_vehicles');

      if (vehiclesString == null) return [];

      final vehiclesJson = json.decode(vehiclesString) as List;
      return vehiclesJson.map((json) => CarModel(
        id: json['id'],
        brand: json['brand'],
        model: json['model'],
        licensePlate: json['licensePlate'],
        year: json['year'],
        mileage: json['mileage'],
        purchaseDate: DateTime.parse(json['purchaseDate']),
        insuranceExpiry: DateTime.parse(json['insuranceExpiry']),
        inspectionExpiry: DateTime.parse(json['inspectionExpiry']),
        registrationNumber: json['registrationNumber'],
        photoUrl: json['photoUrl'],
      )).toList();
    } catch (e) {
      debugPrint('Erreur lecture cache véhicules: $e');
      return [];
    }
  }

  /// Sauvegarde les documents en local
  /// Sauvegarde les documents en local
  static Future<void> _saveDocumentsLocally(String vehicleId, List<DocumentModel> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = documents.map((d) => {
      'id': d.id,
      'vehicleId': d.vehicleId, // ✅ On sauvegarde aussi ce champ
      'type': d.type,
      'name': d.name,
      'fileUrl': d.fileUrl,
      'dateAdded': d.dateAdded.toIso8601String(),
      'expiryDate': d.expiryDate?.toIso8601String(),
    }).toList();

    await prefs.setString('cached_documents_$vehicleId', json.encode(documentsJson));
  }


  /// Ajoute une opération en attente
  static Future<void> addPendingOperation({
    required String type,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final operations = await _getPendingOperations();

    operations.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type, // 'vehicle' ou 'document'
      'operation': operation, // 'create', 'update', 'delete'
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString('pending_operations', json.encode(operations));
  }

  /// Récupère les opérations en attente
  static Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final operationsString = prefs.getString('pending_operations');

    if (operationsString == null) return [];

    try {
      return (json.decode(operationsString) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Traite les opérations de véhicules en attente
  static Future<void> _processPendingVehicleOperations() async {
    final operations = await _getPendingOperations();
    final vehicleOperations = operations.where((op) => op['type'] == 'vehicle').toList();

    for (final operation in vehicleOperations) {
      try {
        final opType = operation['operation'];
        final data = operation['data'];

        switch (opType) {
          case 'create':
          // Logique pour créer un véhicule
            debugPrint('🚗 Création véhicule en attente: ${data['licensePlate']}');
            break;
          case 'update':
          // Logique pour mettre à jour un véhicule
            debugPrint('🔄 Mise à jour véhicule: ${data['id']}');
            break;
          case 'delete':
          // Logique pour supprimer un véhicule
            debugPrint('🗑️ Suppression véhicule: ${data['id']}');
            break;
        }

        // Retirer l'opération de la liste
        await _removePendingOperation(operation['id']);

      } catch (e) {
        debugPrint('Erreur traitement opération véhicule: $e');
      }
    }
  }

  /// Traite les opérations de documents en attente
  static Future<void> _processPendingDocumentOperations() async {
    final operations = await _getPendingOperations();
    final documentOperations = operations.where((op) => op['type'] == 'document').toList();

    for (final operation in documentOperations) {
      try {
        final opType = operation['operation'];
        final data = operation['data'];

        switch (opType) {
          case 'create':
          // Logique pour créer un document
            debugPrint('📄 Création document en attente: ${data['name']}');
            break;
          case 'update':
          // Logique pour mettre à jour un document
            debugPrint('🔄 Mise à jour document: ${data['id']}');
            break;
          case 'delete':
          // Logique pour supprimer un document
            debugPrint('🗑️ Suppression document: ${data['id']}');
            break;
        }

        // Retirer l'opération de la liste
        await _removePendingOperation(operation['id']);

      } catch (e) {
        debugPrint('Erreur traitement opération document: $e');
      }
    }
  }

  /// Met à jour le timestamp de la dernière synchronisation
  static Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
  }

  /// Récupère le timestamp de la dernière synchronisation
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString('last_sync_time');

    if (lastSyncString == null) return null;

    try {
      return DateTime.parse(lastSyncString);
    } catch (e) {
      return null;
    }
  }

  /// Retire une opération en attente
  static Future<void> _removePendingOperation(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    final operations = await _getPendingOperations();

    operations.removeWhere((op) => op['id'] == operationId);

    await prefs.setString('pending_operations', json.encode(operations));
  }

  /// Vide le cache local
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Supprimer toutes les clés de cache
    final keys = prefs.getKeys().where((key) =>
    key.startsWith('cached_') ||
        key.startsWith('pending_') ||
        key == 'last_sync_time'
    ).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }

    debugPrint('🧹 Cache vidé');
  }

  /// Obtient des statistiques de synchronisation
  static Future<SyncStats> getSyncStats() async {
    final lastSync = await getLastSyncTime();
    final operations = await _getPendingOperations();
    final cachedVehicles = await getCachedVehicles();

    return SyncStats(
      lastSyncTime: lastSync,
      pendingOperations: operations.length,
      cachedVehicles: cachedVehicles.length,
      isSyncing: _isSyncing,
      isInitialized: _isInitialized,
    );
  }

  /// Force une synchronisation immédiate
  static Future<SyncResult> forceSync() async {
    debugPrint('🔄 Synchronisation forcée');
    return await syncAll();
  }

  /// Vérifie si une synchronisation est nécessaire
  static Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    // Sync nécessaire si plus de 1 heure
    return difference.inHours >= 1;
  }
}

// Classes pour les résultats de synchronisation
class SyncResult {
  final bool isSuccess;
  final String? errorMessage;
  final SyncData? data;

  SyncResult.success({this.data}) : isSuccess = true, errorMessage = null;
  SyncResult.error(this.errorMessage) : isSuccess = false, data = null;
}

class SyncData {
  final int vehicleCount;
  final int documentCount;
  final DateTime syncTime;

  SyncData({
    required this.vehicleCount,
    required this.documentCount,
    required this.syncTime,
  });
}

class SyncStats {
  final DateTime? lastSyncTime;
  final int pendingOperations;
  final int cachedVehicles;
  final bool isSyncing;
  final bool isInitialized;

  SyncStats({
    required this.lastSyncTime,
    required this.pendingOperations,
    required this.cachedVehicles,
    required this.isSyncing,
    required this.isInitialized,
  });

  String get statusText {
    if (isSyncing) return 'Synchronisation en cours...';
    if (!isInitialized) return 'Service non initialisé';
    if (lastSyncTime == null) return 'Jamais synchronisé';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Synchronisé il y a moins d\'une minute';
    } else if (difference.inMinutes < 60) {
      return 'Synchronisé il y a ${difference.inMinutes} minute(s)';
    } else if (difference.inHours < 24) {
      return 'Synchronisé il y a ${difference.inHours} heure(s)';
    } else {
      return 'Synchronisé il y a ${difference.inDays} jour(s)';
    }
  }

  bool get needsSync {
    if (lastSyncTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);
    return difference.inHours >= 1;
  }
}