// (Optionnel) External API service
// lib/core/services/api_service.dart
// External API service
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';
// Import pour les calculs mathématiques
import 'dart:math' as math;
import 'dart:async';

class ApiService {
  // 🌐 Configuration des URLs d'API
  static const String _vehicleDataApi = 'https://vpic.nhtsa.dot.gov/api/vehicles';
  static const String _geoApi = 'https://api.opencagedata.com/geocode/v1';
  static const Duration _timeout = Duration(seconds: 30);

  // 🔑 Clés API (à configurer dans vos constantes)
  static const String _openCageApiKey = 'YOUR_OPENCAGE_API_KEY'; // À remplacer

  // Headers par défaut
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': '${AppConstants.appName}/${AppConstants.appVersion}',
  };

  /// 🚗 Récupère la liste des marques de véhicules depuis l'API NHTSA (gratuite)
  static Future<ApiResponse<List<String>>> getVehicleBrands() async {
    try {
      final response = await http.get(
        Uri.parse('$_vehicleDataApi/GetMakesForVehicleType/car?format=json'),
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['Results'] as List;

        final brands = results
            .map((item) => item['MakeName'].toString())
            .where((brand) => brand.isNotEmpty)
            .toSet() // Éliminer les doublons
            .toList();

        brands.sort(); // Trier alphabétiquement

        return ApiResponse.success(brands);
      } else {
        return ApiResponse.error('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      return ApiResponse.error('Pas de connexion internet');
    } on TimeoutException {
      return ApiResponse.error('Délai d\'attente dépassé');
    } catch (e) {
      debugPrint('Erreur getBrands: $e');
      return ApiResponse.error('Erreur inconnue: $e');
    }
  }

  /// 🔍 Récupère les modèles d'une marque spécifique
  static Future<ApiResponse<List<String>>> getVehicleModels(String brand) async {
    try {
      // Encoder le nom de la marque pour l'URL
      final encodedBrand = Uri.encodeComponent(brand);

      final response = await http.get(
        Uri.parse('$_vehicleDataApi/GetModelsForMake/$encodedBrand?format=json'),
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['Results'] as List;

        final models = results
            .map((item) => item['Model_Name'].toString())
            .where((model) => model.isNotEmpty)
            .toSet()
            .toList();

        models.sort();

        return ApiResponse.success(models);
      } else {
        return ApiResponse.error('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      return ApiResponse.error('Pas de connexion internet');
    } on TimeoutException {
      return ApiResponse.error('Délai d\'attente dépassé');
    } catch (e) {
      debugPrint('Erreur getModels: $e');
      return ApiResponse.error('Erreur inconnue: $e');
    }
  }

  /// 📅 Récupère les années disponibles pour une marque et un modèle
  static Future<ApiResponse<List<int>>> getVehicleYears(String brand, String model) async {
    try {
      final encodedBrand = Uri.encodeComponent(brand);
      final encodedModel = Uri.encodeComponent(model);

      final response = await http.get(
        Uri.parse('$_vehicleDataApi/GetModelsForMakeYear/make/$encodedBrand/modelyear/2024?format=json'),
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        // Pour simplifier, on retourne une liste d'années standard
        // Vous pouvez adapter selon l'API que vous utilisez
        final currentYear = DateTime.now().year;
        final years = List.generate(30, (index) => currentYear - index)
            .where((year) => year >= 1990)
            .toList();

        return ApiResponse.success(years);
      } else {
        return ApiResponse.error('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Erreur getYears: $e');
      // Retourner une liste par défaut en cas d'erreur
      final currentYear = DateTime.now().year;
      final years = List.generate(30, (index) => currentYear - index)
          .where((year) => year >= 1990)
          .toList();
      return ApiResponse.success(years);
    }
  }

  /// 🔍 Vérifie et récupère les informations d'un véhicule par VIN
  static Future<ApiResponse<VehicleInfo>> getVehicleInfoByVin(String vin) async {
    if (vin.length != 17) {
      return ApiResponse.error('Le VIN doit contenir exactement 17 caractères');
    }

    try {
      final response = await http.get(
        Uri.parse('$_vehicleDataApi/DecodeVin/$vin?format=json'),
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['Results'] as List;

        // Extraire les informations pertinentes
        String? make, model, year, engineType;

        for (final result in results) {
          final variable = result['Variable'] as String;
          final value = result['Value'] as String?;

          switch (variable) {
            case 'Make':
              make = value;
              break;
            case 'Model':
              model = value;
              break;
            case 'Model Year':
              year = value;
              break;
            case 'Engine Configuration':
              engineType = value;
              break;
          }
        }

        if (make != null && model != null && year != null) {
          final vehicleInfo = VehicleInfo(
            brand: make,
            model: model,
            year: int.tryParse(year) ?? 0,
            engineType: engineType,
            isValid: true,
          );

          return ApiResponse.success(vehicleInfo);
        } else {
          return ApiResponse.error('Informations du véhicule incomplètes');
        }
      } else {
        return ApiResponse.error('Erreur ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      return ApiResponse.error('Pas de connexion internet');
    } on TimeoutException {
      return ApiResponse.error('Délai d\'attente dépassé');
    } catch (e) {
      debugPrint('Erreur getVehicleInfoByVin: $e');
      return ApiResponse.error('Erreur inconnue: $e');
    }
  }

  /// 🌍 Géocodage d'une adresse (conversion adresse -> coordonnées)
  static Future<ApiResponse<LocationInfo>> geocodeAddress(String address) async {
    if (_openCageApiKey == 'YOUR_OPENCAGE_API_KEY') {
      return ApiResponse.error('Clé API géocodage non configurée');
    }

    try {
      final encodedAddress = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse('$_geoApi/json?q=$encodedAddress&key=$_openCageApiKey&language=fr&countrycode=fr'),
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final result = results.first;
          final geometry = result['geometry'];

          final locationInfo = LocationInfo(
            latitude: geometry['lat'].toDouble(),
            longitude: geometry['lng'].toDouble(),
            formattedAddress: result['formatted'] ?? address,
          );

          return ApiResponse.success(locationInfo);
        } else {
          return ApiResponse.error('Adresse non trouvée');
        }
      } else {
        return ApiResponse.error('Erreur géocodage: ${response.statusCode}');
      }
    } on SocketException {
      return ApiResponse.error('Pas de connexion internet');
    } on TimeoutException {
      return ApiResponse.error('Délai d\'attente dépassé');
    } catch (e) {
      debugPrint('Erreur geocodeAddress: $e');
      return ApiResponse.error('Erreur géocodage: $e');
    }
  }

  /// 📍 Géocodage inverse (coordonnées -> adresse)
  static Future<ApiResponse<String>> reverseGeocode(double latitude, double longitude) async {
    if (_openCageApiKey == 'YOUR_OPENCAGE_API_KEY') {
      return ApiResponse.error('Clé API géocodage non configurée');
    }

    try {
      final response = await http.get(
        Uri.parse('$_geoApi/json?q=$latitude+$longitude&key=$_openCageApiKey&language=fr'),
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final result = results.first;
          final formattedAddress = result['formatted'] as String;

          return ApiResponse.success(formattedAddress);
        } else {
          return ApiResponse.error('Adresse non trouvée');
        }
      } else {
        return ApiResponse.error('Erreur géocodage inverse: ${response.statusCode}');
      }
    } on SocketException {
      return ApiResponse.error('Pas de connexion internet');
    } on TimeoutException {
      return ApiResponse.error('Délai d\'attente dépassé');
    } catch (e) {
      debugPrint('Erreur reverseGeocode: $e');
      return ApiResponse.error('Erreur géocodage inverse: $e');
    }
  }

  /// 🔧 Recherche de garages/centres auto à proximité (API gratuite OSM)
  static Future<ApiResponse<List<Garage>>> findNearbyGarages({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    try {
      // Utilisation d'Overpass API (OpenStreetMap) - gratuite
      final query = '''
        [out:json][timeout:25];
        (
          node["shop"="car_repair"](around:$radiusMeters,$latitude,$longitude);
          node["amenity"="fuel"](around:$radiusMeters,$latitude,$longitude);
          node["shop"="car"](around:$radiusMeters,$latitude,$longitude);
        );
        out body;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'text/plain'},
        body: query,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List;

        final garages = elements.map((element) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final lat = element['lat']?.toDouble() ?? 0.0;
          final lon = element['lon']?.toDouble() ?? 0.0;

          // Calculer la distance
          final distance = _calculateDistance(latitude, longitude, lat, lon);

          return Garage(
            id: element['id'].toString(),
            name: tags['name'] ?? 'Garage sans nom',
            address: _buildAddress(tags),
            latitude: lat,
            longitude: lon,
            phone: tags['phone'],
            services: _extractServices(tags),
            distanceKm: distance,
          );
        }).where((garage) => garage.name != 'Garage sans nom').toList();

        // Trier par distance
        garages.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

        return ApiResponse.success(garages.take(20).toList());
      } else {
        return ApiResponse.error('Erreur recherche garages: ${response.statusCode}');
      }
    } on SocketException {
      return ApiResponse.error('Pas de connexion internet');
    } on TimeoutException {
      return ApiResponse.error('Délai d\'attente dépassé');
    } catch (e) {
      debugPrint('Erreur findNearbyGarages: $e');
      return ApiResponse.error('Erreur recherche garages: $e');
    }
  }

  /// 🌐 Vérifie la connectivité réseau
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 📊 Envoie des données d'analytics (optionnel - vers votre propre serveur)
  static Future<void> sendAnalytics({
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    try {
      // Remplacez par votre endpoint d'analytics
      const analyticsUrl = 'https://your-analytics-server.com/track';

      await http.post(
        Uri.parse(analyticsUrl),
        headers: _defaultHeaders,
        body: json.encode({
          'event': event,
          'properties': properties ?? {},
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': AppConstants.appVersion,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Ignorer silencieusement les erreurs d'analytics
      debugPrint('Analytics error (ignoré): $e');
    }
  }

  // 🧮 Méthodes utilitaires privées

  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:housenumber'] != null && tags['addr:street'] != null) {
      parts.add('${tags['addr:housenumber']} ${tags['addr:street']}');
    }
    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    }
    if (tags['addr:postcode'] != null) {
      parts.add(tags['addr:postcode']);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Adresse non disponible';
  }

  static List<String> _extractServices(Map<String, dynamic> tags) {
    final services = <String>[];

    if (tags['shop'] == 'car_repair') services.add('Réparation');
    if (tags['amenity'] == 'fuel') services.add('Station-service');
    if (tags['shop'] == 'car') services.add('Vente auto');
    if (tags['service:vehicle:inspection'] == 'yes') services.add('Contrôle technique');

    return services.isEmpty ? ['Services automobiles'] : services;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Formule de Haversine pour calculer la distance
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degToRad(double deg) {
    return deg * (math.pi / 180);
  }
}

// 📦 Classes pour les réponses API
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  ApiResponse.success(this.data) : isSuccess = true, error = null;
  ApiResponse.error(this.error) : isSuccess = false, data = null;
}

// 🚗 Modèle pour les informations de véhicule
class VehicleInfo {
  final String brand;
  final String model;
  final int year;
  final String? color;
  final String? engineType;
  final int? power;
  final bool isValid;

  VehicleInfo({
    required this.brand,
    required this.model,
    required this.year,
    this.color,
    this.engineType,
    this.power,
    this.isValid = true,
  });

  @override
  String toString() => '$brand $model ($year)';
}

// 📍 Modèle pour les informations de localisation
class LocationInfo {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  @override
  String toString() => formattedAddress;
}

// 🔧 Modèle pour les garages
class Garage {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final double? rating;
  final List<String> services;
  final double distanceKm;

  Garage({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.rating,
    required this.services,
    required this.distanceKm,
  });

  String get distanceText => '${distanceKm.toStringAsFixed(1)} km';

  @override
  String toString() => '$name - $distanceText';
}

