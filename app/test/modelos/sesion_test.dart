import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  Map<String, dynamic> datosSesion() => {
    'idDeporte': 'd1',
    'dia': 'miercoles',
    'horaInicio': '16:30',
    'horaFin': '18:00',
    'lugar': 'Gimnasio',
  };

  group('Sesion', () {
    test('fromMap lee todos los campos', () {
      final s = Sesion.fromMap('s1', datosSesion());
      expect(s.idDeporte, 'd1');
      expect(s.dia, DiaSemana.miercoles);
      expect(s.horaInicio, '16:30');
      expect(s.horaFin, '18:00');
      expect(s.lugar, 'Gimnasio');
    });

    test('fromMap reconoce los 7 dias de la semana', () {
      for (final dia in DiaSemana.values) {
        final s = Sesion.fromMap('s1', {...datosSesion(), 'dia': dia.name});
        expect(s.dia, dia);
      }
    });

    test('fromMap con dia invalido lanza FormatException', () {
      expect(
        () => Sesion.fromMap('s1', {...datosSesion(), 'dia': 'feriado'}),
        throwsFormatException,
      );
    });

    test('fromMap sin lugar lanza TypeError', () {
      final datos = datosSesion()..remove('lugar');
      expect(() => Sesion.fromMap('s1', datos), throwsA(isA<TypeError>()));
    });

    test('toMap guarda el dia como texto', () {
      final mapa = Sesion.fromMap('s1', datosSesion()).toMap();
      expect(mapa['dia'], 'miercoles');
      expect(mapa['horaInicio'], '16:30');
      expect(mapa['idDeporte'], 'd1');
    });
  });
}
