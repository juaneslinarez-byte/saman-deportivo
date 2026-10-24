import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  final fecha = DateTime(2026, 10, 23, 9, 0);

  group('Inscripcion', () {
    test('por defecto esta activa', () {
      final i = Inscripcion(
        id: 'i1',
        idEstudiante: 'e1',
        idDeporte: 'd1',
        fecha: fecha,
      );
      expect(i.estado, EstadoInscripcion.activa);
      expect(i.estaActiva, isTrue);
    });

    test('una inscripcion cancelada no esta activa', () {
      final i = Inscripcion(
        id: 'i1',
        idEstudiante: 'e1',
        idDeporte: 'd1',
        fecha: fecha,
        estado: EstadoInscripcion.cancelada,
      );
      expect(i.estaActiva, isFalse);
    });

    test('fromMap lee los campos y convierte la fecha ISO', () {
      final i = Inscripcion.fromMap('i1', {
        'idEstudiante': 'e1',
        'idDeporte': 'd1',
        'fecha': '2026-10-23T09:00:00',
        'estado': 'cancelada',
      });
      expect(i.idEstudiante, 'e1');
      expect(i.idDeporte, 'd1');
      expect(i.fecha, fecha);
      expect(i.estado, EstadoInscripcion.cancelada);
    });

    test('fromMap con estado invalido lanza FormatException', () {
      expect(
        () => Inscripcion.fromMap('i1', {
          'idEstudiante': 'e1',
          'idDeporte': 'd1',
          'fecha': fecha,
          'estado': 'pausada',
        }),
        throwsFormatException,
      );
    });

    // OJO: el constructor tiene "activa" por defecto, pero fromMap exige
    // el campo estado. Se documenta este comportamiento actual.
    test('fromMap sin estado lanza FormatException', () {
      expect(
        () => Inscripcion.fromMap('i1', {
          'idEstudiante': 'e1',
          'idDeporte': 'd1',
          'fecha': fecha,
        }),
        throwsFormatException,
      );
    });

    test('fromMap con fecha invalida lanza FormatException', () {
      expect(
        () => Inscripcion.fromMap('i1', {
          'idEstudiante': 'e1',
          'idDeporte': 'd1',
          'fecha': 'ayer',
          'estado': 'activa',
        }),
        throwsFormatException,
      );
    });

    test('toMap guarda el estado como texto', () {
      final mapa = Inscripcion(
        id: 'i1',
        idEstudiante: 'e1',
        idDeporte: 'd1',
        fecha: fecha,
      ).toMap();
      expect(mapa['estado'], 'activa');
      expect(mapa['idEstudiante'], 'e1');
      expect(mapa['fecha'], fecha);
    });
  });
}