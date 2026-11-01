import 'conversiones.dart';

/// Registro de si un inscrito asistió a una sesión en una fecha.
class Asistencia {
  const Asistencia({
    required this.id,
    required this.idInscripcion,
    required this.idEstudiante,
    required this.idDeporte,
    required this.idSesion,
    required this.fecha,
    required this.presente,
  });

  /// Id del registro de un inscrito en una sesión y un día:
  /// `idInscripcion_idSesion_AAAAMMDD`. Si el entrenador vuelve a tomar la
  /// asistencia de ese día, se reemplaza el registro en lugar de duplicarlo.
  static String idPara(String idInscripcion, String idSesion, DateTime fecha) {
    final dia =
        '${fecha.year}'
        '${fecha.month.toString().padLeft(2, '0')}'
        '${fecha.day.toString().padLeft(2, '0')}';
    return '${idInscripcion}_${idSesion}_$dia';
  }

  factory Asistencia.fromMap(String id, Map<String, dynamic> datos) {
    return Asistencia(
      id: id,
      idInscripcion: datos['idInscripcion'] as String,
      idEstudiante: datos['idEstudiante'] as String,
      idDeporte: datos['idDeporte'] as String,
      idSesion: datos['idSesion'] as String,
      fecha: leerFecha(datos['fecha']),
      presente: datos['presente'] as bool,
    );
  }

  final String id;
  final String idInscripcion;

  /// Estudiante y deporte de la inscripción, copiados para que el estudiante
  /// consulte su historial y las reglas de seguridad sepan qué entrenador
  /// puede registrar la asistencia, sin leer otros documentos.
  final String idEstudiante;
  final String idDeporte;
  final String idSesion;
  final DateTime fecha;
  final bool presente;

  Map<String, dynamic> toMap() => {
    'idInscripcion': idInscripcion,
    'idEstudiante': idEstudiante,
    'idDeporte': idDeporte,
    'idSesion': idSesion,
    'fecha': fecha,
    'presente': presente,
  };
}
