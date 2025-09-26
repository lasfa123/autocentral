import 'package:flutter/material.dart';
import '../../core/models/vehicle.dart';
import '../../core/services/vehicle_service.dart';
import '../../widgets/vehicle_card.dart';
import 'vehicle_form_page.dart';
import 'vehicle_detail_page.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CarModel> _allVehicles = [];
  List<CarModel> _filteredVehicles = [];
  VehicleStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await VehicleService.getVehicleStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = _allVehicles;
      } else {
        final searchLower = query.toLowerCase();
        _filteredVehicles = _allVehicles.where((vehicle) {
          return vehicle.brand.toLowerCase().contains(searchLower) ||
              vehicle.model.toLowerCase().contains(searchLower) ||
              vehicle.licensePlate.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes Véhicules',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VehicleFormPage()),
              ).then((_) => _loadStats());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche + stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un véhicule...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: _onSearchChanged,
                ),

                if (_stats != null && _stats!.totalVehicles > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total',
                            '${_stats!.totalVehicles}',
                            Icons.directions_car,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Échéances',
                            '${_stats!.upcomingExpirations}',
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Expirés',
                            '${_stats!.expiredDocuments}',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Liste des véhicules
          Expanded(
            child: StreamBuilder<List<CarModel>>(
              stream: VehicleService.getUserVehicles(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vehicles = snapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_allVehicles != vehicles) {
                    setState(() {
                      _allVehicles = vehicles;
                      if (_searchController.text.isEmpty) {
                        _filteredVehicles = vehicles;
                      } else {
                        _onSearchChanged(_searchController.text);
                      }
                    });
                  }
                });

                final displayVehicles = _searchController.text.isNotEmpty
                    ? _filteredVehicles
                    : vehicles;

                if (displayVehicles.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayVehicles.length,
                    itemBuilder: (context, index) {
                      final car = displayVehicles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VehicleCard(
                          car: car,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleDetailPage(vehicleId: car.id),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleFormPage(vehicle: car),
                              ),
                            ).then((_) => _loadStats());
                          },
                          onDelete: () => _deleteVehicle(context, car),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[600],
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehicleFormPage()),
          ).then((_) => _loadStats());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 60, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Erreur: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
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
              hasSearch ? Icons.search_off : Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasSearch ? 'Aucun résultat' : 'Aucun véhicule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Essayez avec d\'autres termes de recherche'
                : 'Ajoutez votre premier véhicule\npour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          if (!hasSearch)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VehicleFormPage()),
                  ).then((_) => _loadStats());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un véhicule'),
              ),
            )
          else
            TextButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Text('Effacer la recherche'),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(BuildContext context, CarModel car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le véhicule'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer ${car.brand} ${car.model} (${car.licensePlate}) ?'),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final result = await VehicleService.deleteVehicle(car.id);

        if (context.mounted) {
          Navigator.pop(context);
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Véhicule supprimé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            _loadStats();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                Text(result.errorMessage ?? 'Erreur lors de la suppression'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
