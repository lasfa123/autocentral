// Vehicle detail page
import 'package:flutter/material.dart';
import 'package:autocentral/features/documents/document_form_page.dart';

class VehicleDetailPage extends StatelessWidget {
  final String vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(vehicle)),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentFormPage(vehicleId: vehicle),
              ),
            );
          },
          child: const Text('Ajouter un document'),
        ),
      ),
    );
  }
}
