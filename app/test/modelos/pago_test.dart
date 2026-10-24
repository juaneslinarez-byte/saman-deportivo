import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

void main() {
  final fecha = DateTime(2026, 10, 23, 10, 15);

  Map<String, dynamic> datosPago() => {
    'idEstudiante': 'e1',
    'monto': 25.5,
    'fecha': fecha,
    'referencia': 'REF-001',
    'estado': 'aprobado',
  };

  group('Pago', () {
    test('por defecto esta pendiente', () {
      final p = Pago(
        id: 'p1',
        idEstudiante: 'e1',
        monto: 10,
        fecha: fecha,
        referencia: 'REF-001',
      );
      expect(p.estado, EstadoPago.pendiente);
    });

    test('fromMap lee todos los campos', () {
      final p = Pago.fromMap('p1', datosPago());
      expect(p.idEstudiante, 'e1');
      expect(p.monto, 25.5);
      expect(p.fecha, fecha);
      expect(p.referencia, 'REF-001');
      expect(p.estado, EstadoPago.aprobado);
    });

    test('fromMap convierte un monto entero a double', () {
      final p = Pago.fromMap('p1', {...datosPago(), 'monto': 50});
      expect(p.monto, 50.0);
      expect(p.monto, isA<double>());
    });

    test('fromMap reconoce los tres estados', () {
      for (final estado in EstadoPago.values) {
        final p = Pago.fromMap('p1', {...datosPago(), 'estado': estado.name});
        expect(p.estado, estado);
      }
    });

    test('fromMap con estado invalido lanza FormatException', () {
      expect(
        () => Pago.fromMap('p1', {...datosPago(), 'estado': 'reembolsado'}),
        throwsFormatException,
      );
    });

    test('fromMap sin monto lanza TypeError', () {
      final datos = datosPago()..remove('monto');
      expect(() => Pago.fromMap('p1', datos), throwsA(isA<TypeError>()));
    });

    test('fromMap sin referencia lanza TypeError', () {
      final datos = datosPago()..remove('referencia');
      expect(() => Pago.fromMap('p1', datos), throwsA(isA<TypeError>()));
    });

    test('toMap guarda el estado como texto', () {
      final mapa = Pago.fromMap('p1', datosPago()).toMap();
      expect(mapa['estado'], 'aprobado');
      expect(mapa['monto'], 25.5);
      expect(mapa['referencia'], 'REF-001');
    });
  });
}