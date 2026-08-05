import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../data/models/user_response.dart';
import 'edit_profile_screen.dart';
import '../../core/services/auth_service.dart';

class ProfileAdminScreen extends StatefulWidget {
  final String? userId;
  final String? token;

  const ProfileAdminScreen({super.key, this.userId, this.token});

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  UserData? _userData;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      // Obtener credenciales
      String? userId = widget.userId;
      String? token = widget.token;

      if (userId == null || token == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId');
        token = prefs.getString('accessToken');
      }

      debugPrint('Cargando perfil - userId: $userId');

      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = "No se encontró información de sesión válida.";
        });
        return;
      }

      // Usar el servicio actualizado
      final response = await UserService.getUserById(
        token: token,
        userId: userId,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('Respuesta del servicio: ${response.success}');

      if (response.success && response.data != null) {
        setState(() {
          _userData = response.data;
          _loading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = response.error ?? response.message;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = "Error de conexión: $e";
      });
      debugPrint("Excepción al cargar usuario: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userRole');

    AuthService.logout();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _navigateToEditProfile() async {
    String? userId = widget.userId;
    String? token = widget.token;

    if (userId == null || token == null) {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      token = prefs.getString('accessToken');
    }

    if (userId == null || token == null || _userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se puede acceder a editar perfil'),
        ),
      );
      return;
    }

    // Convertir UserData a Map para compatibilidad con EditProfileScreen
    final userDataMap = _userData!.toCompatibleMap();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userId: userId,
          token: token,
          userData: userDataMap,
        ),
      ),
    );

    // Recargar si hubo cambios
    if (result != null && result is Map && result['success'] == true) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
      _fetchUser();
    }
  }

  // Widget para mostrar la imagen de perfil con manejo mejorado
  Widget _buildProfileImage() {
    // Usar el getter hasProfileImage del modelo UserData actualizado
    if (_userData!.hasProfileImage) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.gray300,
        child: ClipOval(
          child: Image.network(
            _userData!.fotoPerfilUrl!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray300,
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Si hay error cargando la imagen, mostrar placeholder
              return _buildPlaceholderAvatar();
            },
          ),
        ),
      );
    } else {
      // No hay imagen en la base de datos, mostrar placeholder
      return _buildPlaceholderAvatar();
    }
  }

  Widget _buildPlaceholderAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Icon(Icons.person, size: 50, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                "Cargando perfil...",
                style: TextStyle(color: AppColors.text),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _errorMessage = null;
                  });
                  _fetchUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "No se encontró información del usuario.",
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Imagen de perfil con manejo mejorado
              _buildProfileImage(),

              const SizedBox(height: 20),

              // Información del usuario
              Text(
                _userData!.nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _userData!.email,
                style: const TextStyle(color: AppColors.gray500, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Badge del rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(_userData!.rol).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRoleColor(_userData!.rol).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getRoleDisplayName(_userData!.rol),
                  style: TextStyle(
                    color: _getRoleColor(_userData!.rol),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Información adicional en cards
              if (_userData!.cedula != null && _userData!.cedula!.isNotEmpty ||
                  _userData!.telefono != null &&
                      _userData!.telefono!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información adicional',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_userData!.cedula != null &&
                          _userData!.cedula!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.badge,
                              size: 20,
                              color: AppColors.gray500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Cédula: ${_userData!.cedula}",
                              style: const TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_userData!.telefono != null &&
                          _userData!.telefono!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 20,
                              color: AppColors.gray500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Teléfono: ${_userData!.telefono}",
                              style: const TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botones de acción
              if (_userData!.rol.toLowerCase() == "admin") ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/userList');
                    },
                    icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                    ),
                    label: const Text("Asignar roles"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("Editar perfil"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Cerrar sesión"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods para colores y nombres de roles
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'inspector':
        return Colors.blue;
      case 'ayudante':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'inspector':
        return 'Inspector';
      case 'ayudante':
        return 'Ayudante';
      default:
        return role.isNotEmpty ? role.toUpperCase() : 'Sin rol';
    }
  }
}
