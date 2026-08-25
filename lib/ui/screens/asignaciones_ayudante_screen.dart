import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/assignment_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_colors.dart';

class AsignacionesAyudanteScreen extends StatefulWidget {
  const AsignacionesAyudanteScreen({super.key});

  @override
  State<AsignacionesAyudanteScreen> createState() =>
      _AsignacionesAyudanteScreenState();
}

class _AsignacionesAyudanteScreenState
    extends State<AsignacionesAyudanteScreen> {
  bool _loading = true;
  bool _hasData = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _asignaciones = [];

  @override
  void initState() {
    super.initState();
    _loadAsignaciones();
  }

  Future<void> _loadAsignaciones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('userId') ?? '');
      final token = prefs.getString('accessToken');

      if (userId == null || token == null) {
        setState(() {
          _loading = false;
          _hasData = false;
          _errorMessage = 'Sesión no válida. Inicie sesión nuevamente.';
        });
        return;
      }

      DatabaseService.setAuthToken(token);
      final response = await AssignmentService.getAssignmentsByHelper(userId);

      if (response.success) {
        final asignaciones = (response.data ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        setState(() {
          _asignaciones = asignaciones;
          _hasData = asignaciones.isNotEmpty;
          _loading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _loading = false;
          _hasData = false;
          _errorMessage = response.error ?? 'Error al cargar asignaciones';
        });
      }
    } catch (e) {
      debugPrint('Error cargando asignaciones: $e');
      setState(() {
        _loading = false;
        _hasData = false;
        _errorMessage = 'Error al cargar asignaciones';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Asignaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando asignaciones...',
              style: TextStyle(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _errorMessage = null;
                });
                _loadAsignaciones();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (!_hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: AppColors.gray500.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'No tiene formularios asignados,\ncomuníquese con su inspector',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.gray500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAsignaciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _asignaciones.length,
        itemBuilder: (context, index) {
          final item = _asignaciones[index];
          return _buildAssignmentCard(
            nombre: item['nombre_edificio']?.toString() ?? 'Sin nombre',
            direccion: item['direccion']?.toString() ?? 'Sin dirección',
            inspecciones: _parseInt(item['numero_inspecciones']) ?? 0,
            inspector: item['nombre_inspector']?.toString() ?? 'Sin inspector',
            estado: item['estado']?.toString() ?? 'pendiente',
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard({
    required String nombre,
    required String direccion,
    required int inspecciones,
    required String inspector,
    required String estado,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        direccion,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Inspector: $inspector',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.assignment,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$inspecciones inspección(es)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Estado: $estado',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray500),
        ],
      ),
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
