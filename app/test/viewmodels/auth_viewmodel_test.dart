import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/viewmodels/auth_viewmodel.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_usuario_repository.dart';

void main() {
  group('AuthViewModel Tests', () {
    late AuthViewModel authViewModel;
    late FakeAuthRepository fakeAuthRepository;
    late FakeUsuarioRepository fakeUsuarioRepository;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeUsuarioRepository = FakeUsuarioRepository();
      authViewModel = AuthViewModel(
        authRepository: fakeAuthRepository,
        usuarioRepository: fakeUsuarioRepository,
      );
    });

    tearDown(() async {
      await fakeAuthRepository.cerrar();
    });

    test('un registro exitoso crea el perfil', () async {
      final success = await authViewModel.registrar(
        nombre: 'Pedro',
        apellido: 'Pérez',
        cedula: 'V-12345678',
        carnet: '2021111001',
        carrera: 'Ingeniería de Sistemas',
        correo: 'pedro@unimet.edu.ve',
        contrasena: 'Clave123',
      );

      expect(success, isTrue);
      expect(authViewModel.error, isNull);
    });

    test('unas credenciales incorrectas dejan el error', () async {
      fakeAuthRepository.debeFallar = true;
      fakeAuthRepository.mensajeError = 'Credenciales inválidas';

      final success = await authViewModel.iniciarSesion(
        correo: 'usuario@correo.com',
        contrasena: 'claveIncorrecta',
      );

      expect(success, isFalse);
      expect(authViewModel.error, equals('Credenciales inválidas'));
    });

    test('inicio de sesion exitoso', () async {
      final id = fakeAuthRepository.agregarCuenta(
        correo: 'ana@correo.unimet.edu.ve',
        contrasena: '123456',
      );
      await fakeUsuarioRepository.crear(
        Estudiante(
          id: id,
          nombre: 'Ana',
          apellido: 'Pérez',
          cedula: '1',
          correo: 'ana@correo.unimet.edu.ve',
          carnet: '1',
          carrera: 'Sistemas',
        ),
      );

      final success = await authViewModel.iniciarSesion(
        correo: 'ana@correo.unimet.edu.ve',
        contrasena: '123456',
      );

      expect(success, isTrue);
      expect(authViewModel.error, isNull);
    });
  });
}
