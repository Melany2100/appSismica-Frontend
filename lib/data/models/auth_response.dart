import 'user_response.dart';

class AuthResponse {
  final bool success;
  final String? token;
  final int? userId; // Tu servidor devuelve userId en lugar de user completo
  final String? nombre;
  final String? rol;
  final UserData? user;
  final String message;
  final String? error;
  final int? statusCode;

  AuthResponse._({
    required this.success,
    this.token,
    this.userId,
    this.nombre,
    this.rol,
    this.user,
    required this.message,
    this.error,
    this.statusCode,
  });

  // Respuesta exitosa - CORREGIDO
  factory AuthResponse.success({
    String? token,
    int? userId,
    String? nombre, // CORREGIDO: Agregar nombre como parámetro separado
    String? rol,
    UserData? user,
    required String message,
  }) {
    return AuthResponse._(
      success: true,
      token: token,
      userId: userId,
      nombre: nombre, // CORREGIDO: Asignar el nombre
      rol: rol,
      user: user,
      message: message,
    );
  }

  // Respuesta de error
  factory AuthResponse.failure({required String error, int? statusCode}) {
    return AuthResponse._(
      success: false,
      message: error,
      error: error,
      statusCode: statusCode,
    );
  }

  // Obtener ID del usuario
  int? get userIdValue => userId;

  // Obtener nombre del usuario con fallback
  String get userNameValue => nombre ?? 'Usuario';

  // Verificar si tiene token válido
  bool get hasValidToken => token != null && token!.isNotEmpty;

  String get userRoleValue {
    final normalizedRole = rol?.trim().toLowerCase();
    return normalizedRole?.isNotEmpty == true ? normalizedRole! : 'user';
  }

  // Debug: Mostrar información del auth response
  Map<String, dynamic> toDebugMap() {
    return {
      'success': success,
      'token': token != null ? '${token!.substring(0, 10)}...' : null,
      'userId': userId,
      'nombre': nombre,
      'rol': rol,
      'activo': user?.activo,
      'message': message,
      'error': error,
      'statusCode': statusCode,
    };
  }
}
