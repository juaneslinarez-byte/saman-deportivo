import 'conversiones.dart';

enum EstadoInscripcion { activa, cancelada }

/// Une a un estudiante con un deporte.
class Inscripcion {
  const Inscripcion({
    required this.id,
    required this.idEstudiante,
    required this.idDeporte,
    required this.fecha,
    this.estado = EstadoInscripcion.activa,
  });

  factory Inscripcion.fromMap(String id, Map<String, dynamic> datos) {
    return Inscripcion(
      id: id,
      idEstudiante: datos['idEstudiante'] as String,
      idDeporte: datos['idDeporte'] as String,
      fecha: leerFecha(datos['fecha']),
      estado: leerEnum(EstadoInscripcion.values, datos['estado'], 'estado'),
    );
  }

  final String id;
  final String idEstudiante;
  final String idDeporte;
  final DateTime fecha;

  /// Al cancelar no se borra la inscripción: queda en el historial como cancelada.
  final EstadoInscripcion estado;

  bool get estaActiva => estado == EstadoInscripcion.activa;

  Map<String, dynamic> toMap() => {
    'idEstudiante': idEstudiante,
    'idDeporte': idDeporte,
    'fecha': fecha,
    'estado': estado.name,
  };
}
