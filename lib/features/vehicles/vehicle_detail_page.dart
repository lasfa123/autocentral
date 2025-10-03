// lib/features/vehicles/vehicle_detail_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/models/vehicle.dart';
import '../../core/services/vehicle_service.dart';
import '../documents/document_list_page.dart';
import '../documents/document_form_page.dart';

class VehicleDetailPage extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  CarModel? _vehicle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final vehicle = await VehicleService.getVehicleById(widget.vehicleId);
      setState(() {
        _vehicle = vehicle;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Véhicule non trouvé'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_vehicle!.brand} ${_vehicle!.model}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadVehicle,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              // TODO: Navigation vers l'édition
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête véhicule
            _buildVehicleHeader(),

            const SizedBox(height: 16),

            // Statut du véhicule
            _buildStatusCard(),

            const SizedBox(height: 8),

            // Informations de contact (simulation)
            _buildContactCard(),

            const SizedBox(height: 8),

            // Menu principal
            _buildMainMenu(),

            const SizedBox(height: 24),

            // Actions rapides
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Photo ou icône + nom du véhicule
          Row(
            children: [
              // ✅ Photo en Base64 si disponible
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: (_vehicle!.photoUrl != null && _vehicle!.photoUrl!.isNotEmpty)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_vehicle!.photoUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                )
                    : const Icon(
                  Icons.directions_car,
                  color: Colors.blue,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // Infos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_vehicle!.brand} ${_vehicle!.model}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _vehicle!.licensePlate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ACTIF',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Infos rapides
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                '2min',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_vehicle!.year}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_formatMileage(_vehicle!.mileage)} km',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'État des documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Assurance
          _buildDocumentStatus(
            'Assurance',
            _vehicle!.insuranceExpiry,
            Icons.security,
          ),

          const SizedBox(height: 8),

          // Contrôle technique
          _buildDocumentStatus(
            'Contrôle technique',
            _vehicle!.inspectionExpiry,
            Icons.build_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(String title, DateTime expiry, IconData icon) {
    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    final isExpiring = daysLeft <= 30;
    final isExpired = daysLeft < 0;

    Color statusColor;
    String statusText;

    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expiré';
    } else if (isExpiring) {
      statusColor = Colors.orange;
      statusText = 'Dans $daysLeft jour${daysLeft > 1 ? 's' : ''}';
    } else {
      statusColor = Colors.green;
      statusText = 'Valide';
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: statusColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Expire le ${DateHelpers(expiry).toShortDateString()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Abonné(e)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text(
                'autocentral.com',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'Formule d\'abonnement',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Spacer(),
              Text(
                'Premium',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.route,
            title: 'Trajets',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Events',
            subtitle: 'Consulter alertes',
            badge: '45',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Documents',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentListPage(vehicleId: widget.vehicleId),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Paramètres',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      color: Colors.grey[200],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentFormPage(vehicleId: widget.vehicleId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter document'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage bientôt disponible')),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  String _formatMileage(int mileage) {
    if (mileage >= 1000000) {
      return '${(mileage / 1000000).toStringAsFixed(1)}M';
    } else if (mileage >= 1000) {
      return '${(mileage / 1000).toStringAsFixed(0)}K';
    }
    return mileage.toString();
  }
}

// Extension pour formater les dates
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2,'0')}/${month.toString().padLeft(2,'0')}/$year";
  }
}