import '../modelos/modelos.dart';

/// Acceso a las reseñas de las disciplinas.
abstract class ResenaRepository {
  /// Crea o reemplaza la reseña del estudiante. Lanza una excepción con el
  /// mensaje en español si nunca se inscribió en la disciplina.
  Future<void> guardar({
    required Estudiante estudiante,
    required String idDeporte,
    required int calificacion,
    required String comentario,
  });

  Future<void> eliminar(Resena resena);

  /// Reseñas de una disciplina, de la más reciente a la más antigua.
  Stream<List<Resena>> observarPorDeporte(String idDeporte);

  /// La reseña del estudiante en la disciplina, o `null` si no tiene.
  Stream<Resena?> observarMia(String idEstudiante, String idDeporte);
}
