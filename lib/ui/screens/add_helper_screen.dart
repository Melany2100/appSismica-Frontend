import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AddHelperScreen extends StatefulWidget {
  const AddHelperScreen({super.key});

  @override
  State<AddHelperScreen> createState() => _AddHelperScreenState();
}

class _AddHelperScreenState extends State<AddHelperScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _cedulaControllers = {};
  final Map<int, bool> _expandidos = {};
  int _selectedIndex = 0;

  final List<Map<String, String>> _mockEdificios = [
    {
      'nombre': 'Edificio Torres del Norte',
      'inspector': 'Carlos Mendoza',
      'direccion': 'Av. Siempre Viva 742',
      'fecha': '15/03/2026',
      'ayudante': 'Pendiente',
    },
    {
      'nombre': 'Centro Comercial Plaza Mayor',
      'inspector': 'Ana Lucía Pérez',
      'direccion': 'Calle 5ta #23-45',
      'fecha': '12/03/2026',
      'ayudante': 'Juan Rojas',
    },
    {
      'nombre': 'Residencial Los Alamos',
      'inspector': 'Carlos Mendoza',
      'direccion': 'Cra 8 #10-20',
      'fecha': '10/03/2026',
      'ayudante': 'Pendiente',
    },
    {
      'nombre': 'Edificio Municipal',
      'inspector': 'María Fernanda Torres',
      'direccion': 'Plaza Central 1-50',
      'fecha': '08/03/2026',
      'ayudante': 'Pendiente',
    },
  ];

  List<Map<String, String>> _filteredEdificios = [];

  @override
  void initState() {
    super.initState();
    _filteredEdificios = List.from(_mockEdificios);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEdificios = _mockEdificios.where((edificio) {
        final nombre = edificio['nombre']!.toLowerCase();
        final inspector = edificio['inspector']!.toLowerCase();
        return nombre.contains(query) || inspector.contains(query);
      }).toList();
    });
  }

  void _alternarExpandir(int index) {
    setState(() {
      _expandidos[index] = !(_expandidos[index] ?? false);
      if (_expandidos[index] == true) {
        _cedulaControllers[index] = TextEditingController();
      }
    });
  }

  void _asignarAyudante(int index) {
    final controller = _cedulaControllers[index];
    if (controller == null || controller.text.trim().isEmpty) return;
    setState(() {
      _mockEdificios[index]['ayudante'] = 'Cédula: ${controller.text.trim()}';
      _expandidos[index] = false;
      controller.dispose();
      _cedulaControllers.remove(index);
    });
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
              "Registro de Edificio",
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por inspector o edificio",
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
            child: _filteredEdificios.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.gray500,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No se encontraron edificios con esos criterios",
                            style: TextStyle(color: AppColors.gray500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                            child: const Text("Limpiar búsqueda"),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredEdificios.length,
                    itemBuilder: (context, index) {
                      final edificio = _filteredEdificios[index];
                      final tieneAyudante = edificio['ayudante'] != 'Pendiente';
                      final realIndex = _mockEdificios.indexOf(edificio);
                      final expandido = _expandidos[realIndex] ?? false;
                      final cedulaController = _cedulaControllers[realIndex];
                      final cedulaValida =
                          cedulaController != null &&
                          cedulaController.text.trim().isNotEmpty;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                      color: AppColors.gray300.withValues(
                                        alpha: 0.4,
                                      ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          edificio['nombre']!,
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
                                          edificio['fecha']!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Inspector: ${edificio['inspector']}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          edificio['direccion']!,
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
                              if (tieneAyudante) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Ayudante asignado",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (expandido) ...[
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
                                  decoration: InputDecoration(
                                    hintText: 'Ingrese el número de cédula',
                                    filled: true,
                                    fillColor: AppColors.gray300.withValues(
                                      alpha: 0.3,
                                    ),
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
                                        onPressed: cedulaValida
                                            ? () => _asignarAyudante(realIndex)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              AppColors.gray300,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "Asignar",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () =>
                                          _alternarExpandir(realIndex),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _alternarExpandir(realIndex),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Asignar ayudante",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
}
