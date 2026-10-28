import 'conversiones.dart';

enum EstadoInscripcion { activa, cancelada }

/// Une a un estudiante con un deporte.
class Inscripcion {
  const Inscripcion({
    required this.id,
    required this.idEstudiante,
    required this.nombreEstudiante,
    required this.carnetEstudiante,
    required this.idDeporte,
    required this.fecha,
    this.estado = EstadoInscripcion.activa,
  });

  /// Id de la inscripción de un estudiante en un deporte: `idEstudiante_idDeporte`.
  ///
  /// Es siempre el mismo para la misma pareja, así que un estudiante no puede
  /// tener dos inscripciones en un deporte (RF-SIS-04) y las reglas de
  /// seguridad pueden encontrarla sin hacer una consulta.
  static String idPara(String idEstudiante, String idDeporte) =>
      '${idEstudiante}_$idDeporte';

  factory Inscripcion.fromMap(String id, Map<String, dynamic> datos) {
    return Inscripcion(
      id: id,
      idEstudiante: datos['idEstudiante'] as String,
      nombreEstudiante: datos['nombreEstudiante'] as String? ?? '',
      carnetEstudiante: datos['carnetEstudiante'] as String? ?? '',
      idDeporte: datos['idDeporte'] as String,
      fecha: leerFecha(datos['fecha']),
      estado: leerEnum(EstadoInscripcion.values, datos['estado'], 'estado'),
    );
  }

  final String id;
  final String idEstudiante;

  /// Nombre y carnet del estudiante, copiados al inscribirse. Así el
  /// entrenador ve su nómina sin leer los perfiles, que las reglas de
  /// seguridad solo dejan leer a su dueño y al administrador.
  final String nombreEstudiante;
  final String carnetEstudiante;
  final String idDeporte;
  final DateTime fecha;

  /// Al cancelar no se borra la inscripción: queda en el historial como cancelada.
  final EstadoInscripcion estado;

  bool get estaActiva => estado == EstadoInscripcion.activa;

  /// Copia de la inscripción con otro estado. Al cancelar no se borra:
  /// queda en el historial y se puede volver a activar.
  Inscripcion conEstado(EstadoInscripcion nuevo) => Inscripcion(
    id: id,
    idEstudiante: idEstudiante,
    nombreEstudiante: nombreEstudiante,
    carnetEstudiante: carnetEstudiante,
    idDeporte: idDeporte,
    fecha: fecha,
    estado: nuevo,
  );

  Map<String, dynamic> toMap() => {
    'idEstudiante': idEstudiante,
    'nombreEstudiante': nombreEstudiante,
    'carnetEstudiante': carnetEstudiante,
    'idDeporte': idDeporte,
    'fecha': fecha,
    'estado': estado.name,
  };
}
