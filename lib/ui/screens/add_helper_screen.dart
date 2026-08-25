import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/assignment_service.dart';
import '../../core/services/building_list_service.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/building_list_response.dart';

class AddHelperScreen extends StatefulWidget {
  const AddHelperScreen({super.key});

  @override
  State<AddHelperScreen> createState() => _AddHelperScreenState();
}

class _AddHelperScreenState extends State<AddHelperScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _cedulaControllers = {};
  final Map<int, bool> _expandidos = {};
  final Set<int> _assigningBuildings = {};
  int _selectedIndex = 0;
  int? _inspectorId;
  bool _loading = true;
  String? _errorMessage;
  List<BuildingData> _edificios = [];
  List<BuildingData> _filteredEdificios = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      _inspectorId = int.tryParse(prefs.getString('userId') ?? '');

      if (token == null || _inspectorId == null) {
        setState(() {
          _loading = false;
          _errorMessage = 'Sesión no válida. Inicie sesión nuevamente.';
        });
        return;
      }

      DatabaseService.setAuthToken(token);
      final response = await BuildingListService.getBuildings();

      if (!mounted) return;
      setState(() {
        _edificios = response.buildings ?? [];
        _filteredEdificios = List.from(_edificios);
        _loading = false;
        _errorMessage = response.success ? null : response.friendlyError;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Error al cargar edificios: $e';
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredEdificios = _edificios.where((edificio) {
        return edificio.nombreEdificio.toLowerCase().contains(query) ||
            (edificio.inspector ?? '').toLowerCase().contains(query) ||
            (edificio.direccion ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  void _alternarExpandir(int buildingId) {
    setState(() {
      _expandidos[buildingId] = !(_expandidos[buildingId] ?? false);
      if (_expandidos[buildingId] == true) {
        _cedulaControllers.putIfAbsent(buildingId, TextEditingController.new);
      }
    });
  }

  Future<void> _asignarAyudante(BuildingData edificio) async {
    final controller = _cedulaControllers[edificio.idEdificio];
    final cedula = controller?.text.trim() ?? '';
    final inspectorId = _inspectorId;
    if (cedula.isEmpty || inspectorId == null) return;

    setState(() => _assigningBuildings.add(edificio.idEdificio));

    try {
      final helperResponse = await AssignmentService.findHelperByCedula(cedula);
      if (!helperResponse.success || helperResponse.data == null) {
        _showMessage(
          helperResponse.error ??
              'No se encontró un ayudante activo con esa cédula',
          isError: true,
        );
        return;
      }

      final helperId = _parseInt(helperResponse.data!['id_usuario']);
      if (helperId == null) {
        _showMessage(
          'El backend no devolvió el id del ayudante',
          isError: true,
        );
        return;
      }

      final assignResponse = await AssignmentService.createAssignment(
        inspectorId: inspectorId,
        helperId: helperId,
        buildingId: edificio.idEdificio,
      );

      if (!assignResponse.success) {
        _showMessage(
          assignResponse.error ?? 'No se pudo asignar el ayudante',
          isError: true,
        );
        return;
      }

      _showMessage('Ayudante asignado correctamente');
      setState(() => _expandidos[edificio.idEdificio] = false);
      controller?.clear();
    } catch (e) {
      _showMessage('Error al asignar ayudante: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _assigningBuildings.remove(edificio.idEdificio));
      }
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _cedulaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Asignar ayudante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _errorMessage = null;
                  });
                  _loadBuildings();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por inspector, edificio o dirección',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${_filteredEdificios.length} edificio(s) encontrado(s)',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBuildings,
            child: _filteredEdificios.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: AppColors.gray500,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No se encontraron edificios con esos criterios',
                          style: TextStyle(color: AppColors.gray500),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredEdificios.length,
                    itemBuilder: (context, index) {
                      return _buildBuildingCard(_filteredEdificios[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingCard(BuildingData edificio) {
    final expandido = _expandidos[edificio.idEdificio] ?? false;
    final cedulaController = _cedulaControllers[edificio.idEdificio];
    final assigning = _assigningBuildings.contains(edificio.idEdificio);
    final cedulaValida = cedulaController?.text.trim().isNotEmpty == true;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.gray300.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    size: 40,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edificio.nombreEdificio,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inspector: ${edificio.inspector ?? 'Sin inspector'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        edificio.direccion ?? 'Sin dirección',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (expandido) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'Cédula del ayudante',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cedulaController,
                keyboardType: TextInputType.number,
                autofocus: true,
                enabled: !assigning,
                decoration: InputDecoration(
                  hintText: 'Ingrese el número de cédula',
                  filled: true,
                  fillColor: AppColors.gray300.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: cedulaValida && !assigning
                          ? () => _asignarAyudante(edificio)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.gray300,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: assigning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Asignar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: assigning
                        ? null
                        : () => _alternarExpandir(edificio.idEdificio),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: assigning
                      ? null
                      : () => _alternarExpandir(edificio.idEdificio),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Asignar ayudante',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
