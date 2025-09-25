// Vehicle form page
import 'package:flutter/material.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un véhicule")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marque'),
                validator: (value) => value!.isEmpty ? 'Entrez une marque' : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Modèle'),
                validator: (value) => value!.isEmpty ? 'Entrez un modèle' : null,
              ),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(labelText: 'Immatriculation'),
                validator: (value) => value!.isEmpty ? 'Entrez une immatriculation' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Sauvegarder le véhicule dans Firestore
                    Navigator.pop(context);
                  }
                },
                child: const Text("Enregistrer"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

