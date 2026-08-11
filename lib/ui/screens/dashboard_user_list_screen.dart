import 'package:flutter/material.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_response.dart';

class DashboardUserListScreen extends StatefulWidget {
  final String listType;
  const DashboardUserListScreen({super.key, required this.listType});

  @override
  State<DashboardUserListScreen> createState() => _DashboardUserListScreenState();
}

class _DashboardUserListScreenState extends State<DashboardUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _currentTitle;

  List<UserData> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.listType;
    _searchController.addListener(() => setState(() {}));
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final response = await UserService.getAll();
    if (mounted && response.success && response.data != null) {
      setState(() {
        _users = response.data!;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserData> get _visibleUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesStatus = switch (_currentTitle) {
        'Usuarios activos' => user.activo,
        'Usuarios inactivos' => !user.activo,
        _ => true,
      };

      final matchesQuery = query.isEmpty ||
          user.nombre.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.cedula?.toLowerCase().contains(query) ?? false);

      return matchesStatus && matchesQuery;
    }).toList();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filtrar por tipo de usuario',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: Icon(Icons.group,
                    color: _currentTitle == 'Usuarios registrados'
                        ? AppColors.primary
                        : Colors.grey),
                title: Text('Usuarios registrados',
                    style: TextStyle(
                        color: _currentTitle == 'Usuarios registrados'
                            ? AppColors.primary
                            : Colors.black87,
                        fontWeight: _currentTitle == 'Usuarios registrados'
                            ? FontWeight.bold
                            : FontWeight.normal)),
                onTap: () {
                  setState(() => _currentTitle = 'Usuarios registrados');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline,
                    color: _currentTitle == 'Usuarios activos'
                        ? AppColors.primary
                        : Colors.grey),
                title: Text('Usuarios activos',
                    style: TextStyle(
                        color: _currentTitle == 'Usuarios activos'
                            ? AppColors.primary
                            : Colors.black87,
                        fontWeight: _currentTitle == 'Usuarios activos'
                            ? FontWeight.bold
                            : FontWeight.normal)),
                onTap: () {
                  setState(() => _currentTitle = 'Usuarios activos');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined,
                    color: _currentTitle == 'Usuarios inactivos'
                        ? AppColors.primary
                        : Colors.grey),
                title: Text('Usuarios inactivos',
                    style: TextStyle(
                        color: _currentTitle == 'Usuarios inactivos'
                            ? AppColors.primary
                            : Colors.black87,
                        fontWeight: _currentTitle == 'Usuarios inactivos'
                            ? FontWeight.bold
                            : FontWeight.normal)),
                onTap: () {
                  setState(() => _currentTitle = 'Usuarios inactivos');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showLastAccessDate = _currentTitle != 'Usuarios activos';
    final visibleUsers = _visibleUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon:
                          Icon(Icons.search, color: Colors.grey, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primary),
                      onPressed: _showFilterModal),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleUsers.isEmpty
                  ? const Center(
                  child: Text('No hay usuarios para mostrar.',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: visibleUsers.length,
                itemBuilder: (context, index) =>
                    _buildUserCard(visibleUsers[index], showLastAccessDate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserData user, bool showLastAccessDate) {
    final image = user.hasProfileImage ? NetworkImage(user.fotoPerfilUrl!) : null;
    final initial = user.nombre.isNotEmpty ? user.nombre.substring(0, 1).toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: image,
              child: image == null
                  ? Text(initial,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.rol.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  Text(
                    user.nombre.isEmpty ? 'Sin nombre' : user.nombre,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.gray500, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (showLastAccessDate)
                        _buildDetailText('Último acceso: N/A'),
                      _buildDetailText('0 edificios evaluados'),
                    ],
                  ),
                ],
              ),
            ),
            _statusBadge(user.activo),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _statusBadge(bool active) {
    final color = active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}