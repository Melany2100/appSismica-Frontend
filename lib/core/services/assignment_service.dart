import '../constants/database_endpoints.dart';
import '../../data/models/database_response.dart';
import 'database_service.dart';

class AssignmentService {
  static Future<DatabaseResponse<Map<String, dynamic>>> findHelperByCedula(
    String cedula,
  ) {
    final encodedCedula = Uri.encodeQueryComponent(cedula.trim());
    return DatabaseService.get<Map<String, dynamic>>(
      '${DatabaseEndpoints.assignments}/helper/search?cedula=$encodedCedula',
      requiresAuth: true,
    );
  }

  static Future<DatabaseResponse<Map<String, dynamic>>> createAssignment({
    required int inspectorId,
    required int helperId,
    required int buildingId,
  }) {
    return DatabaseService.post<Map<String, dynamic>>(
      DatabaseEndpoints.assignments,
      {
        'id_inspector': inspectorId,
        'id_ayudante': helperId,
        'id_edificio': buildingId,
      },
      requiresAuth: true,
    );
  }

  static Future<DatabaseResponse<List<dynamic>>> getAssignmentsByHelper(
    int helperId,
  ) {
    return DatabaseService.get<List<dynamic>>(
      '${DatabaseEndpoints.assignments}/helper/$helperId',
      requiresAuth: true,
    );
  }
}
