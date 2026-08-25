import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/screens/add_helper_screen.dart';
import 'package:flutter_application_1/ui/screens/building_registry_1_screen.dart';
import 'package:flutter_application_1/ui/screens/home_admin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/database_service.dart';
import 'core/services/session_service.dart';
import '../../ui/screens/assessed_buildings_screen.dart';
import '../../ui/screens/building_registry_2_screen.dart';
import '../../ui/screens/building_registry_3_screen.dart';
import '../../ui/screens/building_registry_4_screen.dart';
import '../../ui/screens/buildings_screen.dart';
import '../../ui/screens/exten_revis.dart';
import '../../ui/screens/forgot_password_screen.dart';
import '../../ui/screens/home_page.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/profile_admin_screen.dart';
import '../../ui/screens/profile_page.dart';
import '../../ui/screens/recovery_password.dart';
import '../../ui/screens/register_screen.dart';
import '../../ui/screens/user_list_screen.dart';
import '../../ui/screens/asignaciones_ayudante_screen.dart';
import 'ui/widgets/route_guards.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzamJlanhycXVtcXBxZnB2cG1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNjU5OTQsImV4cCI6MjA5NTg0MTk5NH0.j97oHACM1K6bM0QL_5fTEyNOX4CzgZqhyHglLxk9ekE",
    url: "https://gsjbejxrqumqpqfpvpmp.supabase.co",
  );
  DatabaseService.setUnauthorizedHandler(() async {
    await SessionService.clear();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'SismosApp',
      debugShowCheckedModeBanner: false,
      //theme: AppTheme.light(),
      initialRoute: '/', // 👈 Pantalla inicial
      routes: {
        '/': (_) => const SessionGate(),
        '/login': (_) => const LoginScreen(),
        '/addHelper': (_) => const AuthGuard(child: AddHelperScreen()),
        '/assessed': (_) => const AuthGuard(child: AssessedBuildingsPage()),
        //'/roles/assign': (_) => const AssignRoleScreen(),
        '/buildingRegistry1': (_) =>
            const AuthGuard(child: BuildingRegistry1Screen()),
        '/buildingRegistry2': (_) =>
            const AuthGuard(child: BuildingRegistry2Screen()),
        '/buildingRegistry3': (_) =>
            const AuthGuard(child: BuildingRegistry3Screen()),
        '/buildingRegistry4': (_) =>
            const AuthGuard(child: BuildingRegistry4Screen()),
        '/building': (_) => const AuthGuard(child: BuildingsScreen()),
        '/exten': (_) => const AuthGuard(
          child: ExtensionRevisionPage(
            idEdificio: 0,
            nombreEdificio: '',
            direccion: '',
            anioConstruccion: '',
            tipoSuelo: 'D',
            numeroPisos: 0,
            ciudad: '', // 👈 Agregado
          ),
        ),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/home_admin': (context) => const AdminGuard(child: HomeAdminScreen()),
        '/homeAdmin': (context) => const AdminGuard(child: HomeAdminScreen()),
        '/home': (context) => const AuthGuard(child: HomePage()),
        '/profileAdmin': (_) => const AdminGuard(child: ProfileAdminScreen()),
        '/profile': (_) => const AuthGuard(child: ProfilePage()),
        '/register': (context) => const RegisterScreen(),
        '/asignaciones': (context) => const AsignacionesAyudanteScreen(),
        '/recovery': (context) => const RecoveryPasswordScreen(),
        '/userList': (context) => const AdminGuard(child: UserListScreen()),
        '/administracion/usuarios': (context) =>
            const AdminGuard(child: UserListScreen()),
      },
    );
  }
}
