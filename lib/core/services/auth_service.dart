import '../../data/models/auth_response.dart';
import '../../data/models/database_response.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';
import 'user_service.dart';

class AuthService {
  static Future<AuthResponse> login({
    required String email,
    required String password,
    int maxRetries = 2,
  }) async {
    final connection = await DatabaseService.checkConnection();
    if (!connection.success) {
      return AuthResponse.failure(
        error: 'Sin conexión al servidor. ${connection.error ?? ''}'.trim(),
      );
    }

    DatabaseResponse<Map<String, dynamic>>? lastResponse;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      lastResponse = await DatabaseService.post<Map<String, dynamic>>(
        DatabaseEndpoints.login,
        {'email': email.trim(), 'password': password},
      );

      if (lastResponse.success && lastResponse.data != null) {
        final data = lastResponse.data!;
        final token = data['token']?.toString();
        final userId = data['userId'] is int
            ? data['userId'] as int
            : int.tryParse(data['userId']?.toString() ?? '');

        if (data['success'] != true || token == null || userId == null) {
          return AuthResponse.failure(
            error: 'El servidor devolvió una sesión incompleta',
          );
        }

        DatabaseService.setAuthToken(token);

        // El JWT solo contiene id y email. El rol y el estado se obtienen aquí.
        final profileResponse = await UserService.getById(userId);
        if (!profileResponse.success || profileResponse.data == null) {
          DatabaseService.clearAuthToken();
          return AuthResponse.failure(
            error: profileResponse.error ?? 'No se pudo obtener el perfil',
            statusCode: profileResponse.statusCode,
          );
        }

        final user = profileResponse.data!;
        if (!user.activo) {
          DatabaseService.clearAuthToken();
          return AuthResponse.failure(
            error: 'La cuenta está desactivada. Contacta al administrador.',
            statusCode: 403,
          );
        }

        return AuthResponse.success(
          token: token,
          userId: userId,
          nombre: user.nombre,
          rol: user.rol.trim().toLowerCase(),
          user: user,
          message: '¡Login exitoso! Bienvenido ${user.nombre}',
        );
      }

      final statusCode = lastResponse.statusCode;
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return AuthResponse.failure(
          error: lastResponse.error ?? _defaultLoginError(statusCode),
          statusCode: statusCode,
        );
      }

      if (attempt + 1 < maxRetries) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    return AuthResponse.failure(
      error: lastResponse?.error ?? 'No fue posible conectar con el servidor',
      statusCode: lastResponse?.statusCode,
    );
  }

  static String _defaultLoginError(int statusCode) {
    switch (statusCode) {
      case 400:
      case 401:
        return 'Email o contraseña incorrectos';
      case 403:
        return 'No tienes permisos para iniciar sesión';
      case 404:
        return 'Servicio de autenticación no encontrado';
      case 422:
        return 'Email o contraseña con formato inválido';
      default:
        return 'No fue posible iniciar sesión';
    }
  }

  static void logout() => DatabaseService.clearAuthToken();

  static bool isLoggedIn() => DatabaseService.hasAuthToken();

  static String? getCurrentToken() => DatabaseService.getAuthToken();

  static Future<DatabaseResponse<dynamic>> forgotPassword({
    String? email,
    String? telefono,
  }) {
    return DatabaseService.post<dynamic>(DatabaseEndpoints.forgotPassword, {
      'email': email,
      'telefono': telefono,
    });
  }

  static Future<DatabaseResponse<dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return DatabaseService.post<dynamic>(DatabaseEndpoints.resetPassword, {
      'token': token,
      'newPassword': newPassword,
    });
  }
}
