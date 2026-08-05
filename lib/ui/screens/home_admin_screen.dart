import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/home_services.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/home_response.dart';
import 'buildings_screen.dart';
import 'assessed_buildings_screen.dart';
import 'profile_admin_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  // State variables
  String _userName = 'Usuario';
  String? _userId;
  String? _token;
  String? _userRole;
  bool _loading = true;
  String? _errorMessage;
  HomeStatistics? _statistics;
  UserInfo? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? 'Administrador';
        _userId = prefs.getString('userId');
        _token = prefs.getString('accessToken');
        _userRole = prefs.getString('userRole') ?? 'admin';
        _errorMessage = null;
      });

      // DETECTAR SI ES ADMIN RECIÉN REGISTRADO
      final isFromRegistration = prefs.getBool('isFromRegistration') ?? false;
      final isFirstLogin = prefs.getBool('isFirstLogin') ?? false;
      final registrationSource = prefs.getString('registrationSource');

      debugPrint('HOME ADMIN - Análisis de origen:');
      debugPrint('  - userName: $_userName');
      debugPrint('  - userId: $_userId');
      debugPrint('  - userRole: $_userRole');
      debugPrint('  - isFromRegistration: $isFromRegistration');
      debugPrint('  - isFirstLogin: $isFirstLogin');
      debugPrint('  - registrationSource: $registrationSource');

      // Verificar permisos de administrador
      if (_userRole != 'admin') {
        _handleUnauthorizedAccess(
          'Acceso denegado: Se requieren permisos de administrador',
        );
        return;
      }

      // Verificaciones básicas
      if (_token == null || !AuthService.isLoggedIn()) {
        _handleInvalidSession('Token no válido o sesión expirada');
        return;
      }

      if (_userId == null) {
        _handleInvalidSession('ID de usuario no encontrado');
        return;
      }

      // FLUJO ESPECÍFICO PARA ADMIN
      if (isFromRegistration) {
        debugPrint('🆕 ADMIN RECIÉN REGISTRADO DETECTADO');
        await _loadAdminDataFromRegistrationWithFallback();
        await prefs.setBool('isFromRegistration', false);
        await prefs.setBool('isFirstLogin', false);
      } else if (isFirstLogin) {
        debugPrint(
          'DETECTADO: Admin viene de registro, aplicando estrategia especial...',
        );
        await _loadAdminDataFromServerWithRegistrationFallback();
        await prefs.setBool('isFirstLogin', false);
      } else {
        debugPrint('Admin login normal, usando flujo estándar...');
        await _loadAdminDataFromServer();
      }
    } catch (e) {
      debugPrint('Error en _loadUserData: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error cargando datos locales: $e';
      });
    }
  }

  // NUEVO MÉTODO para admin recién registrado
  Future<void> _loadAdminDataFromRegistrationWithFallback() async {
    try {
      debugPrint('ADMIN RECIÉN REGISTRADO - Configurando panel...');

      final prefs = await SharedPreferences.getInstance();

      // VERIFICAR QUE REALMENTE ES ADMIN
      final localRole = prefs.getString('userRole')?.toLowerCase() ?? '';
      if (localRole != 'admin') {
        _handleUnauthorizedAccess('El usuario registrado no es administrador');
        return;
      }

      // DATOS DEL REGISTRO DE ADMIN
      final registrationEmail = prefs.getString('userEmail') ?? '';
      final registrationPhone = prefs.getString('userPhone') ?? '';
      final registrationCedula = prefs.getString('userCedula') ?? '';

      debugPrint('ADMIN RECIÉN REGISTRADO - Datos del registro:');
      debugPrint('  - Email: $registrationEmail');
      debugPrint('  - Teléfono: $registrationPhone');
      debugPrint('  - Cédula: $registrationCedula');

      // INTENTAR SERVIDOR PRIMERO (opcional para admin recién registrado)
      bool serverDataLoaded = false;
      try {
        final response = await HomeService.getUserDataWithStats(
          token: _token!,
          userId: _userId!,
          maxRetries: 1,
          timeout: const Duration(seconds: 8),
        );

        if (response.success && response.data != null) {
          final userData = response.data!;

          if (userData.userInfo.rol.toLowerCase() != 'admin') {
            _handleUnauthorizedAccess(
              'El usuario no tiene permisos de administrador',
            );
            return;
          }

          setState(() {
            if (userData.userInfo.nombre.isNotEmpty) {
              _userName = userData.userInfo.nombre;
            }
            _userInfo = userData.userInfo;
            _statistics = userData.statistics;
            _loading = false;
            _errorMessage = null;
          });

          await _updateSharedPreferences(userData.userInfo);
          serverDataLoaded = true;
          debugPrint('ADMIN RECIÉN REGISTRADO - Datos del servidor aplicados');
        }
      } catch (e) {
        debugPrint('ADMIN RECIÉN REGISTRADO - Servidor no disponible: $e');
      }

      // FALLBACK CON DATOS LOCALES DEL REGISTRO
      if (!serverDataLoaded) {
        // CREAR UserInfo DE ADMIN CON DATOS DEL REGISTRO
        final localUserInfo = UserInfo(
          idUsuario: int.tryParse(_userId ?? '0') ?? 0,
          nombre: _userName,
          email: registrationEmail,
          rol: 'admin',
        );

        // ESTADÍSTICAS VACÍAS PARA ADMIN RECIÉN REGISTRADO
        final emptyStatistics = HomeStatistics(
          totalEdificios: 0,
          edificiosEvaluados: 0,
          edificiosPendientes: 0,
          inspeccionesRealizadas: 0,
        );

        setState(() {
          _userInfo = localUserInfo;
          _statistics = emptyStatistics;
          _loading = false;
          _errorMessage = null;
        });

        debugPrint(
          'ADMIN RECIÉN REGISTRADO - Datos locales aplicados exitosamente',
        );

        // MENSAJE ESPECIAL PARA ADMIN RECIÉN REGISTRADO
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('¡Panel de administrador configurado para $_userName!'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ADMIN RECIÉN REGISTRADO - Error: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error configurando panel de administrador: $e';
      });
    }
  }

  Future<void> _loadAdminDataFromServer() async {
    if (_token == null || _userId == null) {
      _handleInvalidSession('Faltan credenciales de autenticación');
      return;
    }

    try {
      debugPrint('Cargando datos de administrador del servidor...');

      // Usar HomeService para obtener datos completos del usuario admin
      final response = await HomeService.getUserDataWithStats(
        token: _token!,
        userId: _userId!,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('Respuesta del servidor para admin: ${response.success}');

      if (response.success && response.data != null) {
        final userData = response.data!;

        // Verificar que el usuario realmente es admin
        if (userData.userInfo.rol.toLowerCase() != 'admin') {
          _handleUnauthorizedAccess(
            'El usuario no tiene permisos de administrador',
          );
          return;
        }

        setState(() {
          // Actualizar información del usuario
          if (userData.userInfo.nombre.isNotEmpty) {
            _userName = userData.userInfo.nombre;
          }

          _userInfo = userData.userInfo;
          _statistics = userData.statistics;
          _loading = false;
          _errorMessage = null;
        });

        // Actualizar SharedPreferences con los nuevos datos
        await _updateSharedPreferences(userData.userInfo);

        debugPrint('Datos de administrador cargados exitosamente');
        debugPrint('  - Usuario: $_userName');
        debugPrint('  - Rol confirmado: ${_userInfo?.rol}');
      } else {
        debugPrint(
          'Error en respuesta del servidor: ${response.error ?? response.message}',
        );

        // Si es un error 401 o 403, verificar permisos
        if (response.error?.contains('401') == true ||
            response.error?.contains('403') == true) {
          _handleUnauthorizedAccess('Acceso denegado: Permisos insuficientes');
          return;
        }

        if (response.error?.contains('404') == true) {
          _handleInvalidSession(
            'Sesión expirada. Por favor, inicie sesión nuevamente',
          );
          return;
        }

        setState(() {
          _loading = false;
          _errorMessage = response.error ?? response.message;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del servidor: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  // NUEVO MÉTODO - Fallback para Post-Registro de Admin
  Future<void> _loadAdminDataFromServerWithRegistrationFallback() async {
    if (_token == null || _userId == null) {
      _handleInvalidSession('Faltan credenciales de autenticación');
      return;
    }

    try {
      debugPrint('REGISTRO ADMIN - Intentando cargar datos del servidor...');

      // PRIMER INTENTO: HomeService normal
      final response = await HomeService.getUserDataWithStats(
        token: _token!,
        userId: _userId!,
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );

      debugPrint('REGISTRO ADMIN - Respuesta HomeService: ${response.success}');

      if (response.success && response.data != null) {
        // ÉXITO CON HOMESERVICE
        final userData = response.data!;

        // Verificar permisos de admin
        if (userData.userInfo.rol.toLowerCase() != 'admin') {
          _handleUnauthorizedAccess(
            'El usuario registrado no tiene permisos de administrador',
          );
          return;
        }

        setState(() {
          if (userData.userInfo.nombre.isNotEmpty) {
            _userName = userData.userInfo.nombre;
          }
          _userInfo = userData.userInfo;
          _statistics = userData.statistics;
          _loading = false;
          _errorMessage = null;
        });

        await _updateSharedPreferences(userData.userInfo);
        debugPrint('REGISTRO ADMIN - Datos del servidor cargados exitosamente');
      } else {
        // FALLÓ HOMESERVICE - USAR FALLBACK CON DATOS LOCALES
        debugPrint(
          'REGISTRO ADMIN - HomeService falló, usando fallback con datos locales',
        );
        await _loadAdminDataWithLocalFallback();
      }
    } catch (e) {
      debugPrint('REGISTRO ADMIN - Error cargando del servidor: $e');
      // FALLBACK CON DATOS LOCALES
      await _loadAdminDataWithLocalFallback();
    }
  }

  // NUEVO MÉTODO - Fallback con Datos Locales para Admin
  Future<void> _loadAdminDataWithLocalFallback() async {
    try {
      debugPrint('REGISTRO ADMIN - Aplicando fallback con datos locales...');

      final prefs = await SharedPreferences.getInstance();

      // VERIFICAR QUE REALMENTE ES ADMIN
      final localRole = prefs.getString('userRole')?.toLowerCase() ?? '';
      if (localRole != 'admin') {
        _handleUnauthorizedAccess('El usuario registrado no es administrador');
        return;
      }

      // CREAR UserInfo CON DATOS LOCALES DE ADMIN
      final localUserInfo = UserInfo(
        idUsuario: int.tryParse(_userId ?? '0') ?? 0,
        nombre: _userName,
        email: prefs.getString('userEmail') ?? '',
        rol: 'admin',
      );

      // CREAR ESTADÍSTICAS VACÍAS PARA ADMIN
      final emptyStatistics = HomeStatistics(
        totalEdificios: 0,
        edificiosEvaluados: 0,
        edificiosPendientes: 0,
        inspeccionesRealizadas: 0,
      );

      setState(() {
        _userInfo = localUserInfo;
        _statistics = emptyStatistics;
        _loading = false;
        _errorMessage = null;
      });

      debugPrint('REGISTRO ADMIN - Fallback aplicado exitosamente');
      debugPrint('  - Nombre: ${localUserInfo.nombre}');
      debugPrint('  - Email: ${localUserInfo.email}');
      debugPrint('  - Rol: ${localUserInfo.rol}');

      // MOSTRAR MENSAJE ESPECIAL PARA ADMIN
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Bienvenido Administrador! Panel configurado correctamente.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('REGISTRO ADMIN - Error en fallback local: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Error configurando panel de administrador: $e';
      });
    }
  }

  void _handleUnauthorizedAccess(String message) {
    debugPrint('Acceso no autorizado: $message');
    setState(() {
      _loading = false;
      _errorMessage = message;
    });

    // Mostrar mensaje de error y redirigir
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }

  void _handleInvalidSession(String message) {
    debugPrint('Sesión inválida: $message');
    setState(() {
      _loading = false;
      _errorMessage = message;
    });

    // Limpiar datos y redirigir al login
    Future.delayed(const Duration(seconds: 2), () {
      _logout(showMessage: false);
    });
  }

  Future<void> _updateSharedPreferences(UserInfo userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (userInfo.nombre.isNotEmpty) {
        await prefs.setString('userName', userInfo.nombre);
      }

      // Asegurar que el rol de admin esté guardado
      await prefs.setString('userRole', 'admin');

      setState(() {
        _userRole = 'admin';
      });

      debugPrint('SharedPreferences actualizado para admin');
    } catch (e) {
      debugPrint('Error actualizando SharedPreferences: $e');
    }
  }

  Future<void> _logout({bool showMessage = true}) async {
    try {
      AuthService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión de administrador cerrada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      debugPrint('Error durante logout: $e');
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    await _loadAdminDataFromServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SismosApp - Panel Admin'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión de administrador'),
          content: const Text(
            '¿Está seguro que desea cerrar la sesión de administrador?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Cargando panel de administración...',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _errorMessage!.contains('Acceso denegado') ||
                            _errorMessage!.contains('permisos')
                        ? Icons.admin_panel_settings
                        : _errorMessage!.contains('sesión') ||
                              _errorMessage!.contains('token')
                        ? Icons.lock_outline
                        : Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!.contains('Acceso denegado')
                        ? 'Acceso Restringido'
                        : _errorMessage!.contains('sesión') ||
                              _errorMessage!.contains('token')
                        ? 'Sesión Expirada'
                        : 'Error del Sistema',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_errorMessage!.contains('Acceso denegado') &&
                      !_errorMessage!.contains('sesión') &&
                      !_errorMessage!.contains('token'))
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminWelcomeSection(),

            if (_userInfo != null) ...[
              const SizedBox(height: 16),
              _buildAdminInfoCard(),
            ],

            if (_statistics != null) ...[
              const SizedBox(height: 24),
              _buildStatisticsSection(),
            ],

            const SizedBox(height: 32),
            _buildAdminMenuOptions(),
          ],
        ),
      ),
    );
  }

  // SECCIÓN DE BIENVENIDA MEJORADA PARA ADMIN
  Widget _buildAdminWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido admin, $_userName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const Text(
                      'Panel de Administración',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // MOSTRAR EMAIL DEL ADMIN SI ESTÁ DISPONIBLE
          if (_userInfo != null && _userInfo!.email.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin: ${_userInfo!.email}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Text(
            'Desde aquí puede gestionar edificios, usuarios e inspecciones.',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminInfoCard() {
    return Container(
      width: double.infinity,
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
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Información del Administrador',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_userInfo!.email.isNotEmpty)
            _buildInfoRow(Icons.email, 'Email', _userInfo!.email),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.badge,
            'ID Administrador',
            _userInfo!.idUsuario.toString(),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.verified_user,
            'Permisos',
            'Administrador del sistema',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    if (_statistics == null || _isStatisticsEmpty()) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.gray500,
              ),
              SizedBox(height: 8),
              Text(
                'Estadísticas no disponibles',
                style: TextStyle(fontSize: 16, color: AppColors.gray500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatisticsGrid(),
      ],
    );
  }

  bool _isStatisticsEmpty() {
    return _statistics!.totalEdificios == 0 &&
        _statistics!.edificiosEvaluados == 0 &&
        _statistics!.edificiosPendientes == 0 &&
        _statistics!.inspeccionesRealizadas == 0;
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Edificios',
                _statistics!.totalEdificios.toString(),
                Icons.apartment,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Evaluados',
                _statistics!.edificiosEvaluados.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pendientes',
                _statistics!.edificiosPendientes.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Inspecciones',
                _statistics!.inspeccionesRealizadas.toString(),
                Icons.assignment,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Panel de Control',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAdminMenuOption(
              context,
              'Gestión de Edificios',
              'https://cdn-icons-png.flaticon.com/512/1441/1441359.png',
              Icons.apartment,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuildingsScreen(),
                  ),
                );
              },
            ),
            _buildAdminMenuOption(
              context,
              'Edificios Evaluados',
              'https://cdn-icons-png.flaticon.com/128/12218/12218407.png',
              Icons.assignment_turned_in,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssessedBuildingsPage(),
                  ),
                );
              },
            ),
            _buildAdminMenuOption(
              context,
              'Usuarios',
              '',
              Icons.manage_accounts,
              () => Navigator.pushNamed(context, '/administracion/usuarios'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.red.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {},
            color: Colors.red,
            tooltip: 'Inicio Admin',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: (_userId != null && _token != null)
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileAdminScreen(userId: _userId, token: _token),
                      ),
                    );
                  }
                : null,
            color: (_userId != null && _token != null)
                ? AppColors.text
                : AppColors.gray500,
            tooltip: 'Perfil Admin',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuOption(
    BuildContext context,
    String title,
    String imageUrl,
    IconData fallbackIcon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 8),
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
            border: Border.all(color: Colors.red.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl.isEmpty)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(fallbackIcon, size: 30, color: Colors.red),
                )
              else
                Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(fallbackIcon, size: 30, color: Colors.red),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
