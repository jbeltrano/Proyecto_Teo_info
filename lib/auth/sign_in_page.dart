import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proyecto_teo_info/auth/google_auth_service.dart';
import 'package:proyecto_teo_info/features/tasks/presentation/pages/tasks_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.googleAuthService});

  final GoogleAuthService googleAuthService;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final GoogleAuthService _authService;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.googleAuthService;
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await _authService.signIn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  void dispose() {
    // No es necesario limpiar _authService porque lo administra main.dart.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldColor = Color(0xFF262b31);

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Divider(height: 80, color: Colors.transparent),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset(
                    'assets/app_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const FlutterLogo(size: 160),
                  ),
                ),
              ),
              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/Gmail.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.login, color: Colors.redAccent),
                    ),
                    label: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continuar con Google'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
