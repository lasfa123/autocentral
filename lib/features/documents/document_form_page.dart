// Document form page
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/services/document_service.dart';

class DocumentFormPage extends StatefulWidget {
  final String vehicleId;

  const DocumentFormPage({super.key, required this.vehicleId});

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  String? _docType;
  String? _fileName;
  Uint8List? _fileBytes;

  final List<String> types = ['assurance', 'visite', 'carte_grise'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un document")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Type de document'),
              items: types
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => _docType = value,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Utilisation de file_selector
                final typeGroup = XTypeGroup(
                  label: 'Documents',
                  extensions: ['pdf', 'jpg', 'png'],
                );
                final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
                if (file != null) {
                  _fileBytes = await file.readAsBytes();
                  _fileName = file.name;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fichier sélectionné: $_fileName')),
                  );
                }
              },
              child: const Text("Choisir un fichier"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_docType != null && _fileBytes != null && _fileName != null) {
                  // Upload via DocumentService
                  await DocumentService.uploadDocument(
                    vehicleId: widget.vehicleId,
                    docType: _docType!,
                    fileName: _fileName!,
                    fileData: _fileBytes!,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sélectionnez un type et un fichier')),
                  );
                }
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
