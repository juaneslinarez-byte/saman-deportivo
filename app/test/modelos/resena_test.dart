import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  final fecha = DateTime(2026, 11, 22, 10);

  group('Resena', () {
    test('guarda y lee la calificación del entrenador', () {
      final r = Resena(
        idDeporte: 'd1',
        idEstudiante: 'e1',
        nombreEstudiante: 'Ana Prueba',
        calificacion: 4,
        calificacionEntrenador: 5,
        comentario: 'Buenas clases y muy puntual.',
        fecha: fecha,
      );
      final leida = Resena.fromMap(r.toMap());
      expect(leida.id, 'e1_d1');
      expect(leida.calificacion, 4);
      expect(leida.calificacionEntrenador, 5);
    });

    test('las reseñas anteriores no tienen calificación del entrenador', () {
      final r = Resena(
        idDeporte: 'd1',
        idEstudiante: 'e1',
        nombreEstudiante: 'Ana Prueba',
        calificacion: 3,
        comentario: 'Faltan más horarios en la tarde.',
        fecha: fecha,
      );
      expect(r.toMap().containsKey('calificacionEntrenador'), isFalse);
      expect(Resena.fromMap(r.toMap()).calificacionEntrenador, isNull);
    });
  });
}
