import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/building_list_service.dart';
import '../../data/models/building_list_response.dart';
import 'building_detail_screen.dart';

class DashboardBuildingListScreen extends StatefulWidget {
  const DashboardBuildingListScreen({super.key});

  @override
  State<DashboardBuildingListScreen> createState() =>
      _DashboardBuildingListScreenState();
}

class _DashboardBuildingListScreenState extends State<DashboardBuildingListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<BuildingData> _buildings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadBuildings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    final response = await BuildingListService.getBuildings();
    if (mounted) {
      if (response.success && response.buildings != null) {
        setState(() {
          _buildings = response.buildings!;
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = response.friendlyError;
        });
      }
    }
  }

  // Filtrado de búsqueda
  List<BuildingData> get _visibleBuildings {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _buildings;

    return _buildings.where((b) {
      final matchesName = b.displayName.toLowerCase().contains(query);
      final matchesLocation = b.displayAddress.toLowerCase().contains(query);
      return matchesName || matchesLocation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleBuildings = _visibleBuildings;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edificios Evaluados',
            style: TextStyle(
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
            // BARRA DE BÚSQUEDA (El botón de filtros fue eliminado)
            Container(
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    hintText: 'Buscar edificio...',
                    hintStyle: TextStyle(color: Colors.grey),
                    suffixIcon: Icon(Icons.search, color: Colors.grey, size: 22),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                  ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          setState(() => _loading = true);
                          _loadBuildings();
                        },
                        child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ))
                  : visibleBuildings.isEmpty
                  ? const Center(
                  child: Text('No hay edificios para mostrar.',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: visibleBuildings.length,
                itemBuilder: (context, index) =>
                    _buildBuildingCard(visibleBuildings[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingCard(BuildingData building) {
    final locationText = building.ciudad != null
        ? '${building.displayAddress}, ${building.ciudad}'
        : building.displayAddress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingDetailScreen(building: building),
              ),
            ).then((_) {
              setState(() => _loading = true);
              _loadBuildings();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: building.hasPhoto
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      building.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, color: Colors.black54),
                    ),
                  )
                      : const Icon(
                    Icons.image,
                    color: Colors.black54,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.displayName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationText,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Inspector: ${building.displayInspector}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}