import 'package:flutter/material.dart';
import '../../core/models/vehicle.dart';
import '../../widgets/vehicle_card.dart';

class VehicleListPage extends StatelessWidget {
  VehicleListPage({super.key});

  // Exemple temporaire
  final List<CarModel> vehicles = [
    CarModel(
      id: '1',
      brand: 'Toyota',
      model: 'Corolla',
      licensePlate: 'AA-123-BB',
      year: 2019,
      mileage: 45000,
      purchaseDate: DateTime(2022, 1, 10),
      insuranceExpiry: DateTime(2025, 12, 10),
      inspectionExpiry: DateTime(2025, 8, 15),
      registrationNumber: 'RG-12345',
      photoUrl: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Véhicules'),
      ),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final car = vehicles[index];
          return VehicleCard(car: car);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/vehicleForm');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
