// lib/features/dashboard/dashboard_controller.dart
import 'package:flutter/material.dart';
import '../../core/services/vehicle_service.dart';
import '../../core/services/document_service.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/document.dart';

class DashboardController extends ChangeNotifier {
  // État du dashboard
  List<CarModel> _vehicles = [];
  List<DocumentModel> _allDocuments = [];
  List<ExpirationAlert> _expirationAlerts = [];
  List<ActivityLog> _recentActivities = [];
  DashboardMetrics _metrics = DashboardMetrics.empty();
  bool _isLoading = true;
  String? _error;

  // Getters
  List<CarModel> get vehicles => _vehicles;
  List<ExpirationAlert> get expirationAlerts => _expirationAlerts;
  List<ActivityLog> get recentActivities => _recentActivities;
  DashboardMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUrgentAlerts => _expirationAlerts.any((a) => a.isUrgent);

  // Initialisation du dashboard
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadVehicles(),
        _loadDocuments(),
      ]);

      _calculateMetrics();
      _generateExpirationAlerts();
      _generateRecentActivities();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur initialisation dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rafraîchir les données
  Future<void> refresh() async {
    await initialize();
  }

  // Charger tous les véhicules
  Future<void> _loadVehicles() async {
    final stream = VehicleService.getUserVehicles();
    final vehicles = await stream.first;
    _vehicles = vehicles;
  }

  // Charger tous les documents de tous les véhicules
  Future<void> _loadDocuments() async {
    _allDocuments.clear();

    for (final vehicle in _vehicles) {
      try {
        final docs = await DocumentService.getDocuments(vehicle.id);
        _allDocuments.addAll(docs);
      } catch (e) {
        debugPrint('Erreur chargement documents pour ${vehicle.id}: $e');
      }
    }
  }

  // Calculer les métriques du dashboard
  void _calculateMetrics() {
    final now = DateTime.now();

    // Documents expirés
    final expiredDocs = _allDocuments.where((doc) {
      return doc.expiryDate != null && doc.expiryDate!.isBefore(now);
    }).length;

    // Documents expirant sous 30 jours
    final expiringSoon = _allDocuments.where((doc) {
      if (doc.expiryDate == null) return false;
      final daysLeft = doc.expiryDate!.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= 30;
    }).length;

    // Documents valides
    final validDocs = _allDocuments.where((doc) {
      if (doc.expiryDate == null) return true;
      return doc.expiryDate!.isAfter(now.add(const Duration(days: 30)));
    }).length;

    // Dernier ajout de véhicule
    DateTime? lastVehicleAdded;
    if (_vehicles.isNotEmpty) {
      // Supposons que CarModel a un champ dateAdded
      // Sinon, utilisez une date fictive ou supprimez cette métrique
      lastVehicleAdded = now.subtract(const Duration(days: 2));
    }

    // Total taille des documents (si disponible)
    int totalStorageUsed = 0;
    // Si votre DocumentModel a un champ fileSize, utilisez-le
    // totalStorageUsed = _allDocuments.fold(0, (sum, doc) => sum + (doc.fileSize ?? 0));

    _metrics = DashboardMetrics(
      totalVehicles: _vehicles.length,
      totalDocuments: _allDocuments.length,
      expiredDocuments: expiredDocs,
      expiringSoonDocuments: expiringSoon,
      validDocuments: validDocs,
      urgentAlerts: expiredDocs + expiringSoon,
      lastVehicleAdded: lastVehicleAdded,
      totalStorageUsed: totalStorageUsed,
    );
  }

  // Générer les alertes d'expiration
  void _generateExpirationAlerts() {
    _expirationAlerts.clear();
    final now = DateTime.now();

    for (final doc in _allDocuments) {
      if (doc.expiryDate == null) continue;

      final daysLeft = doc.expiryDate!.difference(now).inDays;

      // Document expiré
      if (daysLeft < 0) {
        _expirationAlerts.add(ExpirationAlert(
          documentId: doc.id,
          documentName: doc.name,
          documentType: doc.type,
          vehicleId: doc.vehicleId,
          expiryDate: doc.expiryDate!,
          daysLeft: daysLeft,
          severity: AlertSeverity.critical,
          message: 'Expiré depuis ${daysLeft.abs()} jour(s)',
        ));
      }
      // Expire dans moins de 7 jours
      else if (daysLeft <= 7) {
        _expirationAlerts.add(ExpirationAlert(
          documentId: doc.id,
          documentName: doc.name,
          documentType: doc.type,
          vehicleId: doc.vehicleId,
          expiryDate: doc.expiryDate!,
          daysLeft: daysLeft,
          severity: AlertSeverity.urgent,
          message: 'Expire dans $daysLeft jour(s)',
        ));
      }
      // Expire dans moins de 30 jours
      else if (daysLeft <= 30) {
        _expirationAlerts.add(ExpirationAlert(
          documentId: doc.id,
          documentName: doc.name,
          documentType: doc.type,
          vehicleId: doc.vehicleId,
          expiryDate: doc.expiryDate!,
          daysLeft: daysLeft,
          severity: AlertSeverity.warning,
          message: 'Expire dans $daysLeft jour(s)',
        ));
      }
    }

    // Trier par urgence (critiques en premier)
    _expirationAlerts.sort((a, b) {
      if (a.severity != b.severity) {
        return a.severity.index.compareTo(b.severity.index);
      }
      return a.daysLeft.compareTo(b.daysLeft);
    });
  }

  // Générer le journal d'activité récente
  void _generateRecentActivities() {
    _recentActivities.clear();

    // 1️⃣ Connexion
    _recentActivities.add(ActivityLog(
      id: 'login_${DateTime.now().millisecondsSinceEpoch}',
      type: ActivityType.login,
      title: 'Connexion réussie',
      description: 'Dernière connexion',
      timestamp: DateTime.now(),
      icon: Icons.login_rounded,
    ));

    // 2️⃣ Documents récents
    final recentDocs = _allDocuments.where((doc) {
      final daysSinceAdded = DateTime.now().difference(doc.dateAdded).inDays;
      return daysSinceAdded <= 7;
    }).toList();

    recentDocs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

    for (final doc in recentDocs.take(5)) {
      final vehicle = _vehicles.firstWhere(
            (v) => v.id == doc.vehicleId,
        orElse: () => CarModel(
          id: '',
          brand: 'Inconnu',
          model: '',
          licensePlate: '',
          year: 0,
          mileage: 0,
          purchaseDate: DateTime.now(),
          insuranceExpiry: DateTime.now(),
          inspectionExpiry: DateTime.now(),
          registrationNumber: '',
          photoUrl: null,
        ),
      );

      _recentActivities.add(ActivityLog(
        id: 'doc_${doc.id}',
        type: ActivityType.documentAdded,
        title: 'Document ajouté',
        description: '${doc.name} - ${vehicle.brand} ${vehicle.model}',
        timestamp: doc.dateAdded,
        icon: Icons.upload_file_rounded,
      ));
    }

    // 3️⃣ Alertes
    for (final alert in _expirationAlerts.take(3)) {
      if (alert.isUrgent) {
        _recentActivities.add(ActivityLog(
          id: 'alert_${alert.documentId}',
          type: ActivityType.alert,
          title: 'Attention requise',
          description: '${alert.documentName} ${alert.message.toLowerCase()}',
          timestamp: DateTime.now(),
          icon: Icons.warning_rounded,
        ));
      }
    }

    // 4️⃣ Tri final
    _recentActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _recentActivities = _recentActivities.take(10).toList();
  }

  // Obtenir un véhicule par son ID
  CarModel? getVehicleById(String vehicleId) {
    try {
      return _vehicles.firstWhere((v) => v.id == vehicleId);
    } catch (e) {
      return null;
    }
  }

  // Obtenir les documents d'un véhicule spécifique
  List<DocumentModel> getVehicleDocuments(String vehicleId) {
    return _allDocuments.where((doc) => doc.vehicleId == vehicleId).toList();
  }

  // Obtenir le texte de la dernière activité
  String getLastActivityText() {
    if (_recentActivities.isEmpty) return '-';

    final lastActivity = _recentActivities.first;
    final diff = DateTime.now().difference(lastActivity.timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}j';
    }
  }

  // Marquer une alerte comme lue
  void dismissAlert(String documentId) {
    _expirationAlerts.removeWhere((alert) => alert.documentId == documentId);
    notifyListeners();
  }

  // Nettoyer les ressources
  @override
  void dispose() {
    super.dispose();
  }
}

