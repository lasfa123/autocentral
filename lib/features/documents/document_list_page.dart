// Document list page
import 'package:flutter/material.dart';
import '../../core/models/document.dart';
import '../../widgets/document_card.dart';

class DocumentListPage extends StatelessWidget {
  final String vehicleId;

  DocumentListPage({super.key, required this.vehicleId});

  // Exemple temporaire
  final List<DocumentModel> documents = [
    DocumentModel(
      id: '1',
      type: 'assurance',
      name: 'Assurance_2025.pdf',
      fileUrl: 'https://www.example.com/file.pdf',
      dateAdded: DateTime.now(),
      expiryDate: DateTime(2025, 12, 10),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Documents")),
      body: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return DocumentCard(
            document: doc,
            onDownload: () {
              // TODO: Télécharger le document via Firebase Storage
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/documentForm', arguments: vehicleId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
