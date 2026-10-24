import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

import '../fakes/fake_deporte_repository.dart';
import '../fakes/fake_inscripcion_repository.dart';

/// Pruebas de las reglas de inscripción (RF-SIS-01, RF-SIS-02, RF-SIS-04 y
/// RNF-07) sobre los repositorios falsos, sin Firebase.
void main() {
  late FakeDeporteRepository deportes;
  late FakeInscripcionRepository inscripciones;

  const solvente = Estudiante(
    id: 'e1',
    nombre: 'Ana',
    apellido: 'Pérez',
    cedula: '30111222',
    correo: 'ana.perez@correo.unimet.edu.ve',
    carnet: '20231110001',
    carrera: 'Ingeniería de Sistemas',
    solvente: true,
  );

  const noSolvente = Estudiante(
    id: 'e2',
    nombre: 'Luis',
    apellido: 'Gómez',
    cedula: '30333444',
    correo: 'luis.gomez@correo.unimet.edu.ve',
    carnet: '20231110002',
    carrera: 'Ingeniería Civil',
  );

  Deporte futbol({int cupos = 2}) => Deporte(
    id: 'futbol',
    nombre: 'Fútbol',
    descripcion: 'Entrenamiento de fútbol sala',
    lugar: 'Cancha techada',
    cupoMaximo: 2,
    cuposDisponibles: cupos,
    visible: true,
  );

  /// Verifica que [accion] se rechace con el [motivo] indicado.
  Future<void> esperarRechazo(
    Future<void> Function() accion,
    MotivoRechazo motivo,
  ) async {
    await expectLater(
      accion(),
      throwsA(
        isA<InscripcionRechazada>().having((e) => e.motivo, 'motivo', motivo),
      ),
    );
  }

  setUp(() {
    deportes = FakeDeporteRepository();
    inscripciones = FakeInscripcionRepository(deportes);
  });

  tearDown(() async {
    await inscripciones.cerrar();
    await deportes.cerrar();
  });

  group('Reglas de inscripción', () {
    test('un estudiante solvente se inscribe y se descuenta un cupo', () async {
      deportes.agregar(futbol());

      final inscripcion = await inscripciones.inscribir(solvente, futbol());

      expect(inscripcion.estaActiva, isTrue);
      expect(inscripcion.idEstudiante, solvente.id);
      expect((await deportes.obtener('futbol'))!.cuposDisponibles, 1);
    });

    test('rechaza a un estudiante que no está solvente (RF-SIS-02)', () async {
      deportes.agregar(futbol());

      await esperarRechazo(
        () => inscripciones.inscribir(noSolvente, futbol()),
        MotivoRechazo.noSolvente,
      );
      expect(inscripciones.cantidad, 0);
      expect((await deportes.obtener('futbol'))!.cuposDisponibles, 2);
    });

    test('rechaza una segunda inscripción en el mismo deporte '
        '(RF-SIS-04)', () async {
      deportes.agregar(futbol());
      await inscripciones.inscribir(solvente, futbol());

      await esperarRechazo(
        () => inscripciones.inscribir(solvente, futbol()),
        MotivoRechazo.yaInscrito,
      );
      expect(inscripciones.cantidad, 1);
    });

    test('rechaza la inscripción si no quedan cupos (RF-SIS-01)', () async {
      deportes.agregar(futbol(cupos: 0));

      await esperarRechazo(
        () => inscripciones.inscribir(solvente, futbol(cupos: 0)),
        MotivoRechazo.sinCupo,
      );
      expect(inscripciones.cantidad, 0);
    });

    test('usa los cupos guardados y no los del deporte recibido '
        '(RNF-07)', () async {
      // La vista puede tener una copia vieja que todavía muestra cupos.
      deportes.agregar(futbol(cupos: 0));

      await esperarRechazo(
        () => inscripciones.inscribir(solvente, futbol(cupos: 2)),
        MotivoRechazo.sinCupo,
      );
    });

    test('la solvencia se revisa antes que los cupos', () async {
      deportes.agregar(futbol(cupos: 0));

      await esperarRechazo(
        () => inscripciones.inscribir(noSolvente, futbol(cupos: 0)),
        MotivoRechazo.noSolvente,
      );
    });

    test('al cancelar se devuelve el cupo y se puede volver a '
        'inscribir', () async {
      deportes.agregar(futbol(cupos: 1));
      final inscripcion = await inscripciones.inscribir(solvente, futbol());
      expect((await deportes.obtener('futbol'))!.cuposDisponibles, 0);

      await inscripciones.cancelar(inscripcion);

      expect((await deportes.obtener('futbol'))!.cuposDisponibles, 1);
      final nueva = await inscripciones.inscribir(solvente, futbol());
      expect(nueva.estaActiva, isTrue);
    });
  });
}