// Modèles de données pour le dashboard

class DashboardMetrics {
  final int totalVehicles;
  final int totalDocuments;
  final int expiredDocuments;
  final int expiringSoonDocuments;
  final int validDocuments;
  final int urgentAlerts;
  final DateTime? lastVehicleAdded;
  final int totalStorageUsed;

  DashboardMetrics({
    required this.totalVehicles,
    required this.totalDocuments,
    required this.expiredDocuments,
    required this.expiringSoonDocuments,
    required this.validDocuments,
    required this.urgentAlerts,
    this.lastVehicleAdded,
    required this.totalStorageUsed,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalVehicles: 0,
      totalDocuments: 0,
      expiredDocuments: 0,
      expiringSoonDocuments: 0,
      validDocuments: 0,
      urgentAlerts: 0,
      totalStorageUsed: 0,
    );
  }

  double get documentHealthScore {
    if (totalDocuments == 0) return 100.0;
    final healthyDocs = validDocuments + expiringSoonDocuments;
    return (healthyDocs / totalDocuments * 100).clamp(0.0, 100.0);
  }

  String get healthScoreLabel {
    final score = documentHealthScore;
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Bon';
    if (score >= 50) return 'Moyen';
    return 'À améliorer';
  }
}

class ExpirationAlert {
  final String documentId;
  final String documentName;
  final String documentType;
  final String vehicleId;
  final DateTime expiryDate;
  final int daysLeft;
  final AlertSeverity severity;
  final String message;

