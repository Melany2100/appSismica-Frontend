class UserResponse {
  final bool success;
  final String message;
  final UserData? data;
  final String? error;

  UserResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'error': error,
    };
  }

  factory UserResponse.success(
    UserData data, {
    String message = 'Operación exitosa',
  }) {
    return UserResponse(success: true, message: message, data: data);
  }

  factory UserResponse.error(String error) {
    return UserResponse(success: false, message: 'Error', error: error);
  }
}

class UsersListResponse {
  final bool success;
  final String message;
  final List<UserData>? data;
  final String? error;

  UsersListResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory UsersListResponse.fromJson(Map<String, dynamic> json) {
    List<UserData>? usersList;

    if (json['data'] != null) {
      if (json['data'] is List) {
        usersList = (json['data'] as List)
            .map(
              (userData) => UserData.fromJson(userData as Map<String, dynamic>),
            )
            .toList();
      }
    }

    return UsersListResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: usersList,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((user) => user.toJson()).toList(),
      'error': error,
    };
  }

  factory UsersListResponse.success(
    List<UserData> data, {
    String message = 'Lista obtenida correctamente',
  }) {
    return UsersListResponse(success: true, message: message, data: data);
  }

  factory UsersListResponse.error(String error) {
    return UsersListResponse(success: false, message: 'Error', error: error);
  }
}

// ACTUALIZACIÓN EN UserData - user_response.dart
class UserData {
  final int idUsuario;
  final String nombre;
  final String email;
  final String? cedula;
  final String? telefono;
  final String rol;
  final String? direccion;
  final String? fotoPerfilUrl;
  final bool activo;

  UserData({
    required this.idUsuario,
    required this.nombre,
    required this.email,
    this.cedula,
    this.telefono,
    required this.rol,
    this.direccion,
    this.fotoPerfilUrl,
    this.activo = true,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    // Manejar diferentes formatos de ID
    int? userId;
    if (json['id_usuario'] != null) {
      userId = json['id_usuario'] is int
          ? json['id_usuario']
          : int.tryParse(json['id_usuario'].toString());
    } else if (json['id'] != null) {
      userId = json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString());
    } else if (json['userId'] != null) {
      userId = json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId'].toString());
    }

    // MEJORADO: Manejo de URL de foto más robusto
    String? fotoUrl;
    if (json['foto_perfil_url'] != null &&
        json['foto_perfil_url'].toString().trim().isNotEmpty) {
      fotoUrl = json['foto_perfil_url'].toString().trim();
    } else if (json['foto_url'] != null &&
        json['foto_url'].toString().trim().isNotEmpty) {
      fotoUrl = json['foto_url'].toString().trim();
    } else if (json['foto'] != null &&
        json['foto'].toString().trim().isNotEmpty) {
      fotoUrl = json['foto'].toString().trim();
    } else if (json['profileImage'] != null &&
        json['profileImage'].toString().trim().isNotEmpty) {
      fotoUrl = json['profileImage'].toString().trim();
    }

    // Validar que la URL sea válida (opcional)
    if (fotoUrl != null && !_isValidImageUrl(fotoUrl)) {
      print('Warning: Invalid image URL detected: $fotoUrl');
      fotoUrl = null;
    }

    return UserData(
      idUsuario: userId ?? 0,
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cedula: json['cedula']?.toString(),
      telefono: json['telefono']?.toString() ?? json['phone']?.toString(),
      rol: json['rol']?.toString() ?? json['role']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? json['address']?.toString(),
      fotoPerfilUrl: fotoUrl,
      // Los endpoints /users y /users/inactive no incluyen este campo.
      // En esos casos el llamador puede sobrescribir el valor conocido.
      activo: json['activo'] is bool ? json['activo'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'email': email,
      'cedula': cedula,
      'telefono': telefono,
      'rol': rol,
      'direccion': direccion,
      'foto_perfil_url': fotoPerfilUrl,
      'activo': activo,
    };
  }

  // NUEVO: Método para validar URLs de imagen
  static bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Debe tener scheme (http/https)
      if (!uri.hasScheme) return false;

      // Solo permitir http y https
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;

      // Debe tener host
      if (!uri.hasAuthority || uri.host.isEmpty) return false;

      // Opcional: validar extensiones de imagen
      final path = uri.path.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

      // Si tiene extensión, debe ser una válida para imagen
      if (path.contains('.')) {
        return validExtensions.any((ext) => path.endsWith(ext));
      }

      return true; // URL válida sin extensión específica
    } catch (e) {
      return false;
    }
  }

  // MEJORADO: Getter para verificar si tiene foto
  bool get hasProfileImage {
    return fotoPerfilUrl != null &&
        fotoPerfilUrl!.trim().isNotEmpty &&
        _isValidImageUrl(fotoPerfilUrl!);
  }

  // NUEVO: Getter para obtener URL de imagen o placeholder
  String get profileImageUrl {
    if (hasProfileImage) {
      return fotoPerfilUrl!;
    }
    return ''; // Retornar string vacío para usar placeholder
  }

  // Método helper para convertir a Map compatible con pantallas existentes
  Map<String, dynamic> toCompatibleMap() {
    return {
      'id': idUsuario,
      'id_usuario': idUsuario,
      'nombre': nombre,
      'name': nombre,
      'email': email,
      'cedula': cedula,
      'telefono': telefono,
      'phone': telefono,
      'rol': rol,
      'role': rol,
      'direccion': direccion,
      'address': direccion,
      'foto_perfil_url': fotoPerfilUrl,
      'foto_url': fotoPerfilUrl, // Alias para compatibilidad
      'foto': fotoPerfilUrl, // Otro alias
      'profileImage': fotoPerfilUrl, // Otro alias
      'hasProfileImage': hasProfileImage, // Helper
      'activo': activo,
    };
  }

  // Método para verificar si el usuario tiene un rol asignado
  bool get hasRole {
    final normalizedRole = rol.trim().toLowerCase();
    return normalizedRole.isNotEmpty &&
        normalizedRole != 'null' &&
        normalizedRole != 'sin asignar' &&
        normalizedRole != 'undefined';
  }

  // Método para obtener el nombre de display del rol
  String get roleDisplayName {
    switch (rol.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'inspector':
        return 'Inspector';
      case 'ayudante':
        return 'Ayudante';
      default:
        return hasRole ? rol.toUpperCase() : 'Sin asignar';
    }
  }

  // Método para verificar si es un rol válido
  bool get hasValidRole {
    const validRoles = ['admin', 'inspector', 'ayudante'];
    return validRoles.contains(rol.toLowerCase());
  }

  // Método para copiar con cambios
  UserData copyWith({
    int? idUsuario,
    String? nombre,
    String? email,
    String? cedula,
    String? telefono,
    String? rol,
    String? direccion,
    String? fotoPerfilUrl,
    bool? activo,
  }) {
    return UserData(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      direccion: direccion ?? this.direccion,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'UserData{idUsuario: $idUsuario, nombre: $nombre, email: $email, rol: $rol, activo: $activo, hasImage: $hasProfileImage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData && other.idUsuario == idUsuario;
  }

  @override
  int get hashCode => idUsuario.hashCode;
}

