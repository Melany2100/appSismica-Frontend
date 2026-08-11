import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_user_list_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final response = await UserService.getAll();
    if (mounted && response.success && response.data != null) {
      final users = response.data!;
      setState(() {
        _totalUsers = users.length;
        _activeUsers = users.where((u) => u.activo).length;
        _inactiveUsers = users.where((u) => !u.activo).length;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
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
          ? const Center(child: CircularProgressIndicator())
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
                  '0000',
                  'Edificios evaluados',
                  onTap: null,
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
                            _buildLineChart(),
                            _buildChartPlaceholder(),
                            const Center(
                                child: Text('Contenido de Texto',
                                    style: TextStyle(color: Colors.grey))),
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
    );
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

  Widget _buildLineChart() {
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
                maxY: 15,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 5),
                      FlSpot(2, 4),
                      FlSpot(3, 7),
                      FlSpot(4, 9),
                      FlSpot(5, 8),
                      FlSpot(6, 12),
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

  Widget _buildChartPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text('Gráfico(líneas, barras...)',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Ene', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Feb', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Mar', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Abr', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('May', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Jun', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Jul', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}