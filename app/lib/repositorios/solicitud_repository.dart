import 'package:saman_deportivo/modelos/modelos.dart';

/// Solicitudes de los entrenadores para dirigir otra disciplina.
abstract class SolicitudRepository {
  /// Solicitudes del entrenador, de la más reciente a la más antigua.
  Stream<List<Solicitud>> observarPorEntrenador(String idEntrenador);

  /// Solicitudes que esperan la decisión del administrador, de la más
  /// antigua a la más reciente.
  Stream<List<Solicitud>> observarPendientes();

  /// Envía (o vuelve a enviar, si se la rechazaron) la solicitud del
  /// entrenador para [deporte]. Falla si ya la dirige o si ya tiene una
  /// pendiente.
  Future<void> solicitar({
    required Entrenador entrenador,
    required Deporte deporte,
    String mensaje = '',
  });

  /// Aprueba la solicitud y agrega al entrenador a la disciplina en la
  /// misma operación.
  Future<void> aprobar(Solicitud solicitud);

  Future<void> rechazar(Solicitud solicitud);
}
