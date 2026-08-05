import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/database_config.dart';
import '../../data/models/database_response.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class DatabaseService {
  static String? _authToken;
  static Future<void> Function()? _onUnauthorized;

  // Usar la URL dinámica
  static String get _baseUrl => DatabaseConfig.getServerUrl();

  static void setAuthToken(String? token) {
    _authToken = token;
    print(
      'Token establecido: ${token != null ? "${token.substring(0, 20)}..." : "null"}',
    );
  }

  static void clearAuthToken() {
    _authToken = null;
    print('Token limpiado');
  }

  static void setUnauthorizedHandler(Future<void> Function()? handler) {
    _onUnauthorized = handler;
  }

  static Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // MÉTODO PARA VERIFICAR CONEXIÓN
  static Future<DatabaseResponse<Map<String, dynamic>>>
  checkConnection() async {
    try {
      print('Intentando conectar a: $_baseUrl/health');

      final response = await http
          .get(Uri.parse('$_baseUrl/health'), headers: _baseHeaders)
          .timeout(Duration(milliseconds: DatabaseConfig.connectionTimeout));

      print('Respuesta del servidor: ${response.statusCode}');
      print('Contenido: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DatabaseResponse.success({
          'connected': true,
          'message': 'Conexión exitosa con Android',
          'server': _baseUrl,
          'serverResponse': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return DatabaseResponse.error(
          'Servidor respondió con código ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      print('Error de red: $e');
      return DatabaseResponse.error(
        'Sin conexión de red. Verifica que el servidor esté corriendo.',
      );
    } on TimeoutException catch (e) {
      print('Timeout: $e');
      return DatabaseResponse.error(
        'Timeout: El servidor no responde en $_baseUrl',
      );
    } catch (e) {
      print('Error general: $e');
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // GET Request actualizado
  static Future<DatabaseResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      print('GET Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Auth required: $requiresAuth');
      print('  Has token: ${_authToken != null}');

      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: requiresAuth ? _authHeaders : _baseHeaders,
          )
          .timeout(Duration(milliseconds: DatabaseConfig.connectionTimeout));

      return _handleResponse<T>(response, 'GET', endpoint);
    } catch (e) {
      print('Error en GET request: $e');
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  static Future<DatabaseResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      print('DELETE Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Auth required: $requiresAuth');
      print('  Has token: ${_authToken != null}');

      final response = await http
          .delete(
            Uri.parse('$_baseUrl$endpoint'),
            headers: requiresAuth ? _authHeaders : _baseHeaders,
          )
          .timeout(Duration(milliseconds: DatabaseConfig.connectionTimeout));

      // CORRECCIÓN: Usar la misma firma que los otros métodos
      return _handleResponse<T>(response, 'DELETE', endpoint);
    } catch (e) {
      print('Error en DELETE request: $e');
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // POST Request actualizado
  static Future<DatabaseResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      print('POST Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Auth required: $requiresAuth');
      print('  Has token: ${_authToken != null}');
      print('  Data keys: ${data.keys.toList()}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: requiresAuth ? _authHeaders : _baseHeaders,
            body: json.encode(data),
          )
          .timeout(Duration(milliseconds: DatabaseConfig.connectionTimeout));

      return _handleResponse<T>(response, 'POST', endpoint);
    } catch (e) {
      print('Error en POST request: $e');
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // POST con archivo actualizado
  static Future<DatabaseResponse<T>> postWithFile<T>(
    String endpoint,
    Map<String, String> fields,
    File? file,
    String fileFieldName, {
    bool requiresAuth = false,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$endpoint'),
      );

      if (requiresAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.fields.addAll(fields);

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileFieldName, file.path),
        );
      }

      print('Multipart POST Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Fields: ${request.fields.keys.toList()}');
      print('  Files: ${request.files.length}');

      final streamedResponse = await request.send().timeout(
        Duration(milliseconds: DatabaseConfig.connectionTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, 'POST (Multipart)', endpoint);
    } catch (e) {
      print('Error en POST multipart: $e');
      return DatabaseResponse.error('Error al subir archivo: $e');
    }
  }

  static Future<DatabaseResponse<T>> postMultipart<T>(
    String endpoint,
    Map<String, String> fields, { // Solo strings para multipart
    File? file,
    String? fileFieldName,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Agregar headers si tienes token
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Agregar campos
      request.fields.addAll(fields);

      // Agregar archivo si existe
      if (file != null && fileFieldName != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileFieldName, file.path),
        );
      }

      print('Multipart Request:');
      print('  URL: $uri');
      print('  Fields: ${request.fields.keys.toList()}');
      print('  Files: ${request.files.length}');
      print('  Has auth: ${_authToken != null}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, 'POST (Multipart)', endpoint);
    } catch (e) {
      print('Error en postMultipart: $e');
      return DatabaseResponse.failure(error: 'Error de conexión: $e');
    }
  }

  // Manejo centralizado de respuestas MEJORADO
  static DatabaseResponse<T> _handleResponse<T>(
    http.Response response,
    String method,
    String endpoint,
  ) {
    final statusCode = response.statusCode;

    if (statusCode == 401 && _authToken != null && endpoint != '/auth/login') {
      final handler = _onUnauthorized;
      if (handler != null) {
        unawaited(handler());
      }
    }

    // LOGS MÁS INFORMATIVOS
    print('HTTP Response ($method $endpoint):');
    print('  Status: $statusCode');
    print('  Headers: ${response.headers}');

    // Solo mostrar primeros 500 caracteres para evitar spam en logs
    final bodyPreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}...'
        : response.body;
    print('  Body preview: $bodyPreview');

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final data = json.decode(response.body);
        print('  JSON parseado correctamente');
        return DatabaseResponse.success(data, statusCode: statusCode);
      } catch (e) {
        print('  Respuesta no es JSON, retornando como String: $e');
        return DatabaseResponse.success(
          response.body as T,
          statusCode: statusCode,
        );
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        String errorMessage = 'Error del servidor';

        // EXTRACCIÓN MEJORADA DE ERRORES
        if (errorData is Map<String, dynamic>) {
          if (errorData['error'] != null) {
            if (errorData['error'] is Map &&
                errorData['error']['message'] != null) {
              errorMessage = errorData['error']['message'];
            } else if (errorData['error'] is String) {
              errorMessage = errorData['error'];
            }
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        }

        print('  Error extraído: $errorMessage');
        return DatabaseResponse.error(errorMessage, statusCode);
      } catch (e) {
        print('  Error sin estructura JSON: ${response.body}');
        return DatabaseResponse.error(
          'Error HTTP $statusCode: ${response.body}',
          statusCode,
        );
      }
    }
  }

  // PUT Request
  static Future<DatabaseResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      print('PUT Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Auth required: $requiresAuth');
      print('  Data keys: ${data.keys.toList()}');

      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: requiresAuth ? _authHeaders : _baseHeaders,
            body: json.encode(data),
          )
          .timeout(Duration(milliseconds: DatabaseConfig.connectionTimeout));

      return _handleResponse<T>(response, 'PUT', endpoint);
    } catch (e) {
      print('Error en PUT request: $e');
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // PATCH Request
  static Future<DatabaseResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      print('PATCH Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Auth required: $requiresAuth');
      print('  Data keys: ${data.keys.toList()}');

      final response = await http
          .patch(
            Uri.parse('$_baseUrl$endpoint'),
            headers: requiresAuth ? _authHeaders : _baseHeaders,
            body: json.encode(data),
          )
          .timeout(Duration(milliseconds: DatabaseConfig.connectionTimeout));

      return _handleResponse<T>(response, 'PATCH', endpoint);
    } catch (e) {
      print('Error en PATCH request: $e');
      return DatabaseResponse.error('Error de conexión: $e');
    }
  }

  // PUT con archivo
  static Future<DatabaseResponse<T>> putWithFile<T>(
    String endpoint,
    Map<String, String> fields,
    File? file,
    String fileFieldName, {
    bool requiresAuth = false,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl$endpoint'),
      );

      if (requiresAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.fields.addAll(fields);

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileFieldName, file.path),
        );
      }

      print('Multipart PUT Request:');
      print('  URL: $_baseUrl$endpoint');
      print('  Fields: ${request.fields.keys.toList()}');
      print('  Files: ${request.files.length}');

      final streamedResponse = await request.send().timeout(
        Duration(milliseconds: DatabaseConfig.connectionTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, 'PUT (Multipart)', endpoint);
    } catch (e) {
      print('Error en PUT multipart: $e');
      return DatabaseResponse.error('Error al actualizar con archivo: $e');
    }
  }

  // MÉTODO DE UTILIDAD PARA VERIFICAR DISPONIBILIDAD DE ENDPOINTS
  static Future<bool> isEndpointAvailable(String endpoint) async {
    try {
      final response = await http
          .head(Uri.parse('$_baseUrl$endpoint'), headers: _authHeaders)
          .timeout(Duration(seconds: 5));

      // 200-299 = disponible, 404 = no disponible, otros = error pero disponible
      return response.statusCode != 404;
    } catch (e) {
      print('Error verificando endpoint $endpoint: $e');
      return false;
    }
  }

  // GETTERS DE UTILIDAD
  static bool hasAuthToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  static String? getAuthToken() {
    return _authToken;
  }

  static String get baseUrl => _baseUrl;

  // MÉTODOS DE CONSTRUCCIÓN DE MULTIPART (de la segunda versión)
  static http.MultipartRequest buildMultipartRequest(String method, Uri uri) {
    final request = http.MultipartRequest(method, uri);
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    return request;
  }

  static Future<http.MultipartFile> createMultipartFile(
    File file,
    String fieldName,
  ) async {
    // Detectar el tipo MIME
    String mimeType;
    final extension = file.path.toLowerCase();

    if (extension.endsWith('.jpg') || extension.endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (extension.endsWith('.png')) {
      mimeType = 'image/png';
    } else {
      mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    }

    // Crear MediaType de forma más compatible
    MediaType contentType;
    if (mimeType == 'image/jpeg') {
      contentType = MediaType('image', 'jpeg');
    } else if (mimeType == 'image/png') {
      contentType = MediaType('image', 'png');
    } else {
      contentType = MediaType('image', 'jpeg'); // Default
    }

    print('createMultipartFile:');
    print('  Field: $fieldName');
    print('  File: ${file.path}');
    print('  ContentType: $contentType');

    return await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: contentType,
    );
  }

  static Future<DatabaseResponse<Map<String, dynamic>>> sendMultipartRequest(
    http.MultipartRequest request,
  ) async {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse<Map<String, dynamic>>(
      response,
      request.method,
      request.url.path,
    );
  }

  // MÉTODO DE DEBUG PARA VERIFICAR CONFIGURACIÓN
  static Map<String, dynamic> getDebugInfo() {
    return {
      'baseUrl': _baseUrl,
      'hasToken': hasAuthToken(),
      'tokenPreview': _authToken != null
          ? '${_authToken!.substring(0, 20)}...'
          : null,
      'connectionTimeout': DatabaseConfig.connectionTimeout,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