  ExpirationAlert({
    required this.documentId,
    required this.documentName,
    required this.documentType,
    required this.vehicleId,
    required this.expiryDate,
    required this.daysLeft,
    required this.severity,
    required this.message,
  });

  bool get isExpired => daysLeft < 0;
  bool get isUrgent => daysLeft <= 7 || isExpired;

  Color get color {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.urgent:
        return const Color(0xFFF59E0B);
      case AlertSeverity.warning:
        return const Color(0xFFFBBF24);
      case AlertSeverity.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get icon {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.urgent:
        return Icons.warning_rounded;
      case AlertSeverity.warning:
        return Icons.info_rounded;
      case AlertSeverity.info:
        return Icons.notifications_rounded;
    }
  }
}

enum AlertSeverity {
  critical, // Expiré
  urgent,   // Expire dans moins de 7 jours
  warning,  // Expire dans moins de 30 jours
  info,     // Information générale
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;

  ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return 'Il y a ${(diff.inDays / 7).floor()} semaine(s)';
    }
  }

  Color get iconColor {
    switch (type) {
      case ActivityType.login:
        return const Color(0xFF3B82F6);
      case ActivityType.documentAdded:
        return const Color(0xFF10B981);
      case ActivityType.documentExpiring:
        return const Color(0xFFF59E0B);
      case ActivityType.alert:
        return const Color(0xFFEF4444);
      case ActivityType.vehicleAdded:
        return const Color(0xFF8B5CF6);
      case ActivityType.maintenance:
        return const Color(0xFF06B6D4);
    }
  }
}

enum ActivityType {
  login,
  documentAdded,
  documentExpiring,
  alert,
  vehicleAdded,
  maintenance,
}