// lib/features/dashboard/home_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/vehicle_service.dart';
import '../../core/models/vehicle.dart';
import '../settings/profile_page.dart';
import '../vehicles/vehicle_list_page.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<CarModel> _upcomingExpirations = [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingExpirations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcomingExpirations() async {
    try {
      final vehicles = await VehicleService.getVehiclesWithUpcomingExpirations();
      setState(() {
        _upcomingExpirations = vehicles;
      });
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomePage(firstName),
          const VehicleListPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomePage(String firstName) {
    return CustomScrollView(
      slivers: [
        // App Bar avec profil
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          floating: true,
          snap: true,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _getInitials(AuthService.currentUser),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue sur AutoCentral 👋',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    firstName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications bientôt disponibles'),
                  ),
                );
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.grey),
                  if (_upcomingExpirations.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // Contenu principal
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Message de bienvenue
              Text(
                'La sécurité et le suivi de votre véhicule réunis en un seul endroit.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Section "Besoin de votre attention"
              _buildAttentionSection(),

              const SizedBox(height: 24),

              // Section Notifications/Activités récentes
              _buildNotificationsSection(),

              const SizedBox(height: 100), // Espace pour le bottom nav
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionSection() {
    // Items d'attention (checklist style Traxello)
    final List<AttentionItem> items = [
      AttentionItem('Créer compte', true),
      AttentionItem('Ajouter véhicule', false), // TODO: Vérifier si l'utilisateur a des véhicules
      AttentionItem('Configurer alertes intelligentes pour véhicule', false),
      AttentionItem('Activer notifications', false),
      AttentionItem('Renouveler abonnement', false),
      AttentionItem('Renouveler documents', _upcomingExpirations.isNotEmpty),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.checklist,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Besoin de votre attention',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => _buildAttentionItem(item)),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(AttentionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: item.isCompleted ? Colors.green : Colors.white,
              border: Border.all(
                color: item.isCompleted ? Colors.green : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: item.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                color: item.isCompleted ? Colors.grey[600] : Colors.black,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications,
                  color: Colors.orange[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_upcomingExpirations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_upcomingExpirations.length}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // TODO: Voir toutes les notifications
                },
                child: Text(
                  'Voir plus →',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notifications simulées
          _buildNotificationItem(
            icon: Icons.login,
            title: 'New login detected on your account',
            time: '5 minutes ago',
            isUnread: true,
          ),

          const SizedBox(height: 16),

          _buildNotificationItem(
            icon: Icons.directions_car,
            title: 'Vehicle "Clio" entered the safe zone',
            time: '1 hour ago',
            isUnread: false,
          ),

          if (_upcomingExpirations.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.warning,
              title: 'Document expiring soon',
              time: 'Today',
              isUnread: true,
              isUrgent: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String time,
    bool isUnread = false,
    bool isUrgent = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isUrgent
                ? Colors.red[50]
                : isUnread
                ? Colors.blue[50]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isUrgent
                ? Colors.red[600]
                : isUnread
                ? Colors.blue[600]
                : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$time • ${isUnread ? 'Unread' : 'Read'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (isUnread)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[400],
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'Véhicules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  String _getInitials(User? user) {
    if (user?.displayName != null) {
      final names = user!.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    } else if (user?.email != null) {
      return user!.email![0].toUpperCase();
    }
    return '?';
  }
}

// Classe pour les items d'attention
class AttentionItem {
  final String title;
  final bool isCompleted;

  AttentionItem(this.title, this.isCompleted);
}