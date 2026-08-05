import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_response.dart';
import 'database_service.dart';
import 'user_service.dart';

class SessionRestoreResult {
  final UserData? user;
  final String? error;
  final int? statusCode;

  const SessionRestoreResult({this.user, this.error, this.statusCode});

  bool get isAuthenticated => user != null;
}

class SessionService {
  static UserData? _currentUser;

  static UserData? get currentUser => _currentUser;
  static bool get isAuthenticated =>
      _currentUser != null && DatabaseService.hasAuthToken();
  static bool get isAdmin => _currentUser?.rol.toLowerCase() == 'admin';

  static Future<SessionRestoreResult> restore({bool force = false}) async {
    if (!force && isAuthenticated) {
      return SessionRestoreResult(user: _currentUser);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final rawUserId = prefs.getString('userId');
    final userId = int.tryParse(rawUserId ?? '');

    if (token == null || token.isEmpty || userId == null) {
      await clear();
      return const SessionRestoreResult();
    }

    DatabaseService.setAuthToken(token);
    final response = await UserService.getById(userId);
    if (response.success && response.data != null) {
      if (!response.data!.activo) {
        await clear();
        return const SessionRestoreResult(
          error: 'La cuenta está desactivada',
          statusCode: 403,
        );
      }
      await persist(token: token, user: response.data!);
      return SessionRestoreResult(user: response.data!);
    }

    if (response.statusCode == 401) {
      await clear();
    }
    return SessionRestoreResult(
      error: response.error ?? 'No se pudo restaurar la sesión',
      statusCode: response.statusCode,
    );
  }

  static Future<void> persist({
    required String token,
    required UserData user,
  }) async {
    _currentUser = user;
    DatabaseService.setAuthToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    await prefs.setString('userId', user.idUsuario.toString());
    await prefs.setString('userName', user.nombre);
    await prefs.setString('userRole', user.rol.toLowerCase());
    await prefs.setString('userEmail', user.email);
    await prefs.setBool('userActive', user.activo);
    if (user.cedula != null) {
      await prefs.setString('userCedula', user.cedula!);
    } else {
      await prefs.remove('userCedula');
    }
  }

  static Future<void> clear() async {
    _currentUser = null;
    DatabaseService.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userRole');
    await prefs.remove('userEmail');
    await prefs.remove('userActive');
    await prefs.remove('userCedula');
  }
}
