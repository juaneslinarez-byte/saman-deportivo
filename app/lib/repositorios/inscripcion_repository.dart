import 'package:saman_deportivo/modelos/modelos.dart';

/// Inscripciones de los estudiantes en los deportes.
abstract class InscripcionRepository {
  /// Inscribe al estudiante y descuenta un cupo en una sola operación, de
  /// modo que dos inscripciones simultáneas nunca superen el cupo (RNF-07).
  ///
  /// La inscripción se guarda con el id [Inscripcion.idPara] y con el nombre
  /// y el carnet del estudiante. Si el estudiante tenía una inscripción
  /// cancelada en ese deporte, se vuelve a activar en lugar de crear otra.
  ///
  /// Lanza [InscripcionRechazada] si no hay cupo, si el estudiante ya está
  /// inscrito o si no está solvente.
  Future<Inscripcion> inscribir(Estudiante estudiante, Deporte deporte);

  /// Cancela la inscripción y devuelve el cupo en una sola operación.
  Future<void> cancelar(Inscripcion inscripcion);

  /// Inscripciones de un estudiante, para «Mis inscripciones».
  Stream<List<Inscripcion>> observarPorEstudiante(String idEstudiante);

  /// Inscripciones activas de un deporte, para la nómina del entrenador.
  Stream<List<Inscripcion>> observarPorDeporte(String idDeporte);
}

enum MotivoRechazo {
  sinCupo('La disciplina no tiene cupos disponibles.'),
  yaInscrito('Ya estás inscrito en esta disciplina.'),
  noSolvente('Debes estar solvente para inscribirte.');

  const MotivoRechazo(this.mensaje);

  final String mensaje;
}

/// Inscripción no permitida por una regla del sistema
/// (RF-SIS-01, RF-SIS-02 y RF-SIS-04).
class InscripcionRechazada implements Exception {
  const InscripcionRechazada(this.motivo);

  final MotivoRechazo motivo;

  @override
  String toString() => motivo.mensaje;
}
