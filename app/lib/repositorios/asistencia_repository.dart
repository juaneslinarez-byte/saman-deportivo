import 'package:saman_deportivo/modelos/modelos.dart';

/// Asistencia de los inscritos a las sesiones de entrenamiento (CU-07).
abstract class AsistenciaRepository {
  /// Guarda la asistencia de una sesión en un día: un registro por cada
  /// inscrito, presente o ausente, en una sola operación (RF-ENT-03).
  ///
  /// Cada registro usa el id [Asistencia.idPara], así que volver a tomar la
  /// asistencia del mismo día la corrige en lugar de duplicarla.
  Future<void> registrar(List<Asistencia> asistencias);

  /// Asistencia de una sesión en un día, para que el entrenador la revise o
  /// la corrija.
  Stream<List<Asistencia>> observarPorSesion(String idSesion, DateTime fecha);

  /// Historial de asistencia de un deporte, para su entrenador (RF-ENT-04).
  Stream<List<Asistencia>> observarPorDeporte(String idDeporte);

  /// Historial de asistencia de un estudiante, de todas sus inscripciones
  /// (RF-EST-06).
  Stream<List<Asistencia>> observarPorEstudiante(String idEstudiante);
}
