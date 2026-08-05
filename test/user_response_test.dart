import 'package:flutter_application_1/data/models/user_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea el contrato completo de /users/all', () {
    final user = UserData.fromJson({
      'id_usuario': 8,
      'nombre': 'María Pérez',
      'email': 'maria@ejemplo.com',
      'cedula': '0987654321',
      'telefono': '0999999999',
      'rol': 'ayudante',
      'direccion': 'Quito',
      'foto_perfil_url': null,
      'activo': false,
    });

    expect(user.idUsuario, 8);
    expect(user.rol, 'ayudante');
    expect(user.activo, isFalse);
    expect(user.toJson()['activo'], isFalse);
  });

  test('considera activo al usuario cuando el endpoint omite el estado', () {
    final user = UserData.fromJson({
      'id_usuario': 2,
      'nombre': 'Carlos León',
      'email': 'carlos@ejemplo.com',
      'rol': 'inspector',
    });

    expect(user.activo, isTrue);
    expect(user.copyWith(activo: false).activo, isFalse);
  });
}
