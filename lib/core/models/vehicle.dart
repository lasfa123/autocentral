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
}
