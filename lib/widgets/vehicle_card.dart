// lib/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import '../core/models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleCard({
    super.key,
    required this.car,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = car.hasUpcomingExpirations;
    final hasExpired = car.hasExpiredDocuments;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: hasExpired
            ? BorderSide(color: Colors.red[300]!, width: 1)
            : hasAlert
            ? BorderSide(color: Colors.orange[300]!, width: 1)
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
              // En-tête avec photo/icône et actions
              Row(
                children: [
                  // Photo ou icône du véhicule
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: car.photoUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        car.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildCarIcon(),
                      ),
                    )
                        : _buildCarIcon(),
                  ),

                  const SizedBox(width: 16),

                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${car.brand} ${car.model}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.licensePlate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${car.year}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.speed, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatMileage(car.mileage)} km',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Badge d'alerte et menu
                  Column(
                    children: [
                      if (hasExpired)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      else if (hasAlert)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),

                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit?.call();
                              break;
                            case 'delete':
                              onDelete?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Modifier'),
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
                ],
              ),

              const SizedBox(height: 16),

              // Informations sur les échéances
              Row(
                children: [
                  Expanded(
                    child: _buildExpiryInfo(
                      context,
                      'Assurance',
                      car.insuranceExpiry,
                      Icons.security,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildExpiryInfo(
                      context,
                      'Contrôle',
                      car.inspectionExpiry,
                      Icons.build,
                    ),
                  ),
                ],
              ),

              // Message d'alerte si nécessaire
              if (hasExpired || hasAlert)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasExpired ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasExpired ? Icons.error : Icons.warning,
                        color: hasExpired ? Colors.red[700] : Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasExpired
                              ? 'Des documents ont expiré !'
                              : 'Des documents expirent bientôt',
                          style: TextStyle(
                            color: hasExpired ? Colors.red[700] : Colors.orange[700],
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

  Widget _buildCarIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.directions_car,
        color: Colors.blue[600],
        size: 28,
      ),
    );
  }

  Widget _buildExpiryInfo(
      BuildContext context,
      String label,
      DateTime expiry,
      IconData icon,
      ) {
    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    final isExpired = daysLeft < 0;
    final isExpiringSoon = daysLeft <= 30 && daysLeft >= 0;

    Color color;
    if (isExpired) {
      color = Colors.red;
    } else if (isExpiringSoon) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            expiry.toShortDateString(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            isExpired
                ? 'Expiré'
                : daysLeft <= 30
                ? 'Dans $daysLeft j'
                : 'Valide',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
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