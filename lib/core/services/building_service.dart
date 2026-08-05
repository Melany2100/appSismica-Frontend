// building_service.dart - VERSIÓN CORREGIDA PARA COMPATIBILIDAD CON SERVIDOR
import 'dart:io';
import '../config/database_config.dart';
import '../constants/database_endpoints.dart';
import 'database_service.dart';
import '../../data/models/building_response.dart';

class BuildingService {
  // CREATE BUILDING con archivos multimedia
  static Future<BuildingResponse> createBuilding({
    // Información básica del edificio
    required String nombreEdificio,
    required String direccion,
    required String ciudad,
    required String codigoPostal,
    required String usoPrincipal,
    required double latitud,
    required double longitud,

    // Información estructural
    required int numeroPisos,
    required double areaTotalPiso,
    required int anioConstruccion,
    required int anioCodigo,
    required bool ampliacion,
    int? anioAmpliacion, // Opcional - Solo si ampliacion es true
    required String ocupacion,

    // Características especiales
    required bool historico,
    required bool albergue,
    required bool gubernamental,
    required int unidades,

    // Campos opcionales
    String? otrasIdentificaciones,
    String? comentarios,

    // Archivos
    File? fotoEdificio,
    File? graficoEdificio,

    int maxRetries = 2,
  }) async {
    int attemptCount = 0;

    // ===== VALIDACIONES MEJORADAS =====
    final validationError = validateBuildingData(
      nombreEdificio: nombreEdificio,
      direccion: direccion,
      ciudad: ciudad,
      codigoPostal: codigoPostal,
      usoPrincipal: usoPrincipal,
      latitud: latitud,
      longitud: longitud,
      numeroPisos: numeroPisos,
      areaTotalPiso: areaTotalPiso,
      anioConstruccion: anioConstruccion,
      anioCodigo: anioCodigo,
      ampliacion: ampliacion,
      anioAmpliacion: anioAmpliacion,
      ocupacion: ocupacion,
      unidades: unidades,
    );

    if (validationError != null) {
      return BuildingResponse.failure(error: validationError);
    }

    // Validación específica de archivos
    String? fileValidationError = _validateFiles(fotoEdificio, graficoEdificio);
    if (fileValidationError != null) {
      return BuildingResponse.failure(error: fileValidationError);
    }

    while (attemptCount < maxRetries) {
      attemptCount++;

      try {
        print(
          'BuildingService: Intento $attemptCount/$maxRetries para crear edificio',
        );

        // ===== PREPARAR CAMPOS CON COMPATIBILIDAD DEL SERVIDOR =====
        final Map<String, String> fields = {
          // Campos de texto y números (funcionan correctamente)
          'nombre_edificio': nombreEdificio.trim(),
          'direccion': direccion.trim(),
          'ciudad': ciudad.trim(),
          'codigo_postal': codigoPostal.trim(),
          'uso_principal': usoPrincipal.trim(),
          'latitud': latitud.toStringAsFixed(6), // Más precisión
          'longitud': longitud.toStringAsFixed(6), // Más precisión
          'numero_pisos': numeroPisos.toString(),
          'area_total_piso': areaTotalPiso.toStringAsFixed(2), // Más precisión
          'anio_construccion': anioConstruccion.toString(),
          'anio_codigo': anioCodigo.toString(),
          'ocupacion': ocupacion.trim(),
          'unidades': unidades.toString(),

          // CORRECCIÓN CRÍTICA: El servidor espera "1" para true y "0" para false
          // Las transformaciones del servidor son: (v) => v === "1"
          'ampliacion': ampliacion ? '1' : '0',
          'historico': historico ? '1' : '0',
          'albergue': albergue ? '1' : '0',
          'gubernamental': gubernamental ? '1' : '0',
        };

        // Agregar campos opcionales con validaciones
        if (anioAmpliacion != null) {
          fields['anio_ampliacion'] = anioAmpliacion.toString();
        }
        if (otrasIdentificaciones != null &&
            otrasIdentificaciones.trim().isNotEmpty) {
          fields['otras_identificaciones'] = otrasIdentificaciones.trim();
        }
        if (comentarios != null && comentarios.trim().isNotEmpty) {
          fields['comentarios'] = comentarios.trim();
        }

        // Log para verificar compatibilidad con servidor (remover en producción)
        print('Campos enviados - verificación de booleanos:');
        print(
          '  - ampliacion: ${fields['ampliacion']} (bool original: $ampliacion)',
        );
        print(
          '  - historico: ${fields['historico']} (bool original: $historico)',
        );
        print('  - albergue: ${fields['albergue']} (bool original: $albergue)');
        print(
          '  - gubernamental: ${fields['gubernamental']} (bool original: $gubernamental)',
        );
        print('Total campos: ${fields.length}');

        // Crear request multipart
        final request = DatabaseService.buildMultipartRequest(
          'POST',
          Uri.parse(
            '${DatabaseConfig.getServerUrl()}${DatabaseEndpoints.buildings}',
          ),
        );

        // Agregar campos
        request.fields.addAll(fields);

        // ===== AGREGAR ARCHIVOS CON VALIDACIONES MEJORADAS =====
        if (fotoEdificio != null) {
          // Verificar que el archivo existe y es accesible
          if (!await fotoEdificio.exists()) {
            return BuildingResponse.failure(
              error:
                  'El archivo de foto del edificio no existe o no es accesible',
            );
          }

          request.files.add(
            await DatabaseService.createMultipartFile(
              fotoEdificio,
              'foto_edificio',
            ),
          );
          print('Archivo foto_edificio agregado: ${fotoEdificio.path}');
          print('Tamaño del archivo: ${await fotoEdificio.length()} bytes');
        }

        if (graficoEdificio != null) {
          // Verificar que el archivo existe y es accesible
          if (!await graficoEdificio.exists()) {
            return BuildingResponse.failure(
              error:
                  'El archivo de gráfico del edificio no existe o no es accesible',
            );
          }

          request.files.add(
            await DatabaseService.createMultipartFile(
              graficoEdificio,
              'grafico_edificio',
            ),
          );
          print('Archivo grafico_edificio agregado: ${graficoEdificio.path}');
          print('Tamaño del archivo: ${await graficoEdificio.length()} bytes');
        }

        // Enviar request
        final response = await DatabaseService.sendMultipartRequest(request);

        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
        print('Response error: ${response.error}');

        if (response.success && response.data != null) {
          final data = response.data!;

          // Extraer información del edificio creado
          final buildingId = data['id_edificio'] as int?;

          print('Datos extraídos de la creación:');
          print('  - buildingId: $buildingId');
          print('  - success: ${response.success}');

          if (buildingId != null) {
            print('Edificio creado exitosamente en intento $attemptCount');
            print('ID del edificio: $buildingId');

            return BuildingResponse.success(
              buildingId: buildingId,
              message: '¡Edificio registrado exitosamente!',
              buildingData: data,
              statusCode: response.statusCode,
            );
          } else {
            print('Datos incompletos en respuesta exitosa');
            return BuildingResponse.failure(
              error: 'Error en la respuesta del servidor - ID no recibido',
            );
          }
        } else {
          // ===== MANEJO MEJORADO DE ERRORES =====
          if (response.statusCode != null &&
              response.statusCode! >= 400 &&
              response.statusCode! < 500) {
            print('Error del cliente (${response.statusCode})');
            print('Datos de respuesta: ${response.data}');
            print('Error original: ${response.error}');

            String errorMessage = 'Error desconocido';

            // Extraer mensaje de error mejorado
            try {
              if (response.data != null) {
                final data = response.data;

                if (data is Map<String, dynamic>) {
                  // Buscar mensaje en diferentes estructuras posibles
                  if (data['error'] != null) {
                    final errorObj = data['error'];
                    if (errorObj is Map<String, dynamic> &&
                        errorObj['message'] != null) {
                      errorMessage =
                          errorObj['message']?.toString() ??
                          'Error desconocido';
                    } else if (errorObj is String) {
                      errorMessage = errorObj;
                    }
                  } else if (data['message'] != null) {
                    errorMessage =
                        data['message']?.toString() ?? 'Error desconocido';
                  } else if (data['detail'] != null) {
                    errorMessage =
                        data['detail']?.toString() ?? 'Error desconocido';
                  }
                } else if (data is String) {
                  final trimmedData = data!.trim();
                  if (trimmedData.isNotEmpty) {
                    errorMessage = trimmedData;
                  }
                }
              }

              if (errorMessage == 'Error desconocido' &&
                  response.error != null) {
                errorMessage = response.error!;
              }
            } catch (e) {
              print('Error parseando mensaje: $e');
              errorMessage =
                  response.error ?? 'Error de formato en la respuesta';
            }

            print('Mensaje de error extraído: $errorMessage');

            // ===== MENSAJES ESPECÍFICOS MEJORADOS =====
            switch (response.statusCode!) {
              case 400:
                if (errorMessage.isEmpty ||
                    errorMessage.contains('HTTP 400') ||
                    errorMessage == 'Error desconocido') {
                  errorMessage =
                      'Datos del edificio incorrectos o incompletos. Revise:\n'
                      '• Nombre del edificio (mínimo 3 caracteres)\n'
                      '• Todos los campos requeridos\n'
                      '• Formato de archivos (JPG/PNG)\n'
                      '• Valores numéricos válidos';
                }
                break;
              case 401:
                errorMessage = 'No autorizado. Inicie sesión nuevamente.';
                break;
              case 413:
                errorMessage =
                    'Los archivos son demasiado grandes (máximo 10MB cada uno)';
                break;
              case 415:
                errorMessage =
                    'Formato de archivo no válido. Use solo JPG o PNG.';
                break;
              case 422:
                if (errorMessage.isEmpty || errorMessage.contains('HTTP 422')) {
                  errorMessage =
                      'Error de validación en los datos:\n'
                      '• Verifique formatos de fecha y números\n'
                      '• Campos requeridos completos\n'
                      '• Rangos de valores válidos';
                }
                break;
              case 500:
                errorMessage =
                    'Error interno del servidor. Intente nuevamente.';
                break;
            }

            return BuildingResponse.failure(
              error: errorMessage,
              statusCode: response.statusCode,
            );
          }

          // Error de conexión, continuar con retry
          print('Intento $attemptCount falló: ${response.error}');
          if (attemptCount >= maxRetries) {
            return BuildingResponse.failure(
              error:
                  response.error ??
                  'Error de conexión después de $maxRetries intentos',
              statusCode: response.statusCode,
            );
          }
        }
      } catch (e) {
        print('Error en intento $attemptCount: $e');

        // Si es el último intento, devolver error
        if (attemptCount >= maxRetries) {
          return BuildingResponse.failure(
            error: 'Error de conexión después de $maxRetries intentos: $e',
          );
        }

        // Esperar antes del retry
        if (attemptCount < maxRetries) {
          print('Esperando 2 segundos antes del retry...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    // Fallback (no debería llegar aquí)
    return BuildingResponse.failure(
      error: 'Error inesperado al crear edificio',
    );
  }

  // ===== VALIDACIÓN DE ARCHIVOS =====
  static String? _validateFiles(File? fotoEdificio, File? graficoEdificio) {
    const int maxFileSize = 10 * 1024 * 1024; // 10MB
    const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png'];

    if (fotoEdificio != null) {
      final extension = fotoEdificio.path.toLowerCase().split('.').last;
      if (!allowedExtensions.contains('.$extension')) {
        return 'Formato de foto no válido. Use JPG o PNG.';
      }
    }

    if (graficoEdificio != null) {
      final extension = graficoEdificio.path.toLowerCase().split('.').last;
      if (!allowedExtensions.contains('.$extension')) {
        return 'Formato de gráfico no válido. Use JPG o PNG.';
      }
    }

    return null;
  }

  // ===== VALIDACIONES MEJORADAS =====
  static String? validateBuildingData({
    required String nombreEdificio,
    required String direccion,
    required String ciudad,
    required String codigoPostal,
    required String usoPrincipal,
    required double latitud,
    required double longitud,
    required int numeroPisos,
    required double areaTotalPiso,
    required int anioConstruccion,
    required int anioCodigo,
    required bool ampliacion,
    int? anioAmpliacion,
    required String ocupacion,
    required int unidades,
  }) {
    // ===== VALIDACIONES DE STRINGS =====
    if (nombreEdificio.trim().isEmpty)
      return 'El nombre del edificio es requerido';
    if (nombreEdificio.trim().length < 3)
      return 'El nombre del edificio debe tener al menos 3 caracteres';
    if (direccion.trim().isEmpty) return 'La dirección es requerida';
    if (ciudad.trim().isEmpty) return 'La ciudad es requerida';
    if (codigoPostal.trim().isEmpty) return 'El código postal es requerido';
    if (usoPrincipal.trim().isEmpty) return 'El uso principal es requerido';
    if (ocupacion.trim().isEmpty) return 'La ocupación es requerida';

    // ===== VALIDACIONES GEOGRÁFICAS =====
    if (latitud < -90 || latitud > 90)
      return 'Latitud inválida (debe estar entre -90 y 90)';
    if (longitud < -180 || longitud > 180)
      return 'Longitud inválida (debe estar entre -180 y 180)';

    // ===== VALIDACIONES NUMÉRICAS =====
    if (numeroPisos <= 0) return 'El número de pisos debe ser mayor a 0';
    if (numeroPisos > 200)
      return 'El número de pisos parece excesivo (máximo 200)';

    if (areaTotalPiso <= 0) return 'El área total por piso debe ser mayor a 0';
    if (areaTotalPiso > 100000)
      return 'El área por piso parece excesiva (máximo 100,000 m²)';

    if (unidades <= 0) return 'El número de unidades debe ser mayor a 0';
    if (unidades > 10000)
      return 'El número de unidades parece excesivo (máximo 10,000)';

    // ===== VALIDACIONES DE FECHAS =====
    final currentYear = DateTime.now().year;
    if (anioConstruccion < 1800 || anioConstruccion > currentYear) {
      return 'Año de construcción inválido (debe estar entre 1800 y $currentYear)';
    }
    if (anioCodigo < 1900 || anioCodigo > currentYear) {
      return 'Año del código inválido (debe estar entre 1900 y $currentYear)';
    }

    // ===== VALIDACIONES DE AMPLIACIÓN =====
    if (ampliacion) {
      if (anioAmpliacion == null) {
        return 'El año de ampliación es requerido cuando se indica que hay ampliación';
      }
      if (anioAmpliacion <= anioConstruccion) {
        return 'El año de ampliación debe ser posterior al año de construcción';
      }
      if (anioAmpliacion > currentYear) {
        return 'El año de ampliación no puede ser futuro';
      }
    }

    return null; // Todo válido
  }
}
