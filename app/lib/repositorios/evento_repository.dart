import 'package:saman_deportivo/modelos/modelos.dart';

/// Eventos del club que el estudiante puede reservar.
abstract class EventoRepository {
  /// Eventos publicados que todavía no han terminado, del más próximo al
  /// más lejano.
  Stream<List<Evento>> observarProximos();

  /// Todos los eventos, para el administrador.
  Stream<List<Evento>> observarTodos();

  Future<String> crear(Evento evento);

  /// Guarda los cambios. No deja bajar el cupo por debajo de lo reservado.
  Future<void> actualizar(Evento evento);

  /// Pasa el evento a cancelado y cancela sus reservas vigentes en la misma
  /// operación.
  Future<void> cancelar(Evento evento);

  /// Elimina un evento que nunca tuvo reservas.
  Future<void> eliminar(Evento evento);
}
