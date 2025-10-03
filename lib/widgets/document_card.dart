// lib/widgets/document_card.dart
import 'package:autocentral/features/documents/document_list_page.dart';
import 'package:flutter/material.dart';
import '../core/models/document.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onDownload;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    this.onDownload,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = _isExpired();
    final isExpiringSoon = _isExpiringSoon();
    final daysUntilExpiry = _getDaysUntilExpiry();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isExpired
            ? BorderSide(color: Colors.red[300]!, width: 1.5)
            : isExpiringSoon
            ? BorderSide(color: Colors.orange[300]!, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône du document avec fond coloré
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getDocumentIcon(),
                      color: _getIconColor(),
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Informations du document
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom du document
                        Text(
                          document.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Date d'expiration
                        if (document.expiryDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 14,
                                color: _getExpiryColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expire le ${document.expiryDate!.toShortDateString()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getExpiryColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pas de date d\'expiration',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Badge de statut
                  if (isExpired || isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpired ? Icons.error : Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),

              // Barre d'information d'expiration
              if (document.expiryDate != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getExpiryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getExpiryIcon(),
                        size: 16,
                        color: _getExpiryColor(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getExpiryMessage(daysUntilExpiry),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getExpiryColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Boutons d'action
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton de téléchargement
                  if (onDownload != null)
                    TextButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Télécharger'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),

                  // Bouton de suppression
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vérifie si le document est expiré
  bool _isExpired() {
    if (document.expiryDate == null) return false;
    return document.expiryDate!.isBefore(DateTime.now());
  }

  // Vérifie si le document expire bientôt (dans les 30 jours)
  bool _isExpiringSoon() {
    if (document.expiryDate == null) return false;
    final daysLeft = _getDaysUntilExpiry();
    return daysLeft >= 0 && daysLeft <= 30;
  }

  // Calcule les jours restants avant expiration
  int _getDaysUntilExpiry() {
    if (document.expiryDate == null) return 999;
    return document.expiryDate!.difference(DateTime.now()).inDays;
  }

  // Retourne la couleur de fond de l'icône
  Color _getIconBackgroundColor() {
    if (_isExpired()) return Colors.red[50]!;
    if (_isExpiringSoon()) return Colors.orange[50]!;
    return Colors.blue[50]!;
  }

  // Retourne la couleur de l'icône
  Color _getIconColor() {
    if (_isExpired()) return Colors.red[600]!;
    if (_isExpiringSoon()) return Colors.orange[600]!;
    return Colors.blue[600]!;
  }

  // Retourne l'icône appropriée selon le type de document
  IconData _getDocumentIcon() {
    final name = document.name.toLowerCase();
    if (name.contains('assurance')) return Icons.security;
    if (name.contains('carte grise') || name.contains('immatriculation')) {
      return Icons.description;
    }
    if (name.contains('contrôle') || name.contains('visite')) {
      return Icons.build_circle;
    }
    if (name.contains('permis')) return Icons.badge;
    return Icons.picture_as_pdf;
  }

  // Retourne la couleur selon le statut d'expiration
  Color _getExpiryColor() {
    if (_isExpired()) return Colors.red[700]!;
    if (_isExpiringSoon()) return Colors.orange[700]!;
    return Colors.green[700]!;
  }

  // Retourne l'icône selon le statut d'expiration
  IconData _getExpiryIcon() {
    if (_isExpired()) return Icons.error;
    if (_isExpiringSoon()) return Icons.warning;
    return Icons.check_circle;
  }

  // Retourne le message selon le statut d'expiration
  String _getExpiryMessage(int daysLeft) {
    if (_isExpired()) {
      final daysExpired = daysLeft.abs();
      return 'Expiré depuis $daysExpired jour${daysExpired > 1 ? 's' : ''}';
    }
    if (_isExpiringSoon()) {
      return 'Expire dans $daysLeft jour${daysLeft > 1 ? 's' : ''}';
    }
    return 'Document valide ($daysLeft jours restants)';
  }
}

// Version compacte du document card
class CompactDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onTap;

  const CompactDocumentCard({
    super.key,
    required this.document,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = document.expiryDate != null &&
        document.expiryDate!.isBefore(DateTime.now());
    final isExpiringSoon = document.expiryDate != null &&
        document.expiryDate!.difference(DateTime.now()).inDays <= 30 &&
        !isExpired;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isExpired
              ? Colors.red[50]
              : isExpiringSoon
              ? Colors.orange[50]
              : Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.picture_as_pdf,
          color: isExpired
              ? Colors.red[600]
              : isExpiringSoon
              ? Colors.orange[600]
              : Colors.blue[600],
        ),
      ),
      title: Text(
        document.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: document.expiryDate != null
          ? Text(
        'Expire le ${document.expiryDate!.toShortDateString()}',
        style: TextStyle(
          color: isExpired
              ? Colors.red[700]
              : isExpiringSoon
              ? Colors.orange[700]
              : Colors.grey[600],
        ),
      )
          : null,
      trailing: isExpired || isExpiringSoon
          ? Icon(
        isExpired ? Icons.error : Icons.warning,
        color: isExpired ? Colors.red : Colors.orange,
      )
          : null,
    );
  }
}