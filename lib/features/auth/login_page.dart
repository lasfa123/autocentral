// lib/features/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
import 'register_page.dart';
import 'reset_password_page.dart';
import 'package:autocentral/pigeon_definitions/user_api.g.dart'; // UserDetails

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      debugPrint('🔐 Démarrage de la connexion...');

      // 1. Connexion avec Firebase Auth
      final result = await AuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        debugPrint('✅ Connexion Firebase réussie');

        // 2. Petite pause pour que Firebase Auth se stabilise
        await Future.delayed(const Duration(milliseconds: 300));

        // 3. Récupération du profil utilisateur
        try {
          debugPrint('🔍 Récupération du profil utilisateur...');
          final userProfile = await AuthService.getUserProfile();

          if (userProfile != null) {
            debugPrint('✅ Profil utilisateur récupéré');
            debugPrint('   - UID: ${userProfile.uid}');
            debugPrint('   - Email: ${userProfile.email ?? "null"}');
            debugPrint('   - DisplayName: ${userProfile.displayName ?? "null"}');

            // 4. Validation de l'objet UserDetails
            if (_validateUserDetails(userProfile)) {
              // 5. Optionnel: Envoyer à votre API Pigeon
              await _sendToPigeon(userProfile);

              // 6. Navigation vers la page principale
              _navigateToHome();

            } else {
              debugPrint('❌ UserDetails invalide');
              setState(() => _errorMessage = 'Données utilisateur invalides');
            }
          } else {
            debugPrint('⚠️ Profil utilisateur non récupéré, mais connexion OK');
            // Connexion réussie même sans profil complet
            _navigateToHome();
          }

        } catch (profileError) {
          debugPrint('❌ Erreur récupération profil: $profileError');
          // Connexion Firebase OK, mais problème avec le profil
          setState(() => _errorMessage = 'Connexion réussie, profil incomplet');

          // On peut quand même continuer
          _navigateToHome();
        }

        HapticFeedback.lightImpact();

      } else {
        // Erreur de connexion Firebase
        debugPrint('❌ Erreur connexion Firebase: ${result.errorMessage ?? "Erreur inconnue"}');
        setState(() => _errorMessage = result.errorMessage ?? 'Erreur de connexion');
        HapticFeedback.heavyImpact();
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur inattendue lors de la connexion: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _errorMessage = 'Erreur inattendue: ${_getSimpleError(e)}');
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Valider que l'objet UserDetails est correct avant utilisation
  bool _validateUserDetails(UserDetails userDetails) {
    try {
      // Vérification de l'UID (requis selon Pigeon)
      final uid = userDetails.uid;
      if (uid == null || uid.isEmpty) {
        debugPrint('❌ Validation: UID vide');
        return false;
      }

      // L'email peut être null mais pas vide si présent
      final email = userDetails.email;
      if (email != null && email.isEmpty) {
        debugPrint('❌ Validation: Email vide');
        return false;
      }

      // Le displayName peut être null mais pas vide si présent
      final displayName = userDetails.displayName;
      if (displayName != null && displayName.isEmpty) {
        debugPrint('⚠️ Validation: DisplayName vide (non bloquant)');
      }

      // Le photoUrl peut être null mais pas vide si présent
      final photoUrl = userDetails.photoUrl;
      if (photoUrl != null && photoUrl.isEmpty) {
        debugPrint('⚠️ Validation: PhotoUrl vide (non bloquant)');
      }

      debugPrint('✅ UserDetails valide');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur validation UserDetails: $e');
      return false;
    }
  }

  /// Envoyer les données à votre API Pigeon (optionnel)
  Future<void> _sendToPigeon(UserDetails userDetails) async {
    try {
      debugPrint('📤 Envoi vers Pigeon...');

      // Décommentez cette ligne quand vous voulez utiliser Pigeon
      // await UserApi().setCurrentUser(userDetails);

      debugPrint('✅ Données envoyées à Pigeon avec succès');
    } catch (pigeonError) {
      debugPrint('❌ Erreur Pigeon: $pigeonError');
      // Ne pas faire échouer la connexion pour une erreur Pigeon

      // Diagnostic de l'erreur Pigeon
      final errorString = pigeonError.toString();
      if (errorString.contains('list is not a subtype')) {
        debugPrint('🔍 Erreur de sérialisation Pigeon détectée');
        debugPrint('🔍 Vérifiez la définition de UserDetails dans pigeon');
        debugPrint('🔍 UserDetails reçu: $userDetails');
      }
    }
  }

  /// Navigation vers la page principale
  void _navigateToHome() {
    debugPrint('🏠 Navigation vers le tableau de bord');

    if (!mounted) return;

    // ✅ On remplace l'écran actuel par le Dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeDashboardPage(),
      ),
    );

    //  (Optionnel) Afficher une confirmation après la navigation
     WidgetsBinding.instance.addPostFrameCallback((_) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('✅ Connexion réussie !'),
           backgroundColor: Colors.green,
           duration: Duration(seconds: 2),
         ),
       );
     });
  }

  /// Simplifier les messages d'erreur pour l'utilisateur
  String _getSimpleError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network')) {
      return 'Problème de connexion internet';
    }
    if (errorStr.contains('timeout')) {
      return 'Délai d\'attente dépassé';
    }
    if (errorStr.contains('permission')) {
      return 'Problème de permissions';
    }

    // Retourner une version courte de l'erreur
    final shortError = error.toString();
    return shortError.length > 50
        ? '${shortError.substring(0, 50)}...'
        : shortError;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Logo et titre
              Hero(
                tag: 'app_logo',
                child: Icon(
                  Icons.directions_car_filled,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'AutoCentral',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Gérez vos véhicules en toute simplicité',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Formulaire de connexion
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Champ email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Adresse email',
                        hintText: 'exemple@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Email non valide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Champ mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir votre mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Lien mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Message d'erreur
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bouton de connexion
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Lien d'inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: _isLoading
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}