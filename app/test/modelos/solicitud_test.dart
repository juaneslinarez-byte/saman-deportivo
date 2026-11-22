import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  final fecha = DateTime(2026, 11, 22, 9);

  group('Solicitud', () {
    test('el id es idEntrenador_idDeporte', () {
      final s = Solicitud(
        idEntrenador: 't1',
        nombreEntrenador: 'María Bolívar',
        idDeporte: 'd1',
        nombreDeporte: 'Natación',
        fecha: fecha,
      );
      expect(s.id, 't1_d1');
      expect(s.estaPendiente, isTrue);
    });

    test('toMap y fromMap conservan los datos', () {
      final s = Solicitud(
        idEntrenador: 't1',
        nombreEntrenador: 'María Bolívar',
        idDeporte: 'd1',
        nombreDeporte: 'Natación',
        fecha: fecha,
        mensaje: 'Fui nadadora 8 años',
        estado: EstadoSolicitud.rechazada,
      );
      final leida = Solicitud.fromMap(s.toMap());
      expect(leida.id, s.id);
      expect(leida.nombreDeporte, 'Natación');
      expect(leida.mensaje, 'Fui nadadora 8 años');
      expect(leida.estado, EstadoSolicitud.rechazada);
      expect(leida.fecha, fecha);
    });

    test('un estado inválido lanza FormatException', () {
      expect(
        () => Solicitud.fromMap({
          'idEntrenador': 't1',
          'idDeporte': 'd1',
          'fecha': fecha,
          'estado': 'otro',
        }),
        throwsFormatException,
      );
    });
  });
}
