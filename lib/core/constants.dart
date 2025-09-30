// lib/core/constants.dart
// Global constants

class AppConstants {
  // 🏢 Informations de l'application
  static const String appName = 'Gestion Véhicules';
  static const String appVersion = '1.0.0';

  // 📊 Collections Firestore
  static const String usersCollection = 'users';
  static const String carsCollection = 'cars';
  static const String documentsCollection = 'documents';

  // 📄 Types de documents
  static const String docTypeAssurance = 'assurance';
  static const String docTypeCarteGrise = 'carte_grise';
  static const String docTypeVisite = 'visite_technique';
  static const String docTypePermis = 'permis_conduire';
  static const String docTypeVignette = 'vignette';
  static const String docTypeAutre = 'autre';

  static const List<String> documentTypes = [
    docTypeAssurance,
    docTypeCarteGrise,
    docTypeVisite,
    docTypePermis,
    docTypeVignette,
    docTypeAutre,
  ];

  // 📅 Seuils de notification (en jours)
  static const int warningThresholdDays = 30;
  static const int criticalThresholdDays = 7;
  static const int expiredThresholdDays = 0;

  // 🚗 Marques de véhicules populaires
  static const List<String> popularBrands = [
    'Toyota',
    'Peugeot',
    'Renault',
    'Mercedes',
    'BMW',
    'Volkswagen',
    'Audi',
    'Ford',
    'Hyundai',
    'Kia',
    'Nissan',
    'Citroen',
    'Autre',
  ];

  // 📁 Dossiers de stockage
  static const String storageUserPath = 'users';
  static const String storageVehiclesPath = 'vehicles';
  static const String storageDocumentsPath = 'documents';

  // 📱 Paramètres de l'interface
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;

  // 🔢 Limites
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxVehiclesPerUser = 10;
  static const int maxDocumentsPerVehicle = 50;
  static const int maxImageQuality = 80;

  // 🎨 Couleurs d'état
  static const String colorExpired = '#F44336';
  static const String colorCritical = '#FF9800';
  static const String colorWarning = '#FFC107';
  static const String colorOk = '#4CAF50';

  // 📝 Formats de fichiers acceptés
  static const List<String> acceptedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> acceptedDocumentFormats = ['pdf', 'jpg', 'jpeg', 'png'];

  // 🔔 IDs des canaux de notification
  static const String notificationChannelId = 'vehicle_documents';
  static const String notificationChannelName = 'Documents de véhicules';
  static const String notificationChannelDescription = 'Notifications pour les échéances de documents';

  // ⚙️ Paramètres par défaut
  static const bool defaultNotificationsEnabled = true;
  static const int defaultNotificationDays = 30;
  static const bool defaultAutoBackup = true;

  // 🌐 Préférences utilisateur
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefNotificationDays = 'notification_days';
  static const String prefAutoBackup = 'auto_backup';
  static const String prefDarkMode = 'dark_mode';
  static const String prefLanguage = 'language';

  // 🔤 Expressions régulières
  static const String regexEmail = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String regexLicensePlate = r'^[A-Z0-9-]{1,10}$';
  static const String regexPhoneNumber = r'^(\+33|0)[1-9](\d{8})$';

  // 📊 Codes d'erreur
  static const String errorUserNotFound = 'USER_NOT_FOUND';
  static const String errorVehicleNotFound = 'VEHICLE_NOT_FOUND';
  static const String errorDocumentNotFound = 'DOCUMENT_NOT_FOUND';
  static const String errorPermissionDenied = 'PERMISSION_DENIED';
  static const String errorNetworkError = 'NETWORK_ERROR';
  static const String errorFileTooBig = 'FILE_TOO_BIG';
  static const String errorInvalidFormat = 'INVALID_FORMAT';

  // 💬 Messages d'erreur
  static const Map<String, String> errorMessages = {
    errorUserNotFound: 'Utilisateur non trouvé',
    errorVehicleNotFound: 'Véhicule non trouvé',
    errorDocumentNotFound: 'Document non trouvé',
    errorPermissionDenied: 'Permission refusée',
    errorNetworkError: 'Erreur de connexion',
    errorFileTooBig: 'Fichier trop volumineux (max 10MB)',
    errorInvalidFormat: 'Format de fichier non accepté',
  };

  // ✅ Messages de succès
  static const String successVehicleAdded = 'Véhicule ajouté avec succès';
  static const String successVehicleUpdated = 'Véhicule mis à jour avec succès';
  static const String successVehicleDeleted = 'Véhicule supprimé avec succès';
  static const String successDocumentAdded = 'Document ajouté avec succès';
  static const String successDocumentDeleted = 'Document supprimé avec succès';

  // 🔄 Messages de chargement
  static const String loadingVehicles = 'Chargement des véhicules...';
  static const String loadingDocuments = 'Chargement des documents...';
  static const String uploadingDocument = 'Upload du document...';
  static const String savingVehicle = 'Enregistrement du véhicule...';

  // 🎯 Actions
  static const String actionAdd = 'Ajouter';
  static const String actionEdit = 'Modifier';
  static const String actionDelete = 'Supprimer';
  static const String actionCancel = 'Annuler';
  static const String actionSave = 'Enregistrer';
  static const String actionView = 'Voir';
  static const String actionShare = 'Partager';

  // 📊 Statistiques par défaut
  static const Map<String, dynamic> defaultStats = {
    'totalVehicles': 0,
    'expiredDocuments': 0,
    'upcomingExpirations': 0,
    'averageMileage': 0.0,
    'oldestVehicleYear': 0,
    'newestVehicleYear': 0,
  };
}