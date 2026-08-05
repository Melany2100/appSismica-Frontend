import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';

class AssignRoleScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AssignRoleScreen({super.key, required this.user});

  @override
  State<AssignRoleScreen> createState() => _AssignRoleScreenState();
}

class _AssignRoleScreenState extends State<AssignRoleScreen> {
  String? _selectedRole;
  String? _currentRole;
  bool _loading = false;

  final List<Map<String, String>> _roles = [
    {'value': 'inspector', 'label': 'Inspector'},
    {'value': 'ayudante', 'label': 'Ayudante'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeCurrentRole();
  }

  void _initializeCurrentRole() {
    _currentRole = widget.user['rol']?.toString();

    // Si el usuario ya tiene un rol válido, establecerlo como seleccionado
    if (_currentRole != null && _currentRole!.isNotEmpty) {
      final normalizedRole = _currentRole!.trim().toLowerCase();
      if (normalizedRole == 'inspector' || normalizedRole == 'ayudante') {
        _selectedRole = normalizedRole;
      }
    }
  }

  Future<void> _saveRole() async {
    if (_selectedRole == null) return;

    // Verificar si hay cambios
    if (_currentRole != null &&
        _currentRole!.toLowerCase() == _selectedRole!.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cambios que guardar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      if (token.isEmpty) {
        _showErrorMessage('Token de autenticación no encontrado');
        return;
      }

      final rawUserId =
          widget.user['id'] ??
          widget.user['id_usuario'] ??
          widget.user['userId'];

      if (rawUserId == null) {
        _showErrorMessage('ID de usuario no válido');
        return;
      }

      final userId = rawUserId.toString().trim();

      if (userId.isEmpty) {
        _showErrorMessage('ID de usuario no válido');
        return;
      }

      debugPrint(
        '🎯 Cambiando rol de $_currentRole a $_selectedRole para usuario $userId',
      );

      // Usar el servicio para asignar/cambiar rol
      final response = await UserService.assignRole(
        token: token,
        userId: userId,
        role: _selectedRole!,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      if (response.success) {
        final actionText = _currentRole == null || _currentRole!.isEmpty
            ? 'asignado'
            : 'cambiado';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rol ${_getRoleDisplayName(_selectedRole!)} $actionText con éxito',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Retornar true para indicar que hubo cambios
        Navigator.pop(context, true);
      } else {
        _showErrorMessage(response.error ?? 'Error desconocido al asignar rol');
      }
    } catch (e) {
      _showErrorMessage('Error de conexión: $e');
      debugPrint('Error en _saveRole: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'inspector':
        return 'Inspector';
      case 'ayudante':
        return 'Ayudante';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'inspector':
        return Colors.blue;
      case 'ayudante':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  bool _hasChanges() {
    if (_selectedRole == null) return false;
    if (_currentRole == null || _currentRole!.isEmpty) return true;
    return _currentRole!.toLowerCase() != _selectedRole!.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final foto = user['foto_perfil_url']?.toString() ?? '';
    final nombre = user['nombre'] ?? 'Sin nombre';
    final email = user['email'] ?? 'Sin email';
    final cedula = user['cedula']?.toString() ?? '';

    // Determinar el texto del rol actual
    String currentRoleText;
    Color currentRoleColor;

    if (_currentRole == null ||
        _currentRole!.isEmpty ||
        _currentRole!.toLowerCase() == 'null' ||
        _currentRole!.toLowerCase() == 'sin asignar') {
      currentRoleText = "Sin rol asignado";
      currentRoleColor = Colors.orange;
    } else {
      currentRoleText = _getRoleDisplayName(_currentRole!);
      currentRoleColor = _getRoleColor(_currentRole!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentRole == null || _currentRole!.isEmpty
              ? "Asignar rol"
              : "Cambiar rol",
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            const Text(
              "Información del Usuario",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),

            // Card con información del usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Imagen de perfil
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        (foto.isNotEmpty &&
                            Uri.tryParse(foto)?.isAbsolute == true)
                        ? NetworkImage(foto)
                        : const AssetImage(
                                "assets/images/avatar_placeholder.png",
                              )
                              as ImageProvider,
                  ),
                  const SizedBox(height: 16),

                  // Información del usuario
                  _buildInfoRow(Icons.person, "Nombre", nombre),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.email, "Correo", email),
                  if (cedula.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.badge, "Cédula", cedula),
                  ],
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.admin_panel_settings,
                    "Rol actual",
                    currentRoleText,
                    valueColor: currentRoleColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sección de asignación/cambio de rol
            Text(
              _currentRole == null || _currentRole!.isEmpty
                  ? "Asignar Rol"
                  : "Cambiar Rol",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown para seleccionar rol
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedRole,
                hint: const Text(
                  "Seleccionar rol",
                  style: TextStyle(color: AppColors.gray500),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primary,
                ),
                items: _roles.map((role) {
                  final isCurrentRole =
                      _currentRole?.toLowerCase() ==
                      role['value']!.toLowerCase();
                  return DropdownMenuItem<String>(
                    value: role['value'],
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getRoleColor(role['value']!),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            role['label']!,
                            style: TextStyle(
                              color: isCurrentRole
                                  ? AppColors.gray500
                                  : AppColors.text,
                              fontWeight: isCurrentRole
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCurrentRole)
                          Text(
                            "(Actual)",
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedRole = val),
              ),
            ),

            // Información sobre los roles
            if (_selectedRole != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getRoleColor(_selectedRole!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRoleColor(_selectedRole!).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _getRoleColor(_selectedRole!),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Sobre el rol ${_getRoleDisplayName(_selectedRole!)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(_selectedRole!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRoleDescription(_selectedRole!),
                      style: TextStyle(
                        fontSize: 13,
                        color: _getRoleColor(_selectedRole!).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Botón para guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedRole != null && _hasChanges() && !_loading)
                    ? _saveRole
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedRole != null && _hasChanges())
                      ? AppColors.primary
                      : AppColors.gray300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _getButtonText(),
                        style: TextStyle(
                          color: (_selectedRole != null && _hasChanges())
                              ? Colors.white
                              : AppColors.gray500,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getWarningText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? AppColors.text,
              fontWeight: valueColor != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'inspector':
        return 'Los inspectores pueden realizar evaluaciones completas de edificios, generar reportes y supervisar inspecciones.';
      case 'ayudante':
        return 'Los ayudantes pueden asistir en las inspecciones y acceder a información básica de los edificios.';
      default:
        return 'Rol con permisos básicos del sistema.';
    }
  }

  String _getButtonText() {
    if (_selectedRole == null) {
      return "Seleccione un rol";
    } else if (!_hasChanges()) {
      return "Sin cambios";
    } else if (_currentRole == null || _currentRole!.isEmpty) {
      return "Asignar rol ${_getRoleDisplayName(_selectedRole!)}";
    } else {
      return "Cambiar a ${_getRoleDisplayName(_selectedRole!)}";
    }
  }

  String _getWarningText() {
    if (_currentRole == null || _currentRole!.isEmpty) {
      return "Esta acción asignará el rol seleccionado al usuario. Una vez asignado, el usuario tendrá acceso a las funciones correspondientes.";
    } else {
      return "Esta acción cambiará el rol actual del usuario. Los permisos y accesos se actualizarán inmediatamente.";
    }
  }
}
