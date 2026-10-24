import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  const estudiante = Estudiante(
    id: 'e1',
    nombre: 'Ana',
    apellido: 'Perez',
    cedula: 'V-123',
    correo: 'ana@correo.com',
    carnet: '20231234',
    carrera: 'Ingenieria',
  );

  final datosEstudiante = <String, dynamic>{
    'actor': 'estudiante',
    'nombre': 'Ana',
    'apellido': 'Perez',
    'cedula': 'V-123',
    'correo': 'ana@correo.com',
    'carnet': '20231234',
    'carrera': 'Ingenieria',
  };

  group('Persona', () {
    test('nombreCompleto une nombre y apellido', () {
      expect(estudiante.nombreCompleto, 'Ana Perez');
    });

    test('por defecto esta habilitada', () {
      expect(estudiante.habilitado, isTrue);
    });

    test('Persona.fromMap crea un Estudiante', () {
      final p = Persona.fromMap('e1', datosEstudiante);
      expect(p, isA<Estudiante>());
      expect(p.actor, Actor.estudiante);
    });

    test('Persona.fromMap crea un Entrenador', () {
      final p = Persona.fromMap('t1', {
        ...datosEstudiante,
        'actor': 'entrenador',
        'especialidad': 'Natacion',
      });
      expect(p, isA<Entrenador>());
      expect(p.actor, Actor.entrenador);
    });

    test('Persona.fromMap crea un Administrador', () {
      final p = Persona.fromMap('a1', {
        ...datosEstudiante,
        'actor': 'administrador',
        'cargo': 'Coordinador',
      });
      expect(p, isA<Administrador>());
      expect(p.actor, Actor.administrador);
    });

    test('Persona.fromMap lanza FormatException con actor invalido', () {
      expect(
        () => Persona.fromMap('x', {...datosEstudiante, 'actor': 'profesor'}),
        throwsFormatException,
      );
    });

    test('Persona.fromMap lanza FormatException sin actor', () {
      final datos = {...datosEstudiante}..remove('actor');
      expect(() => Persona.fromMap('x', datos), throwsFormatException);
    });

    test('habilitado es true si no viene en los datos', () {
      expect(Persona.fromMap('e1', datosEstudiante).habilitado, isTrue);
    });

    test('respeta habilitado = false (usuario deshabilitado)', () {
      final p = Persona.fromMap('e1', {...datosEstudiante, 'habilitado': false});
      expect(p.habilitado, isFalse);
    });

    test('toMap incluye el actor y los datos comunes', () {
      final mapa = estudiante.toMap();
      expect(mapa['actor'], 'estudiante');
      expect(mapa['nombre'], 'Ana');
      expect(mapa['habilitado'], true);
    });

    test('toMap y fromMap son consistentes (ida y vuelta)', () {
      final copia = Persona.fromMap('e1', estudiante.toMap()) as Estudiante;
      expect(copia.nombreCompleto, estudiante.nombreCompleto);
      expect(copia.carnet, estudiante.carnet);
      expect(copia.solvente, estudiante.solvente);
    });
  });

  group('Estudiante', () {
    test('no es solvente por defecto', () {
      expect(estudiante.solvente, isFalse);
    });

    test('fromMap lee solvente = true', () {
      final e = Estudiante.fromMap('e1', {...datosEstudiante, 'solvente': true});
      expect(e.solvente, isTrue);
    });

    test('toMap incluye carnet, carrera y solvente', () {
      final mapa = estudiante.toMap();
      expect(mapa['carnet'], '20231234');
      expect(mapa['carrera'], 'Ingenieria');
      expect(mapa['solvente'], false);
    });

    test('fromMap sin carnet lanza TypeError', () {
      final datos = {...datosEstudiante}..remove('carnet');
      expect(() => Estudiante.fromMap('e1', datos), throwsA(isA<TypeError>()));
    });
  });

  group('Entrenador', () {
    test('toMap incluye la especialidad', () {
      const t = Entrenador(
        id: 't1',
        nombre: 'Luis',
        apellido: 'Gomez',
        cedula: 'V-456',
        correo: 'luis@correo.com',
        especialidad: 'Futbol',
      );
      expect(t.toMap()['especialidad'], 'Futbol');
      expect(t.toMap()['actor'], 'entrenador');
    });
  });

  group('Administrador', () {
    test('toMap incluye el cargo', () {
      const a = Administrador(
        id: 'a1',
        nombre: 'Rosa',
        apellido: 'Diaz',
        cedula: 'V-789',
        correo: 'rosa@correo.com',
        cargo: 'Director',
      );
      expect(a.toMap()['cargo'], 'Director');
      expect(a.toMap()['actor'], 'administrador');
    });
  });
}