// Modelo específico para estadísticas de usuarios (si se necesita)
class UserStatistics {
  final int totalUsers;
  final int usersWithRole;
  final int usersWithoutRole;
  final int adminUsers;
  final int inspectorUsers;
  final int ayudanteUsers;

  UserStatistics({
    required this.totalUsers,
    required this.usersWithRole,
    required this.usersWithoutRole,
    required this.adminUsers,
    required this.inspectorUsers,
    required this.ayudanteUsers,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalUsers: json['totalUsers'] ?? 0,
      usersWithRole: json['usersWithRole'] ?? 0,
      usersWithoutRole: json['usersWithoutRole'] ?? 0,
      adminUsers: json['adminUsers'] ?? 0,
      inspectorUsers: json['inspectorUsers'] ?? 0,
      ayudanteUsers: json['ayudanteUsers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'usersWithRole': usersWithRole,
      'usersWithoutRole': usersWithoutRole,
      'adminUsers': adminUsers,
      'inspectorUsers': inspectorUsers,
      'ayudanteUsers': ayudanteUsers,
    };
  }
}

// Modelo para respuesta de asignación de rol
class RoleAssignmentResponse {
  final bool success;
  final String message;
  final UserData? userData;
  final String? error;

  RoleAssignmentResponse({
    required this.success,
    required this.message,
    this.userData,
    this.error,
  });

  factory RoleAssignmentResponse.fromJson(Map<String, dynamic> json) {
    return RoleAssignmentResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      userData: json['data'] != null ? UserData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }

  factory RoleAssignmentResponse.success(UserData userData, {String? message}) {
    return RoleAssignmentResponse(
      success: true,
      message: message ?? 'Rol asignado correctamente',
      userData: userData,
    );
  }

  factory RoleAssignmentResponse.error(String error) {
    return RoleAssignmentResponse(
      success: false,
      message: 'Error al asignar rol',
      error: error,
    );
  }
}
