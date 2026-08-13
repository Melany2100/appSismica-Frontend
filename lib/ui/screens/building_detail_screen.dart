import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/building_list_service.dart';
import '../../data/models/building_list_response.dart';
import 'building_pdf_service.dart';
import 'reporte_detalle_screen.dart';

class BuildingDetailScreen extends StatefulWidget {
  final BuildingData building;

  const BuildingDetailScreen({super.key, required this.building});

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _realReports = [];

  @override
  void initState() {
    super.initState();
    _loadRealReports();
  }

  // Extraemos la información real de la inspección
  void _loadRealReports() {
    if (widget.building.inspector != null && widget.building.fechaHora != 'Sin fecha') {
      _realReports.add({
        'codigo': 'INF-${DateTime.now().year}-${widget.building.idEdificio.toString().padLeft(3, '0')}',
        'fecha': widget.building.displayDate,
        'inspector': widget.building.displayInspector,
        'expanded': false,
      });
    }
  }

  Future<void> _deleteBuilding() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar edificio?'),
        content: Text('Estás a punto de eliminar "${widget.building.displayName}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final response = await BuildingListService.deleteBuilding(
        idEdificio: widget.building.idEdificio,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edificio eliminado correctamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Enviamos "true" para actualizar la pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.friendlyError), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        // Solo dejamos el botón de eliminar
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteBuilding,
            tooltip: 'Eliminar edificio',
          ),
        ],
      ),
      body: Column(
        children: [
          // AQUÍ SE DIBUJA EL ENCABEZADO DE LA FOTO Y EL NOMBRE
          _buildHeader(),
          const SizedBox(height: 16),
          _buildCustomTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildInformesSection()
                : _buildDatosTecnicosSection(),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN: ENCABEZADO (FOTO, NOMBRE, DIRECCIÓN) ---
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade200,
            borderRadius: BorderRadius.circular(32),
          ),
          child: widget.building.hasPhoto
              ? ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.network(
              widget.building.fotoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
            ),
          )
              : const Icon(Icons.landscape, color: Colors.black87, size: 64),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            widget.building.displayName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            widget.building.ciudad != null
                ? '${widget.building.displayAddress}, ${widget.building.ciudad}'
                : widget.building.displayAddress,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECCIÓN: PESTAÑAS (INFORMES / DATOS TÉCNICOS) ---
  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0 ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text('Informes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTabIndex == 0 ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1 ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text('Datos Técnicos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTabIndex == 1 ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN: INFORMES ---
  Widget _buildInformesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Buscar',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                suffixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
        Expanded(
          child: _realReports.isEmpty
              ? const Center(
              child: Text('Aún no hay informes para este edificio.', style: TextStyle(color: Colors.grey))
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            itemCount: _realReports.length,
            itemBuilder: (context, index) {
              final report = _realReports[index];
              return _buildReportCard(report, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: report['expanded'],
          onExpansionChanged: (expanded) {
            setState(() {
              _realReports[index]['expanded'] = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            report['codigo'],
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(report['fecha'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              Text(report['inspector'].toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          trailing: Icon(
            report['expanded'] ? Icons.keyboard_arrow_down : Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  _buildMockupButton(
                      Icons.description_outlined,
                      'Ver detalles del informe',
                          () async {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        );

                        try {
                          await BuildingPdfService.generateFullReport(widget.building.idEdificio);
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                  ),
                  const SizedBox(height: 8),
                  _buildMockupButton(
                      Icons.analytics_outlined,
                      'Ver resultados',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReporteDetalleScreen(
                              edificio: widget.building,
                              puntuacion: widget.building.puntuacionFinal ?? 0.0,
                            ),
                          ),
                        );
                      }
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMockupButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  // --- SECCIÓN: DATOS TÉCNICOS ---
  Widget _buildDatosTecnicosSection() {
    final b = widget.building;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      children: [
        _buildDataRow('Uso Principal', b.usoPrincipal ?? 'No especificado'),
        _buildDataRow('Ocupación', b.ocupacion ?? 'No especificada'),
        const Divider(height: 32),

        const Text('Estructura', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildDataRow('Número de pisos', b.numeroPisos?.toString() ?? 'N/A'),
        _buildDataRow('Área total por piso', b.areaTotalPiso != null ? '${b.areaTotalPiso} m²' : 'N/A'),
        _buildDataRow('Año de construcción', b.anioConstruccion?.toString() ?? 'N/A'),
        _buildDataRow('Unidades', b.unidades?.toString() ?? 'N/A'),
        const Divider(height: 32),

        const Text('Características', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildBooleanRow('Ampliación', b.ampliacion ?? false),
        if (b.ampliacion == true && b.anioAmpliacion != null)
          _buildDataRow('Año de ampliación', b.anioAmpliacion.toString()),
        _buildBooleanRow('Edificio Histórico', b.historico ?? false),
        _buildBooleanRow('Uso Gubernamental', b.gubernamental ?? false),
        _buildBooleanRow('Funciona como Albergue', b.albergue ?? false),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBooleanRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.grey.shade400,
            size: 18,
          ),
        ],
      ),
    );
  }
}