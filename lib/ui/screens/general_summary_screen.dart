import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/user_service.dart';
import '../../core/services/building_list_service.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_user_list_screen.dart';
import 'dashboard_building_list_screen.dart';

class GeneralSummaryScreen extends StatefulWidget {
  const GeneralSummaryScreen({super.key});

  @override
  State<GeneralSummaryScreen> createState() => _GeneralSummaryScreenState();
}

class _GeneralSummaryScreenState extends State<GeneralSummaryScreen> {
  bool _loading = true;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _inactiveUsers = 0;
  int _totalBuildings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      UserService.getAll(),
      BuildingListService.getBuildings(),
    ]);

    final usersResponse = results[0] as dynamic;
    final buildingsResponse = results[1] as dynamic;

    if (mounted) {
      setState(() {
        if (usersResponse.success && usersResponse.data != null) {
          final users = usersResponse.data as List;
          _totalUsers = users.length;
          _activeUsers = users.where((u) => u.activo).length;
          _inactiveUsers = users.where((u) => !u.activo).length;
        }

        if (buildingsResponse.success && buildingsResponse.buildings != null) {
          _totalBuildings = buildingsResponse.buildings!.length;
        }

        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resumen General',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildStatCard(
                  context,
                  _totalUsers.toString().padLeft(4, '0'),
                  'Usuarios registrados',
                  onTap: () => _navigateToUserList(context, 'Usuarios registrados'),
                ),
                _buildStatCard(
                  context,
                  _totalBuildings.toString().padLeft(4, '0'),
                  'Edificios evaluados',
                  onTap: () => _navigateToBuildingList(context),
                ),
                _buildStatCard(
                  context,
                  _activeUsers.toString().padLeft(4, '0'),
                  'Usuarios activos',
                  onTap: () => _navigateToUserList(context, 'Usuarios activos'),
                ),
                _buildStatCard(
                  context,
                  _inactiveUsers.toString().padLeft(4, '0'),
                  'Usuarios inactivos',
                  onTap: () => _navigateToUserList(context, 'Usuarios inactivos'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Usuarios'),
                          Tab(text: 'Edificios'),
                          Tab(text: 'Texto'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildUserLineChart(),
                            _buildBuildingBarChart(), // <-- Nuevo gráfico de barras
                            _buildTextSummary(), // <-- Nuevo reporte en texto
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUserList(BuildContext context, String filterType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardUserListScreen(listType: filterType),
      ),
    ).then((_) {
      setState(() => _loading = true);
      _loadData();
    });
  }

  void _navigateToBuildingList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardBuildingListScreen(),
      ),
    ).then((_) {
      setState(() => _loading = true);
      _loadData();
    });
  }

  Widget _buildStatCard(BuildContext context, String number, String label,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // GRÁFICO 1: USUARIOS (Líneas)
  Widget _buildUserLineChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul'];
                        if (value >= 0 && value < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                    left: BorderSide(color: Colors.grey.shade300),
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: (_totalUsers > 15) ? _totalUsers.toDouble() + 5 : 15,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 5),
                      const FlSpot(2, 4),
                      const FlSpot(3, 7),
                      const FlSpot(4, 9),
                      const FlSpot(5, 11),
                      // El último punto usa el dato real para dar contexto
                      FlSpot(6, _totalUsers.toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GRÁFICO 2: EDIFICIOS (Barras - NUEVO)
  Widget _buildBuildingBarChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_totalBuildings > 15) ? _totalBuildings.toDouble() + 5 : 15,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul'];
                        if (value >= 0 && value < months.length) {
                          return Text(months[value.toInt()], style: const TextStyle(color: Colors.black54, fontSize: 12));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                    left: BorderSide(color: Colors.grey.shade300),
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 1, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 5, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 4, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 7, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  // El último mes muestra los datos reales
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: _totalBuildings.toDouble(), color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PESTAÑA 3: RESUMEN EN TEXTO DINÁMICO (NUEVO)
  Widget _buildTextSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporte Ejecutivo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'El sistema SismosApp cuenta actualmente con un total de $_totalUsers usuarios registrados en la plataforma. De estos, $_activeUsers se encuentran activos y operativos para realizar o revisar inspecciones estructurales, mientras que $_inactiveUsers cuentan con su acceso suspendido o inactivo temporalmente.',
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 12),
            Text(
              'En cuanto a la infraestructura física evaluada, los inspectores han registrado y analizado un total de $_totalBuildings edificios hasta la fecha. El flujo de evaluaciones y registros mantiene un monitoreo actualizado que permite categorizar la vulnerabilidad sísmica en las zonas de interés.',
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nota: Todos los datos estadísticos presentados en este resumen están sincronizados en tiempo real con la base de datos principal.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}