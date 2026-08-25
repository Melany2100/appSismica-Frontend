import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/connection_test_android.dart';
import '../widgets/fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _loginBackend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      print('Iniciando login con AuthService...');

      // USAR SOLO AuthService - ya maneja todo el flujo interno
      final authResponse = await AuthService.login(
        email: email.text.trim(),
        password: password.text.trim(),
        maxRetries: 2,
      );

      print('Respuesta de AuthService: ${authResponse.toDebugMap()}');

      if (authResponse.success) {
        // LOGIN EXITOSO - AuthResponse ya contiene todo lo necesario
        final token = authResponse.token!;
        final userId = authResponse.userId!.toString();
        final userName = authResponse.userNameValue; // Ya incluye fallback
        final userRole = authResponse.userRoleValue;

        print('Datos del usuario obtenidos:');
        print('  - userName: $userName');
        print('  - userId: $userId');
        print('  - token: ${token.substring(0, 10)}...');

        // OBTENER ROL DEL USUARIO - Solo si es necesario
        //String userRole = 'user'; // Valor por defecto

        // El AuthService ya configuró el token, podemos hacer llamadas autenticadas
        /* if (authResponse.nombre != null) {
          // Si AuthService obtuvo el nombre, también intentar obtener el rol
          try {
            final roleResponse = await _getUserRole(token, userId);
            if (roleResponse != null) {
              userRole = roleResponse;
            }
          } catch (e) {
            print('Error obteniendo rol: $e');
            // Continuar con rol por defecto
          }
        }*/

        print('Rol final del usuario: $userRole');

        await SessionService.persist(token: token, user: authResponse.user!);

        // Verificar que se guardaron correctamente
        print('Datos guardados en SharedPreferences:');
        print('  - accessToken: ${token.substring(0, 10)}...');
        print('  - userId: $userId');
        print('  - userName: $userName');
        print('  - userRole: $userRole');
        print('  - userEmail: ${email.text.trim()}');

        if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Bienvenido, $userName!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // REDIRECCIÓN SEGÚN EL ROL
          _redirectByRole(userRole);
        }
      } else {
        // LOGIN FALLÓ
        print('Login falló: ${authResponse.error}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResponse.error ?? 'Error en el login'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error inesperado durante login: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con el servidor: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Método auxiliar para obtener rol del usuario
  /*Future<String?> _getUserRole(String token, String userId) async {
    try {
      // Usar DatabaseService directamente ya que el token está configurado
      final response = await DatabaseService.get<dynamic>(
        '/users/$userId',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        Map<String, dynamic> userData = response.data;

        // Manejar diferentes estructuras de respuesta
        if (userData.containsKey('data')) {
          userData = userData['data'];
        } else if (userData.containsKey('user')) {
          userData = userData['user'];
        }

        final rol = userData['rol']?.toString();
        return rol?.isNotEmpty == true ? rol!.toLowerCase() : null;
      }
    } catch (e) {
      print('Error obteniendo rol: $e');
    }
    return null;
  }*/

  // Método auxiliar para redirección
  void _redirectByRole(String userRole) {
    print('Redirigiendo según el rol: $userRole');

    switch (userRole.toLowerCase()) {
      case 'admin':
        print('Navegando a HomeAdminScreen...');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/homeAdmin',
          (route) => false,
        );
        break;
      case 'inspector':
      case 'ayudante':
        print('Navegando a HomePage (inspector/ayudante)...');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      default:
        print('Navegando a HomePage (usuario general)...');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SismosApp',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: AppLogo()),
                  const SizedBox(height: 24),
                  const ConnectionTestAndroid(),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Iniciar sesión',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Ingrese su correo y su contraseña para iniciar sesión',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppEmailField(controller: email),
                        const SizedBox(height: 12),
                        AppPasswordField(controller: password),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot');
                            },
                            child: const Text('¿Olvidó su contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loginBackend,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Aún no tienes una cuenta? ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(255, 94, 94, 94),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Text(
                                'Registrarse',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color.fromARGB(255, 27, 27, 27),
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
        ),
      ),
    );
  }
}
