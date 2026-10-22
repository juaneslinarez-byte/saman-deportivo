import 'package:saman_deportivo/modelos/modelos.dart';

/// Pagos de solvencia hechos a través de la pasarela de pagos.
abstract class PagoRepository {
  /// Procesa el pago con la pasarela y lo registra.
  Future<Pago> pagar({required Estudiante estudiante, required double monto});

  /// Pagos de un estudiante, para que consulte su estado.
  Stream<List<Pago>> observarPorEstudiante(String idEstudiante);

  /// Pagos que esperan revisión del administrador.
  Stream<List<Pago>> observarPendientes();

  /// Aprueba el pago y marca al estudiante como solvente (RF-ADM-05, RF-SIS-07).
  Future<void> aprobar(Pago pago);

  Future<void> rechazar(Pago pago);
}
