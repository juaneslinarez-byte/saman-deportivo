import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/conversiones.dart';

class _FalsoTimestamp {
  _FalsoTimestamp(this._fecha);
  final DateTime _fecha;
  DateTime toDate() => _fecha;
}

enum _Color { rojo, verde }

void main() {
  final fecha = DateTime(2026, 10, 23, 14, 30);

  group('leerFecha', () {
    test('devuelve el mismo DateTime si ya es DateTime', () {
      expect(leerFecha(fecha), fecha);
    });

    test('convierte un texto ISO 8601', () {
      expect(leerFecha('2026-10-23T14:30:00'), fecha);
    });

    test('convierte milisegundos desde 1970', () {
      expect(leerFecha(1000), DateTime.fromMillisecondsSinceEpoch(1000));
    });

    test('convierte un objeto con toDate() (Timestamp de Firestore)', () {
      expect(leerFecha(_FalsoTimestamp(fecha)), fecha);
    });

    test('lanza FormatException si el valor es nulo', () {
      expect(() => leerFecha(null), throwsFormatException);
    });

    test('lanza FormatException si el texto no es una fecha', () {
      expect(() => leerFecha('no es fecha'), throwsFormatException);
    });

    test('lanza FormatException si el tipo no es soportado', () {
      expect(() => leerFecha(true), throwsFormatException);
    });
  });

  group('leerEnum', () {
    test('devuelve el valor que coincide con el nombre', () {
      expect(leerEnum(_Color.values, 'verde', 'color'), _Color.verde);
    });

    test('lanza FormatException si el nombre no existe', () {
      expect(
        () => leerEnum(_Color.values, 'azul', 'color'),
        throwsFormatException,
      );
    });

    test('lanza FormatException si el nombre es nulo', () {
      expect(
        () => leerEnum(_Color.values, null, 'color'),
        throwsFormatException,
      );
    });
  });
}
