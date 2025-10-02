// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/sync_service.dart';
import 'package:autocentral/core/services/firebase_background_fix.dart';
import 'core/utils/notifications_helper.dart';
import 'core/services/auth_service.dart';
import 'package:autocentral/features/auth/login_page.dart';
import 'package:autocentral/features/auth/auth_wrapper.dart';
import 'package:autocentral/firebase_options.dart';
import 'package:autocentral/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔹 INITIALISATION FIREBASE
    debugPrint('🚀 Démarrage de l\'application...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialisé');

    // 🔹 INITIALISATION DES SERVICES APRÈS FIREBASE
    try {
      await SyncService.initialize();
      debugPrint('✅ SyncService initialisé');
    } catch (e) {
      debugPrint('⚠️ Erreur SyncService (non bloquant): $e');
    }

    try {
      await NotificationsHelper.initialize();
      debugPrint('✅ NotificationsHelper initialisé');
    } catch (e) {
      debugPrint('⚠️ Erreur NotificationsHelper (non bloquant): $e');
    }

    try {
      await FirebaseBackgroundService.startListening();
      debugPrint('✅ FirebaseBackgroundService initialisé');
    } catch (e) {
      debugPrint('⚠️ Erreur FirebaseBackgroundService (non bloquant): $e');
    }

    debugPrint('✅ Tous les services initialisés');

  } catch (e, stack) {
    debugPrint('❌ Erreur critique lors de l\'initialisation: $e');
    debugPrint('Stack trace: $stack');

    // On continue quand même avec Firebase de base
    debugPrint('🔄 Continuation avec Firebase de base uniquement');
  }

  // 🔹 Gestionnaire d'erreurs global
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ Erreur Flutter globale: ${details.exception}');
    debugPrint('Contexte: ${details.context}');

    // En mode debug, afficher l'erreur complète
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // 🔹 Gestionnaire d'erreurs pour les zones isolées
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ Erreur platform: $error');
    return true;
  };

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🟢 App initialisée');

    // Vérifier l'état d'authentification au démarrage
    _checkAuthState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupServices();
    super.dispose();
    debugPrint('🔴 App disposée');
  }

  /// Vérifier l'état d'authentification au démarrage
  void _checkAuthState() {
    try {
      final isLoggedIn = AuthService.isLoggedIn;
      debugPrint('🔐 État d\'authentification au démarrage: $isLoggedIn');

      if (isLoggedIn) {
        // Optionnel: revalider le token ou récupérer le profil
        _validateCurrentUser();
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification auth state: $e');
    }
  }

  /// Valider l'utilisateur actuel au démarrage
  Future<void> _validateCurrentUser() async {
    try {
      final userProfile = await AuthService.getUserProfile();
      if (userProfile != null) {
        debugPrint('✅ Utilisateur validé au démarrage: ${userProfile.displayName}');
      } else {
        debugPrint('⚠️ Utilisateur connecté mais profil invalide');
      }
    } catch (e) {
      debugPrint('❌ Erreur validation utilisateur: $e');
    }
  }

  /// Nettoyage des services
  Future<void> _cleanupServices() async {
    try {
      await FirebaseBackgroundService.stopListening();
      await SyncService.dispose();
      debugPrint('🧹 Services nettoyés');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage services: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 État app changé: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        _handleAppPause();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        debugPrint('💤 App inactive/hidden');
        break;
    }
  }

  Future<void> _handleAppResume() async {
    try {
      debugPrint('🔄 App reprise - vérification des services...');

      // Redémarrer les listeners Firebase si nécessaire
      await FirebaseBackgroundService.onAppResumed();

      // Synchronisation des données
      final syncResult = await SyncService.forceSync();
      if (syncResult.isSuccess) {
        debugPrint('✅ Sync réussie au retour');
      } else {
        debugPrint('❌ Erreur sync au retour: ${syncResult.errorMessage}');
      }

      // Revalider l'utilisateur connecté
      if (AuthService.isLoggedIn) {
        await _validateCurrentUser();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Erreur handleAppResume: $e');
    }
  }

  Future<void> _handleAppPause() async {
    try {
      debugPrint('⏸️ App en pause - sauvegarde...');
      await FirebaseBackgroundService.onAppPaused();
      debugPrint('💾 État sauvegardé avant background');
    } catch (e) {
      debugPrint('❌ Erreur handleAppPause: $e');
    }
  }

  Future<void> _handleAppDetached() async {
    try {
      debugPrint('🔌 App détachée - nettoyage final...');
      await _cleanupServices();
      debugPrint('🧹 Nettoyage final effectué');
    } catch (e) {
      debugPrint('❌ Erreur handleAppDetached: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoCentral',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,

      // Thème de l'application
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Configuration des couleurs pour Material 3
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          surface: Colors.white,
        ),

        // Style des boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Style des champs de texte
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),

      // Page d'accueil forcée vers LoginPage pour éviter l'écran blanc
      home: const AuthWrapper(),

      // Routes nommées
      routes: AppRoutes.routes,

      // Générateur de routes dynamiques
      onGenerateRoute: AppRoutes.generateRoute,

      // Gestionnaire de routes inconnues
      onUnknownRoute: (settings) {
        debugPrint('❌ Route inconnue: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page introuvable')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Page "${settings.name}" introuvable'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🌟 Page Debug Firebase améliorée
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Map<String, dynamic> _firebaseStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFirebaseStatus();
  }

  Future<void> _loadFirebaseStatus() async {
    setState(() => _isLoading = true);

    try {
      _firebaseStatus = FirebaseBackgroundService.getStatus();

      // Ajouter l'état d'authentification
      _firebaseStatus['authState'] = AuthService.isLoggedIn;
      _firebaseStatus['currentUserUid'] = AuthService.currentUser?.uid;
      _firebaseStatus['currentUserEmail'] = AuthService.currentUser?.email;

    } catch (e) {
      debugPrint('❌ Erreur chargement status: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firebase'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFirebaseStatus,
          ),
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () => _testFirebaseConnection(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo et titre
            const Icon(Icons.directions_car, size: 100, color: Colors.blue),
            const SizedBox(height: 20),

            Text(
              'AutoCentral Debug',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Statut Firebase
            _buildStatusCard(
              'Statut Firebase',
              Icons.cloud,
              Colors.green,
              _firebaseStatus.isNotEmpty ? 'Connecté' : 'Déconnecté',
            ),

            const SizedBox(height: 16),

            // Détails du statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du statut',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._firebaseStatus.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              '${entry.key}:',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value?.toString() ?? 'null',
                              style: TextStyle(
                                color: entry.value == true
                                    ? Colors.green
                                    : entry.value == false
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: () => _testFirebaseConnection(context),
              icon: const Icon(Icons.network_check),
              label: const Text('Tester la connexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => _testUserProfile(context),
              icon: const Icon(Icons.person),
              label: const Text('Tester le profil utilisateur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Aller à Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, Color color, String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    status,
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFirebaseConnection(BuildContext context) async {
    try {
      await FirebaseBackgroundService.checkAndRepairConnection();
      _showSnackBar(context, '✅ Connexion Firebase OK', Colors.green);
      await _loadFirebaseStatus();
    } catch (e) {
      _showSnackBar(context, '❌ Erreur Firebase: $e', Colors.red);
    }
  }

  Future<void> _testUserProfile(BuildContext context) async {
    try {
      if (!AuthService.isLoggedIn) {
        _showSnackBar(context, '⚠️ Aucun utilisateur connecté', Colors.orange);
        return;
      }

      final userProfile = await AuthService.getUserProfile();
      if (userProfile != null) {
        _showSnackBar(
          context,
          '✅ Profil récupéré: ${userProfile.displayName}',
          Colors.green,
        );
      } else {
        _showSnackBar(context, '❌ Profil non récupéré', Colors.red);
      }
    } catch (e) {
      _showSnackBar(context, '❌ Erreur profil: $e', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}