import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/viewmodels/perfil_viewmodel.dart';

import '../fakes/fake_usuario_repository.dart';

void main() {
  late FakeUsuarioRepository repositorio;
  late PerfilViewModel viewModel;

  const entrenador = Entrenador(
    id: 't1',
    nombre: 'Luis',
    apellido: 'Gómez',
    cedula: 'V-1',
    correo: 'luis@correo.unimet.edu.ve',
    especialidad: 'Fútbol',
    aniosExperiencia: 3,
  );

  setUp(() {
    repositorio = FakeUsuarioRepository()..agregar(entrenador);
    viewModel = PerfilViewModel(usuarioRepository: repositorio);
  });

  group('PerfilViewModel.guardarCambios', () {
    test('guarda el perfil editado de un entrenador', () async {
      const editado = Entrenador(
        id: 't1',
        nombre: 'Luis',
        apellido: 'Gómez',
        cedula: 'V-1',
        correo: 'luis@correo.unimet.edu.ve',
        especialidad: 'Baloncesto',
        aniosExperiencia: 5,
      );

      final exito = await viewModel.guardarCambios(editado);

      expect(exito, isTrue);
      expect(viewModel.error, isNull);
      expect(viewModel.cargando, isFalse);
      final guardado = await repositorio.obtener('t1') as Entrenador;
      expect(guardado.especialidad, 'Baloncesto');
      expect(guardado.aniosExperiencia, 5);
    });

    test('si la base de datos falla, devuelve false y deja el error', () async {
      repositorio.debeFallar = true;

      final exito = await viewModel.guardarCambios(entrenador);

      expect(exito, isFalse);
      expect(viewModel.error, 'No se pudieron guardar los cambios.');
      expect(viewModel.cargando, isFalse);
    });
  });
}
