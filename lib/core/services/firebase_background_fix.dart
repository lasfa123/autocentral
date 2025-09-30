// lib/core/services/firebase_background_service.dart
// Service pour gérer Firebase en arrière-plan

import 'dart:async';
import 'package:autocentral/core/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_service.dart';
import '../models/vehicle.dart';

class FirebaseBackgroundService {
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<List<CarModel>>? _vehiclesSubscription;
  static bool _isListening = false;
  
  /// Démarre l'écoute des changements Firebase
  static Future<void> startListening() async {
    if (_isListening) return;
    
    debugPrint('🔥 Démarrage des listeners Firebase');
    
    // Écouter les changements d'authentification
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        debugPrint('🔐 Auth state changed: ${user?.uid}');
        if (user != null) {
          _startVehicleListening();
        } else {
          _stopVehicleListening();
        }
      },
      onError: (error) {
        debugPrint('❌ Erreur auth listener: $error');
        _reconnectAuth();
      },
    );
    
    _isListening = true;
  }
  
  /// Arrête l'écoute des changements Firebase
  static Future<void> stopListening() async {
    debugPrint('🔥 Arrêt des listeners Firebase');
    
    await _authSubscription?.cancel();
    await _vehiclesSubscription?.cancel();
    
    _authSubscription = null;
    _vehiclesSubscription = null;
    _isListening = false;
  }
  
  /// Démarre l'écoute des véhicules
  static void _startVehicleListening() {
    debugPrint('🚗 Démarrage listener véhicules');
    
    _vehiclesSubscription = VehicleService.getUserVehicles().listen(
      (List<CarModel> vehicles) {
        debugPrint('🚗 Véhicules mis à jour: ${vehicles.length}');
        // Ici vous pouvez notifier vos widgets via Provider/Bloc
        _notifyVehiclesUpdated(vehicles);
      },
      onError: (error) {
        debugPrint('❌ Erreur vehicles listener: $error');
        _reconnectVehicles();
      },
    );
  }
  
  /// Arrête l'écoute des véhicules
  static void _stopVehicleListening() {
    _vehiclesSubscription?.cancel();
    _vehiclesSubscription = null;
  }
  
  /// Reconnecte le listener auth en cas d'erreur
  static void _reconnectAuth() {
    Timer(const Duration(seconds: 3), () {
      if (_isListening) {
        debugPrint('🔄 Reconnexion auth listener...');
        _authSubscription?.cancel();
        startListening();
      }
    });
  }
  
  /// Reconnecte le listener véhicules en cas d'erreur
  static void _reconnectVehicles() {
    Timer(const Duration(seconds: 3), () {
      if (_isListening && FirebaseAuth.instance.currentUser != null) {
        debugPrint('🔄 Reconnexion vehicles listener...');
        _stopVehicleListening();
        _startVehicleListening();
      }
    });
  }
  
  /// Notifie les widgets des changements de véhicules
  static void _notifyVehiclesUpdated(List<CarModel> vehicles) {
    // Si vous utilisez Provider, notifiez ici
    // Provider.of<VehicleProvider>(context, listen: false).updateVehicles(vehicles);
    
    // Si vous utilisez un GlobalKey ou callback
    // VehicleNotifier.instance.notifyListeners();
  }
  
  /// Vérifie et répare la connexion Firebase
  static Future<void> checkAndRepairConnection() async {
    try {
      debugPrint('🔍 Vérification connexion Firebase...');
      
      // Test connexion Firestore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Transaction vide juste pour tester la connexion
      });
      
      // Test connexion Auth
      await FirebaseAuth.instance.currentUser?.reload();
      
      debugPrint('✅ Connexion Firebase OK');
      
      // Redémarrer les listeners si nécessaire
      if (!_isListening) {
        await startListening();
      }
      
    } catch (e) {
      debugPrint('❌ Problème connexion Firebase: $e');
      
      // Tenter de réparer
      await _repairConnection();
    }
  }
  
  /// Répare la connexion Firebase
  static Future<void> _repairConnection() async {
    debugPrint('🔧 Tentative de réparation connexion Firebase...');
    
    try {
      // Arrêter tous les listeners
      await stopListening();
      
      // Attendre un peu
      await Future.delayed(const Duration(seconds: 2));
      
      // Redémarrer les listeners
      await startListening();
      
      debugPrint('✅ Connexion Firebase réparée');
      
    } catch (e) {
      debugPrint('❌ Échec réparation Firebase: $e');
    }
  }
  
  /// Méthode à appeler quand l'app revient du background
  static Future<void> onAppResumed() async {
    debugPrint('🟢 App revenue du background - Vérification Firebase');
    
    // Vérifier et réparer la connexion
    await checkAndRepairConnection();
    
    // Force un refresh des données
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        // Trigger un nouveau fetch des véhicules
        final vehicles = await VehicleService.getUserVehiclesList();
        _notifyVehiclesUpdated(vehicles);
      } catch (e) {
        debugPrint('❌ Erreur refresh véhicules: $e');
      }
    }
  }
  
  /// Méthode à appeler quand l'app va en background
  static Future<void> onAppPaused() async {
    debugPrint('🟡 App en background - Sauvegarde état Firebase');
    
    // Optionnel : persister l'état actuel
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        // Sauvegarder les données importantes
        await SyncService.forceSync();
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde background: $e');
    }
  }
  
  /// Obtient l'état des listeners
  static Map<String, dynamic> getStatus() {
    return {
      'isListening': _isListening,
      'authSubscription': _authSubscription != null,
      'vehiclesSubscription': _vehiclesSubscription != null,
      'currentUser': FirebaseAuth.instance.currentUser?.uid,
    };
  }
}

// Extension pour votre main.dart
extension AppLifecycleHandler on State {
  void handleAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        FirebaseBackgroundService.onAppResumed();
        break;
      case AppLifecycleState.paused:
        FirebaseBackgroundService.onAppPaused();
        break;
      case AppLifecycleState.detached:
        FirebaseBackgroundService.stopListening();
        break;
      default:
        break;
    }
  }
}