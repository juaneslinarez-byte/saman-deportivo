import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  final fecha = DateTime(2026, 10, 23, 16, 30);

  Map<String, dynamic> datosAsistencia() => {
    'idInscripcion': 'i1',
    'idEstudiante': 'e1',
    'idDeporte': 'd1',
    'idSesion': 's1',
    'fecha': fecha,
    'presente': true,
  };

  group('Asistencia', () {
    test('fromMap lee un registro presente', () {
      final a = Asistencia.fromMap('a1', datosAsistencia());
      expect(a.idInscripcion, 'i1');
      expect(a.idEstudiante, 'e1');
      expect(a.idDeporte, 'd1');
      expect(a.idSesion, 's1');
      expect(a.fecha, fecha);
      expect(a.presente, isTrue);
    });

    test('fromMap lee un registro ausente', () {
      final a = Asistencia.fromMap('a1', {
        ...datosAsistencia(),
        'presente': false,
      });
      expect(a.presente, isFalse);
    });

    test('fromMap acepta la fecha en milisegundos', () {
      final a = Asistencia.fromMap('a1', {...datosAsistencia(), 'fecha': 0});
      expect(a.fecha, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromMap sin presente lanza TypeError', () {
      final datos = datosAsistencia()..remove('presente');
      expect(() => Asistencia.fromMap('a1', datos), throwsA(isA<TypeError>()));
    });

    test('fromMap con fecha invalida lanza FormatException', () {
      expect(
        () => Asistencia.fromMap('a1', {...datosAsistencia(), 'fecha': 'hoy'}),
        throwsFormatException,
      );
    });

    test('toMap conserva todos los datos', () {
      final mapa = Asistencia.fromMap('a1', datosAsistencia()).toMap();
      expect(mapa['idInscripcion'], 'i1');
      expect(mapa['idEstudiante'], 'e1');
      expect(mapa['idDeporte'], 'd1');
      expect(mapa['idSesion'], 's1');
      expect(mapa['fecha'], fecha);
      expect(mapa['presente'], true);
    });

    test('idPara usa la inscripción, la sesión y el día', () {
      expect(
        Asistencia.idPara('i1', 's1', DateTime(2026, 11, 3, 16, 30)),
        'i1_s1_20261103',
      );
    });
  });
}
