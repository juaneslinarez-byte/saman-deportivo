import 'conversiones.dart';

enum EstadoPago { pendiente, aprobado, rechazado }

/// Pago de solvencia de un estudiante, hecho a través de la pasarela de pagos.
class Pago {
  const Pago({
    required this.id,
    required this.idEstudiante,
    required this.monto,
    required this.fecha,
    required this.referencia,
    this.estado = EstadoPago.pendiente,
  });

  factory Pago.fromMap(String id, Map<String, dynamic> datos) {
    return Pago(
      id: id,
      idEstudiante: datos['idEstudiante'] as String,
      monto: (datos['monto'] as num).toDouble(),
      fecha: leerFecha(datos['fecha']),
      referencia: datos['referencia'] as String,
      estado: leerEnum(EstadoPago.values, datos['estado'], 'estado'),
    );
  }

  final String id;
  final String idEstudiante;
  final double monto;
  final DateTime fecha;

  /// Código de la operación que devuelve la pasarela.
  final String referencia;

  /// Al aprobarse el pago, el estudiante pasa a estar solvente (RF-SIS-07).
  final EstadoPago estado;

  Map<String, dynamic> toMap() => {
    'idEstudiante': idEstudiante,
    'monto': monto,
    'fecha': fecha,
    'referencia': referencia,
    'estado': estado.name,
  };
}
