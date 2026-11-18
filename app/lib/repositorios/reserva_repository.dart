import 'package:saman_deportivo/modelos/modelos.dart';

/// Reservas de los estudiantes en los eventos.
abstract class ReservaRepository {
  /// Reserva [personas] lugares en el evento y descuenta el cupo en la misma
  /// operación. La reserva queda en revisión. Si el estudiante tenía una
  /// reserva cancelada o rechazada en ese evento, se reactiva.
  ///
  /// [referencia] es el código que devolvió la pasarela de pago (vacío si
  /// el evento es gratis).
  Future<Reserva> reservar({
    required Estudiante estudiante,
    required Evento evento,
    required int personas,
    required String referencia,
  });

  /// El estudiante cancela antes de que empiece el evento; devuelve el cupo.
  Future<void> cancelar(Reserva reserva);

  /// El administrador confirma el pago.
  Future<void> aprobar(Reserva reserva);

  /// El administrador rechaza el pago; devuelve el cupo.
  Future<void> rechazar(Reserva reserva);

  Stream<List<Reserva>> observarPorEstudiante(String idEstudiante);

  Stream<List<Reserva>> observarPorEvento(String idEvento);

  /// Todas las reservas que esperan la revisión del administrador.
  Stream<List<Reserva>> observarEnRevision();
}
