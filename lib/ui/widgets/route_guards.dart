import 'package:flutter/material.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../screens/home_admin_screen.dart';
import '../screens/home_page.dart';
import '../screens/login_screen.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return _SessionLoader(
      builder: (result) {
        if (!result.isAuthenticated) {
          return const LoginScreen();
        }
        return SessionService.isAdmin
            ? const HomeAdminScreen()
            : const HomePage();
      },
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _SessionLoader(
      builder: (result) => result.isAuthenticated ? child : const LoginScreen(),
    );
  }
}

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _SessionLoader(
      builder: (result) {
        if (!result.isAuthenticated) {
          return const LoginScreen();
        }
        if (!SessionService.isAdmin) {
          return const AccessDeniedScreen();
        }
        return child;
      },
    );
  }
}

class _SessionLoader extends StatefulWidget {
  final Widget Function(SessionRestoreResult result) builder;

  const _SessionLoader({required this.builder});

  @override
  State<_SessionLoader> createState() => _SessionLoaderState();
}

class _SessionLoaderState extends State<_SessionLoader> {
  late Future<SessionRestoreResult> _future;

  @override
  void initState() {
    super.initState();
    _future = SessionService.restore();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionRestoreResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _SessionError(
            message: 'No se pudo comprobar la sesión',
            onRetry: _retry,
          );
        }

        final result = snapshot.data ?? const SessionRestoreResult();
        if (result.error != null && result.statusCode != 401) {
          return _SessionError(message: result.error!, onRetry: _retry);
        }
        return widget.builder(result);
      },
    );
  }

  void _retry() {
    setState(() {
      _future = SessionService.restore(force: true);
    });
  }
}

class _SessionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SessionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso denegado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'No tienes permisos para realizar esta acción.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
