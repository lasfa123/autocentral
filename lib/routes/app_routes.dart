// Navigation routes
import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/vehicles/vehicle_list_page.dart';
import '../features/vehicles/vehicle_form_page.dart';
import '../features/documents/document_list_page.dart';
import '../features/documents/document_form_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const HomeDashboardPage(),
    '/vehicleList': (context) => VehicleListPage(),
    '/vehicleForm': (context) => const VehicleFormPage(),
  };

  // Route dynamique pour les documents
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/documentList':
        final vehicleId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DocumentListPage(vehicleId: vehicleId),
        );
      case '/documentForm':
        final vehicleId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => DocumentFormPage(vehicleId: vehicleId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeDashboardPage(),
        );
    }
  }
}
