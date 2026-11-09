import '../modelos/resena.dart';

abstract class ResenaRepository {
  Future<void> guardar(
    String idEstudiante,
    String idDeporte,
    int calificacion,
    String comentario,
  );

  Future<void> eliminar(Resena resena);

  Stream<List<Resena>> observarPorDeporte(String idDeporte);

  Stream<Resena?> observarMia(String idEstudiante, String idDeporte);
}
