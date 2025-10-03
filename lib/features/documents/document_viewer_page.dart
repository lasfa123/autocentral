import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/models/document.dart';

class DocumentViewerPage extends StatelessWidget {
  final DocumentModel document;

  const DocumentViewerPage({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    if (document.base64Data == null || document.base64Data!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(document.name),
          backgroundColor: Colors.blue[600],
        ),
        body: const Center(
          child: Text('Le document est vide ou corrompu'),
        ),
      );
    }

    final bytes = base64Decode(_cleanBase64(document.base64Data!));
    final isPdf = document.name.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
        backgroundColor: Colors.blue[600],
      ),
      body: isPdf
          ? PdfView(
        controller: PdfController(
          document: PdfDocument.openData(bytes),
        ),
      )
          : Center(
        child: InteractiveViewer(
          child: Image.memory(bytes),
        ),
      ),
    );
  }

  String _cleanBase64(String base64String) {
    if (base64String.startsWith('data:')) {
      return base64String.split(',')[1];
    }
    return base64String;
  }
}
