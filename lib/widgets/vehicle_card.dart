// Vehicle card widget
import 'package:flutter/material.dart';
import '../core/models/vehicle.dart';
import '../features/vehicles/vehicle_detail_page.dart';

class VehicleCard extends StatelessWidget {
  final CarModel car;

  const VehicleCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text('${car.brand} ${car.model}'),
        subtitle: Text('Immatriculation: ${car.licensePlate}\n'
            'Assurance: ${car.insuranceExpiry.toLocal().toShortDateString()}\n'
            'Visite: ${car.inspectionExpiry.toLocal().toShortDateString()}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // TODO: Naviguer vers le détail du véhicule
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailPage(vehicle: car.id),
            ),
          );
        },
      ),
    );
  }
}

// Extension pour formater les dates
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2,'0')}/${month.toString().padLeft(2,'0')}/${year}";
  }
}
