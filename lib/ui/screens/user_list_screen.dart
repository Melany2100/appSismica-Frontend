import 'package:flutter/material.dart';

import '../../core/services/session_service.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/database_response.dart';
import '../../data/models/user_response.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  static const Map<String, String> _roleLabels = {
    'admin': 'Administrador',
    'inspector': 'Inspector',
    'ayudante': 'Ayudante',
  };

  final TextEditingController _searchController = TextEditingController();
  final Set<int> _busyUsers = <int>{};
  List<UserData> _users = <UserData>[];
  String _statusFilter = 'all';
  String _roleFilter = 'all';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilters);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilters)
      ..dispose();
    super.dispose();
  }

  void _refreshFilters() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUsers({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final response = await UserService.getAll();
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _users = response.data!;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = false;
      _error = response.statusCode == 403
          ? 'No tienes permisos para realizar esta acción.'
          : response.error ?? 'No se pudieron cargar los usuarios';
    });
  }

  List<UserData> get _visibleUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final matchesStatus = switch (_statusFilter) {
        'active' => user.activo,
        'inactive' => !user.activo,
        _ => true,
      };
      final matchesRole =
          _roleFilter == 'all' || user.rol.toLowerCase() == _roleFilter;
      final matchesQuery =
          query.isEmpty ||
          user.nombre.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.cedula?.toLowerCase().contains(query) ?? false);
      return matchesStatus && matchesRole && matchesQuery;
    }).toList();
  }

  bool _isCurrentUser(UserData user) =>
      SessionService.currentUser?.idUsuario == user.idUsuario;

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _changeRole(UserData user, String? newRole) async {
    if (newRole == null || newRole == user.rol.toLowerCase()) return;
    if (_isCurrentUser(user)) {
      _showMessage(
        'No puedes quitarte o cambiarte tu propio rol temporalmente.',
        isError: true,
      );
      return;
    }

    final confirmed = await _confirm(
      title: 'Cambiar rol',
      message: '¿Cambiar el rol de ${user.nombre} a ${_roleLabels[newRole]}?',
      action: 'Cambiar',
    );
    if (!confirmed || !mounted) return;

    await _runUserAction(
      user,
      () => UserService.updateRole(user.idUsuario, newRole),
      successMessage: 'Rol actualizado correctamente.',
    );
  }

  Future<void> _changeStatus(UserData user) async {
    if (_isCurrentUser(user)) {
      _showMessage('No puedes desactivar tu propia cuenta.', isError: true);
      return;
    }

    final activate = !user.activo;
    final confirmed = await _confirm(
      title: activate ? 'Reactivar usuario' : 'Desactivar usuario',
      message: activate
          ? '¿Reactivar la cuenta de ${user.nombre}?'
          : '¿Desactivar la cuenta de ${user.nombre}?',
      action: activate ? 'Reactivar' : 'Desactivar',
      destructive: !activate,
    );
    if (!confirmed || !mounted) return;

    await _runUserAction(
      user,
      () => UserService.updateStatus(user.idUsuario, activate),
      successMessage: activate
          ? 'Usuario reactivado correctamente.'
          : 'Usuario desactivado correctamente.',
    );
  }

  Future<void> _runUserAction(
    UserData user,
    Future<DatabaseResponse<UserData>> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _busyUsers.add(user.idUsuario));
    final response = await action();
    if (!mounted) return;

    if (response.success == true) {
      await _loadUsers(showLoader: false);
      if (mounted) _showMessage(successMessage);
    } else {
      final message = response.statusCode == 403
          ? 'No tienes permisos para realizar esta acción.'
          : response.error?.toString() ?? 'No se pudo completar la acción';
      _showMessage(message, isError: true);
    }

    if (mounted) {
      setState(() => _busyUsers.remove(user.idUsuario));
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administración de usuarios'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadUsers,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, correo o cédula',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusChip('all', 'Todos', _users.length),
                        const SizedBox(width: 8),
                        _statusChip(
                          'active',
                          'Activos',
                          _users.where((user) => user.activo).length,
                        ),
                        const SizedBox(width: 8),
                        _statusChip(
                          'inactive',
                          'Inactivos',
                          _users.where((user) => !user.activo).length,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _roleFilter,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todos los roles'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrador'),
                    ),
                    DropdownMenuItem(
                      value: 'inspector',
                      child: Text('Inspector'),
                    ),
                    DropdownMenuItem(
                      value: 'ayudante',
                      child: Text('Ayudante'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _roleFilter = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, int count) {
    return ChoiceChip(
      selected: _statusFilter == value,
      label: Text('$label ($count)'),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            Center(
              child: FilledButton(
                onPressed: _loadUsers,
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      );
    }

    final visibleUsers = _visibleUsers;
    if (visibleUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay usuarios que coincidan con los filtros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: visibleUsers.length,
        itemBuilder: (context, index) => _buildUserCard(visibleUsers[index]),
      ),
    );
  }

  Widget _buildUserCard(UserData user) {
    final busy = _busyUsers.contains(user.idUsuario);
    final self = _isCurrentUser(user);
    final image = user.hasProfileImage
        ? NetworkImage(user.fotoPerfilUrl!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundImage: image,
                  child: image == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.nombre.isEmpty ? 'Sin nombre' : user.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (self) ...[
                            const SizedBox(width: 8),
                            const Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text('Tú'),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppColors.gray500),
                      ),
                      if (user.cedula?.isNotEmpty == true)
                        Text(
                          'CI: ${user.cedula}',
                          style: const TextStyle(color: AppColors.gray500),
                        ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _statusBadge(user.activo),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _roleLabels.containsKey(user.rol.toLowerCase())
                        ? user.rol.toLowerCase()
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _roleLabels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: busy || self
                        ? null
                        : (role) => _changeRole(user, role),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: busy || self ? null : () => _changeStatus(user),
                  icon: Icon(user.activo ? Icons.person_off : Icons.person_add),
                  label: Text(user.activo ? 'Desactivar' : 'Reactivar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.activo ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            if (self) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tu rol y estado no se pueden modificar desde esta pantalla.',
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    final color = active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
