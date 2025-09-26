// Notifications utilities
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/vehicle.dart';
import '../models/document.dart';
import 'date_helper.dart';

class NotificationsHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialise le système de notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser les fuseaux horaires
    tz.initializeTimeZones();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Demande les permissions de notification (iOS)
  static Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return result ?? false;
  }

  /// Planifie une notification pour l'expiration d'un document
  static Future<void> scheduleDocumentExpiryNotification({
    required String vehicleId,
    required DocumentModel document,
    required String vehicleName,
    int daysBefore = 30,
  }) async {
    await initialize();

    if (document.expiryDate == null) return;

    final notificationDate = document.expiryDate!.subtract(Duration(days: daysBefore));

    // Ne pas programmer si la date est déjà passée
    if (notificationDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'document_expiry',
      'Expiration de documents',
      channelDescription: 'Notifications pour l\'expiration des documents',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'document_expiry',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _generateNotificationId(vehicleId, document.id, 'expiry');

    await _notifications.zonedSchedule(
      id,
      '📋 Document expire bientôt',
      '${document.type.toUpperCase()} de $vehicleName expire le ${document.expiryDate!.toShortString()}',
      tz.TZDateTime.from(notificationDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'document_expiry:$vehicleId:${document.id}',
    );
  }

  /// Planifie une notification pour l'assurance d'un véhicule
  static Future<void> scheduleInsuranceExpiryNotification({
    required CarModel vehicle,
    int daysBefore = 15,
  }) async {
    await initialize();

    final notificationDate = vehicle.insuranceExpiry.subtract(Duration(days: daysBefore));

    if (notificationDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'insurance_expiry',
      'Expiration d\'assurance',
      channelDescription: 'Notifications pour l\'expiration des assurances',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'insurance_expiry',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _generateNotificationId(vehicle.id, 'insurance', 'expiry');

    await _notifications.zonedSchedule(
      id,
      '🚗 Assurance expire bientôt',
      'L\'assurance de ${vehicle.brand} ${vehicle.model} expire le ${vehicle.insuranceExpiry.toShortString()}',
      tz.TZDateTime.from(notificationDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'insurance_expiry:${vehicle.id}',
    );
  }

  /// Planifie une notification pour le contrôle technique
  static Future<void> scheduleInspectionExpiryNotification({
    required CarModel vehicle,
    int daysBefore = 30,
  }) async {
    await initialize();

    final notificationDate = vehicle.inspectionExpiry.subtract(Duration(days: daysBefore));

    if (notificationDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'inspection_expiry',
      'Contrôle technique',
      channelDescription: 'Notifications pour le contrôle technique',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'inspection_expiry',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _generateNotificationId(vehicle.id, 'inspection', 'expiry');

    await _notifications.zonedSchedule(
      id,
      '🔧 Contrôle technique requis',
      'Le contrôle technique de ${vehicle.brand} ${vehicle.model} expire le ${vehicle.inspectionExpiry.toShortString()}',
      tz.TZDateTime.from(notificationDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'inspection_expiry:${vehicle.id}',
    );
  }

  /// Planifie toutes les notifications pour un véhicule
  static Future<void> scheduleAllVehicleNotifications(CarModel vehicle) async {
    await scheduleInsuranceExpiryNotification(vehicle: vehicle);
    await scheduleInspectionExpiryNotification(vehicle: vehicle);
  }

  /// Annule toutes les notifications pour un véhicule
  static Future<void> cancelVehicleNotifications(String vehicleId) async {
    await initialize();

    // Annuler les notifications d'assurance et de contrôle technique
    final insuranceId = _generateNotificationId(vehicleId, 'insurance', 'expiry');
    final inspectionId = _generateNotificationId(vehicleId, 'inspection', 'expiry');

    await _notifications.cancel(insuranceId);
    await _notifications.cancel(inspectionId);
  }

  /// Annule une notification de document
  static Future<void> cancelDocumentNotification(String vehicleId, String documentId) async {
    await initialize();
    final id = _generateNotificationId(vehicleId, documentId, 'expiry');
    await _notifications.cancel(id);
  }

  /// Affiche une notification immédiate
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'immediate',
      'Notifications immédiates',
      channelDescription: 'Notifications affichées immédiatement',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Récupère toutes les notifications en attente
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  /// Annule toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await initialize();
    await _notifications.cancelAll();
  }

  /// Génère un ID unique pour une notification
  static int _generateNotificationId(String vehicleId, String type, String action) {
    final combined = '$vehicleId:$type:$action';
    return combined.hashCode.abs().remainder(2147483647); // Max int32
  }

  /// Gestionnaire de tap sur notification
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Traiter le payload selon le type de notification
    final parts = payload.split(':');
    if (parts.isEmpty) return;

    switch (parts[0]) {
      case 'document_expiry':
      // Navigation vers les documents du véhicule
        if (parts.length >= 2) {
          final vehicleId = parts[1];
          // TODO: Naviguer vers DocumentListPage(vehicleId: vehicleId)
        }
        break;
      case 'insurance_expiry':
      case 'inspection_expiry':
      // Navigation vers le détail du véhicule
        if (parts.length >= 2) {
          final vehicleId = parts[1];
          // TODO: Naviguer vers VehicleDetailPage(vehicle: vehicleId)
        }
        break;
    }
  }
}

/// Classe utilitaire pour les rappels périodiques
class ReminderScheduler {
  /// Programme tous les rappels pour un utilisateur
  static Future<void> scheduleAllReminders({
    required List<CarModel> vehicles,
    required List<DocumentModel> documents,
  }) async {
    // Annuler toutes les notifications existantes
    await NotificationsHelper.cancelAllNotifications();

    // Programmer les notifications pour chaque véhicule
    for (final vehicle in vehicles) {
      await NotificationsHelper.scheduleAllVehicleNotifications(vehicle);
    }

    // Programmer les notifications pour chaque document
    for (final document in documents) {
      // Trouver le véhicule correspondant
      final vehicle = vehicles.firstWhere((v) => v.id == document.id, orElse: () => vehicles.first);
      await NotificationsHelper.scheduleDocumentExpiryNotification(
        vehicleId: vehicle.id,
        document: document,
        vehicleName: '${vehicle.brand} ${vehicle.model}',
      );
    }
  }
}

/// Types de notification
enum NotificationType {
  documentExpiry,
  insuranceExpiry,
  inspectionExpiry,
  maintenanceReminder,
}

/// Configuration des notifications
class NotificationConfig {
  final NotificationType type;
  final int daysBefore;
  final bool enabled;

  const NotificationConfig({
    required this.type,
    required this.daysBefore,
    this.enabled = true,
  });

  static const List<NotificationConfig> defaultConfigs = [
    NotificationConfig(type: NotificationType.documentExpiry, daysBefore: 30),
    NotificationConfig(type: NotificationType.insuranceExpiry, daysBefore: 15),
    NotificationConfig(type: NotificationType.inspectionExpiry, daysBefore: 30),
    NotificationConfig(type: NotificationType.maintenanceReminder, daysBefore: 7),
  ];
}