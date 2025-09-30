// lib/features/documents/document_list_page.dart
import 'package:flutter/material.dart';
import '../../core/models/document.dart';
import '../../core/services/document_service.dart';
import 'document_form_page.dart';

class DocumentListPage extends StatefulWidget {
  final String vehicleId;

  const DocumentListPage({super.key, required this.vehicleId});

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  List<DocumentModel> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await DocumentService.getDocuments(widget.vehicleId);
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Documents',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentFormPage(vehicleId: widget.vehicleId),
                ),
              ).then((_) => _loadDocuments());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? _buildEmptyState()
          : _buildDocumentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun document',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos premiers documents\npour ce véhicule',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentFormPage(vehicleId: widget.vehicleId),
                ),
              ).then((_) => _loadDocuments());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un document'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    // Grouper les documents par type
    final Map<String, List<DocumentModel>> groupedDocs = {};
    for (final doc in _documents) {
      groupedDocs.putIfAbsent(doc.type, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Carte grise
        _buildDocumentTypeCard(
          'carte_grise',
          'Carte Grise',
          Icons.credit_card,
          groupedDocs['carte_grise'] ?? [],
        ),

        const SizedBox(height: 12),

        // Assurance
        _buildDocumentTypeCard(
          'assurance',
          'Assurance',
          Icons.security,
          groupedDocs['assurance'] ?? [],
          hasExpiry: true,
        ),

        const SizedBox(height: 12),

        // Visite technique
        _buildDocumentTypeCard(
          'visite',
          'Visite Technique',
          Icons.build_circle,
          groupedDocs['visite'] ?? [],
          hasExpiry: true,
          isUrgent: _isVisiteTechniqueUrgent(groupedDocs['visite'] ?? []),
        ),

        // Autres types de documents
        ...groupedDocs.keys
            .where((type) => !['carte_grise', 'assurance', 'visite'].contains(type))
            .map((type) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDocumentTypeCard(
            type,
            _getDocumentTypeLabel(type),
            Icons.description,
            groupedDocs[type]!,
          ),
        )),
      ],
    );
  }

  Widget _buildDocumentTypeCard(
      String type,
      String title,
      IconData icon,
      List<DocumentModel> documents, {
        bool hasExpiry = false,
        bool isUrgent = false,
      }) {
    final hasDocuments = documents.isNotEmpty;
    final latestDoc = hasDocuments ? documents.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUrgent
            ? Border.all(color: Colors.red[300]!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDocumentDetails(type, documents),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? Colors.red[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isUrgent ? Colors.red[600] : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasExpiry && latestDoc?.expiryDate != null)
                          _buildExpiryInfo(latestDoc!.expiryDate!),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),

              if (isUrgent && hasExpiry)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ce document doit être renouvelé !',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryInfo(DateTime expiryDate) {
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    final isExpiring = daysLeft <= 30;
    final isExpired = daysLeft < 0;

    String text;
    Color color;

    if (isExpired) {
      text = 'Expiré le ${expiryDate.toShortDateString()}';
      color = Colors.red;
    } else if (isExpiring) {
      text = 'Expire le ${expiryDate.toShortDateString()} - dans $daysLeft jour${daysLeft > 1 ? 's' : ''}';
      color = Colors.orange[700]!;
    } else {
      text = 'Expire le ${expiryDate.toShortDateString()}';
      color = Colors.grey[600]!;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: color,
        fontWeight: isExpiring || isExpired ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  bool _isVisiteTechniqueUrgent(List<DocumentModel> documents) {
    if (documents.isEmpty) return false;
    final latestDoc = documents.first;
    if (latestDoc.expiryDate == null) return false;

    final daysLeft = latestDoc.expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft <= 2; // Urgent si expire dans 2 jours ou moins
  }

  String _getDocumentTypeLabel(String type) {
    switch (type) {
      case 'carte_grise':
        return 'Carte Grise';
      case 'assurance':
        return 'Assurance';
      case 'visite':
        return 'Visite Technique';
      case 'permis':
        return 'Permis de Conduire';
      case 'facture':
        return 'Factures';
      default:
        return type.replaceAll('_', ' ').split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  void _showDocumentDetails(String type, List<DocumentModel> documents) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      _getDocumentTypeLabel(type),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentFormPage(
                              vehicleId: widget.vehicleId,
                              initialDocType: type,
                            ),
                          ),
                        ).then((_) => _loadDocuments());
                      },
                      icon: const Icon(Icons.add, color: Colors.blue),
                    ),
                  ],
                ),
              ),

              // Documents list
              Expanded(
                child: documents.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun document',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez votre premier document',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return _buildDocumentTile(doc);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(DocumentModel document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf,
              color: Colors.blue[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajouté le ${document.dateAdded.toShortDateString()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (document.expiryDate != null)
                  Text(
                    'Expire le ${document.expiryDate!.toShortDateString()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getExpiryColor(document.expiryDate!),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onSelected: (value) async {
              switch (value) {
                case 'download':
                  _downloadDocument(document);
                  break;
                case 'share':
                  _shareDocument(document);
                  break;
                case 'delete':
                  _deleteDocument(document);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Télécharger'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Partager'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return Colors.red;
    if (daysLeft <= 30) return Colors.orange[700]!;
    return Colors.grey[600]!;
  }

  void _downloadDocument(DocumentModel document) {
    // TODO: Implémenter le téléchargement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement bientôt disponible')),
    );
  }

  void _shareDocument(DocumentModel document) {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage bientôt disponible')),
    );
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${document.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implémenter la suppression
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression bientôt disponible')),
      );
    }
  }
}

// Extension pour formater les dates
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2,'0')}/${month.toString().padLeft(2,'0')}/$year";
  }
}