import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

Deporte crearDeporte({int cupoMaximo = 20, int disponibles = 20}) {
  return Deporte(
    id: 'd1',
    nombre: 'Baloncesto',
    descripcion: 'Entrenamiento general',
    lugar: 'Cancha 1',
    cupoMaximo: cupoMaximo,
    cuposDisponibles: disponibles,
  );
}

void main() {
  group('Deporte', () {
    test('valores por defecto: sin entrenador y oculto', () {
      final d = crearDeporte();
      expect(d.idEntrenador, isNull);
      expect(d.visible, isFalse);
    });

    test('hayCupo es true si quedan cupos', () {
      expect(crearDeporte(disponibles: 1).hayCupo, isTrue);
    });

    test('hayCupo es false si no quedan cupos', () {
      expect(crearDeporte(disponibles: 0).hayCupo, isFalse);
    });

    test('inscritos = cupoMaximo - cuposDisponibles', () {
      expect(crearDeporte(cupoMaximo: 20, disponibles: 5).inscritos, 15);
    });

    test('inscritos es 0 con todos los cupos libres', () {
      expect(crearDeporte().inscritos, 0);
    });

    test('fromMap lee todos los campos', () {
      final d = Deporte.fromMap('d1', {
        'nombre': 'Tenis',
        'descripcion': 'Nivel basico',
        'lugar': 'Cancha 2',
        'cupoMaximo': 10,
        'cuposDisponibles': 4,
        'idEntrenador': 't1',
        'visible': true,
      });
      expect(d.nombre, 'Tenis');
      expect(d.cupoMaximo, 10);
      expect(d.cuposDisponibles, 4);
      expect(d.idEntrenador, 't1');
      expect(d.visible, isTrue);
    });

    test('fromMap usa valores por defecto en los campos opcionales', () {
      final d = Deporte.fromMap('d1', {
        'nombre': 'Tenis',
        'cupoMaximo': 10,
        'cuposDisponibles': 10,
      });
      expect(d.descripcion, '');
      expect(d.lugar, '');
      expect(d.idEntrenador, isNull);
      expect(d.visible, isFalse);
    });

    test('fromMap sin nombre lanza TypeError', () {
      expect(
        () => Deporte.fromMap('d1', {'cupoMaximo': 10, 'cuposDisponibles': 10}),
        throwsA(isA<TypeError>()),
      );
    });

    test('toMap contiene los datos del deporte', () {
      final mapa = crearDeporte(cupoMaximo: 20, disponibles: 18).toMap();
      expect(mapa['nombre'], 'Baloncesto');
      expect(mapa['cupoMaximo'], 20);
      expect(mapa['cuposDisponibles'], 18);
      expect(mapa['idEntrenador'], isNull);
      expect(mapa['visible'], false);
    });
  });
}
