// lib/features/documents/document_form_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/services/document_service.dart';

class DocumentFormPage extends StatefulWidget {
  final String vehicleId;
  final String? initialDocType;

  const DocumentFormPage({
    super.key,
    required this.vehicleId,
    this.initialDocType,
  });

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? _docType;
  String? _fileName;
  Uint8List? _fileBytes;
  DateTime? _expiryDate;
  bool _hasExpiry = false;
  bool _isLoading = false;

  final Map<String, String> _documentTypes = {
    'carte_grise': 'Carte Grise',
    'assurance': 'Assurance',
    'visite': 'Visite Technique',
    'permis': 'Permis de Conduire',
    'facture': 'Facture',
    'contrat': 'Contrat',
    'autre': 'Autre',
  };

  final Set<String> _typesWithExpiry = {
    'assurance',
    'visite',
    'permis',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialDocType != null) {
      _docType = widget.initialDocType;
      _hasExpiry = _typesWithExpiry.contains(widget.initialDocType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter un document',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Section Type de document
                  _buildSectionCard(
                    title: 'Type de document',
                    icon: Icons.category_outlined,
                    child: DropdownButtonFormField<String>(
                      value: _docType,
                      decoration: const InputDecoration(
                        hintText: 'Sélectionnez un type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _documentTypes.entries
                          .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(
                              _getDocumentIcon(entry.key),
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Text(entry.value),
                          ],
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _docType = value;
                          _hasExpiry = _typesWithExpiry.contains(value);
                          if (!_hasExpiry) {
                            _expiryDate = null;
                          }
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Veuillez sélectionner un type' : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section Fichier
                  _buildSectionCard(
                    title: 'Fichier',
                    icon: Icons.upload_file,
                    child: Column(
                      children: [
                        if (_fileName == null)
                          _buildFileSelector()
                        else
                          _buildSelectedFile(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section Date d'expiration (si applicable)
                  if (_hasExpiry)
                    _buildSectionCard(
                      title: 'Date d\'expiration',
                      icon: Icons.event_outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _expiryDate != null,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectExpiryDate();
                                    } else {
                                      _expiryDate = null;
                                    }
                                  });
                                },
                              ),
                              const Text('Le document peut-il expirer ?'),
                            ],
                          ),
                          if (_expiryDate != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Expire le',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: _selectExpiryDate,
                                    child: Text(
                                      _formatDate(_expiryDate!),
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getExpiryWarning(),
                                    style: TextStyle(
                                      color: _getExpiryWarningColor(),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bouton de sauvegarde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Sauvegarder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return InkWell(
      onTap: _selectFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Choisir un fichier',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG ou PNG (max 10MB)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(_fileBytes!.length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _fileName = null;
                _fileBytes = null;
              });
            },
            icon: Icon(Icons.close, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();

        // Vérifier la taille (max 10MB)
        if (bytes.length > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Le fichier est trop volumineux (max 10MB)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _fileBytes = bytes;
          _fileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du fichier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fileBytes == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fichier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DocumentService.uploadDocument(
        vehicleId: widget.vehicleId,
        docType: _docType!,
        fileName: _fileName!,
        fileData: _fileBytes!,
        expiryDate: _expiryDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'carte_grise':
        return Icons.credit_card;
      case 'assurance':
        return Icons.security;
      case 'visite':
        return Icons.build_circle;
      case 'permis':
        return Icons.badge;
      case 'facture':
        return Icons.receipt;
      case 'contrat':
        return Icons.description;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _getExpiryWarning() {
    if (_expiryDate == null) return '';

    final daysLeft = _expiryDate!.difference(DateTime.now()).inDays;

    if (daysLeft < 0) {
      return 'Ce document a expiré';
    } else if (daysLeft <= 30) {
      return 'Expire dans $daysLeft jour${daysLeft > 1 ? 's' : ''}';
    } else if (daysLeft <= 90) {
      return 'Expire dans ${(daysLeft / 30).ceil()} mois';
    } else {
      return 'Valide pour ${(daysLeft / 365).toStringAsFixed(1)} an${daysLeft > 365 ? 's' : ''}';
    }
  }

  Color _getExpiryWarningColor() {
    if (_expiryDate == null) return Colors.grey;

    final daysLeft = _expiryDate!.difference(DateTime.now()).inDays;

    if (daysLeft < 0) {
      return Colors.red[700]!;
    } else if (daysLeft <= 30) {
      return Colors.orange[700]!;
    } else {
      return Colors.blue[700]!;
    }
  }
}