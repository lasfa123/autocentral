// Document card widget
import 'package:flutter/material.dart';
import '../core/models/document.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onDownload;

  const DocumentCard({super.key, required this.document, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf),
        title: Text(document.name),
        subtitle: document.expiryDate != null
            ? Text('Expire le: ${document.expiryDate!.toShortDateString()}')
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: onDownload,
        ),
      ),
    );
  }
}

// Extension pour formater les dates
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2,'0')}/${month.toString().padLeft(2,'0')}/$year";
  }
}
