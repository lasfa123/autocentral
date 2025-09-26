import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  final String id;
  final String brand;
  final String model;
  final String licensePlate;
  final int year;
  final int mileage;
  final DateTime purchaseDate;
  final DateTime insuranceExpiry;
  final DateTime inspectionExpiry;
  final String registrationNumber;
  final String? photoUrl;

  CarModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.year,
    required this.mileage,
    required this.purchaseDate,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    required this.registrationNumber,
    this.photoUrl,
  });

  factory CarModel.fromMap(Map<String, dynamic> map, String docId) {
    return CarModel(
      id: docId,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      year: map['year'] ?? 0,
      mileage: map['mileage'] ?? 0,
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      insuranceExpiry: (map['insuranceExpiry'] as Timestamp).toDate(),
      inspectionExpiry: (map['inspectionExpiry'] as Timestamp).toDate(),
      registrationNumber: map['registrationNumber'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'licensePlate': licensePlate,
      'year': year,
      'mileage': mileage,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'insuranceExpiry': Timestamp.fromDate(insuranceExpiry),
      'inspectionExpiry': Timestamp.fromDate(inspectionExpiry),
      'registrationNumber': registrationNumber,
      'photoUrl': photoUrl,
    };
  }

  // Méthode copyWith pour créer une copie avec des modifications
  CarModel copyWith({
    String? id,
    String? brand,
    String? model,
    String? licensePlate,
    int? year,
    int? mileage,
    DateTime? purchaseDate,
    DateTime? insuranceExpiry,
    DateTime? inspectionExpiry,
    String? registrationNumber,
    String? photoUrl,
  }) {
    return CarModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      licensePlate: licensePlate ?? this.licensePlate,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  // Méthode pour vérifier si le véhicule a des documents expirés
  bool get hasExpiredDocuments {
    final now = DateTime.now();
    return insuranceExpiry.isBefore(now) || inspectionExpiry.isBefore(now);
  }

  // Méthode pour vérifier si le véhicule a des échéances proches
  bool get hasUpcomingExpirations {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return insuranceExpiry.isBefore(thirtyDaysFromNow) ||
        inspectionExpiry.isBefore(thirtyDaysFromNow);
  }

  // Obtenir le nombre de jours avant la prochaine échéance
  int get daysUntilNextExpiration {
    final now = DateTime.now();
    final insuranceDays = insuranceExpiry.difference(now).inDays;
    final inspectionDays = inspectionExpiry.difference(now).inDays;

    // Retourner la plus proche échéance (positive ou négative)
    if (insuranceDays < inspectionDays) {
      return insuranceDays;
    } else {
      return inspectionDays;
    }
  }

  // Obtenir le type de document qui expire le plus tôt
  String get nextExpiringDocumentType {
    final insuranceDays = insuranceExpiry.difference(DateTime.now()).inDays;
    final inspectionDays = inspectionExpiry.difference(DateTime.now()).inDays;

    if (insuranceDays < inspectionDays) {
      return 'assurance';
    } else {
      return 'controle_technique';
    }
  }

  // Méthode toString pour le debugging
  @override
  String toString() {
    return 'CarModel{id: $id, brand: $brand, model: $model, licensePlate: $licensePlate}';
  }

  // Méthode equals pour comparer les véhicules
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}