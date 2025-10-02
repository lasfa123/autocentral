// lib/features/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:autocentral/core/services/auth_service.dart';
import 'package:autocentral/features/dashboard/dashboard_page.dart';
import 'package:autocentral/features/auth/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // En cas d'erreur de connexion
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de connexion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vérifiez votre connexion internet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        // Écran de chargement initial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }

        // Utilisateur connecté - aller au dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeDashboardPage();
        }

        // Utilisateur non connecté - aller à la page de login
        return const LoginPage();
      },
    );
  }
}

// Écran de chargement pour l'authentification
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Hero(
                    tag: 'app_logo',
                    child: Icon(
                      Icons.directions_car_filled,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              },
              onEnd: () {
                // Recommencer l'animation
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              'AutoCentral',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Indicateur de chargement
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Initialisation...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}