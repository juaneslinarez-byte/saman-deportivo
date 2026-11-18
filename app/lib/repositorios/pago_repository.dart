import 'package:saman_deportivo/modelos/modelos.dart';

/// Pagos de solvencia hechos a través de la pasarela de pagos.
abstract class PagoRepository {
  /// Registra el pago. [referencia] es el id de la operación que devolvió
  /// PayPal; si no se pasa, se simula la pasarela y se genera una.
  Future<Pago> pagar({
    required Estudiante estudiante,
    required double monto,
    String? referencia,
  });

  /// Pagos de un estudiante, para que consulte su estado.
  Stream<List<Pago>> observarPorEstudiante(String idEstudiante);

  /// Pagos que esperan revisión del administrador.
  Stream<List<Pago>> observarPendientes();

  /// Aprueba el pago y marca al estudiante como solvente (RF-ADM-05, RF-SIS-07).
  Future<void> aprobar(Pago pago);

  Future<void> rechazar(Pago pago);
}
