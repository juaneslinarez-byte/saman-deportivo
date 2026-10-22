import 'conversiones.dart';

/// Registro de si un inscrito asistió a una sesión en una fecha.
class Asistencia {
  const Asistencia({
    required this.id,
    required this.idInscripcion,
    required this.idSesion,
    required this.fecha,
    required this.presente,
  });

  factory Asistencia.fromMap(String id, Map<String, dynamic> datos) {
    return Asistencia(
      id: id,
      idInscripcion: datos['idInscripcion'] as String,
      idSesion: datos['idSesion'] as String,
      fecha: leerFecha(datos['fecha']),
      presente: datos['presente'] as bool,
    );
  }

  final String id;
  final String idInscripcion;
  final String idSesion;
  final DateTime fecha;
  final bool presente;

  Map<String, dynamic> toMap() => {
    'idInscripcion': idInscripcion,
    'idSesion': idSesion,
    'fecha': fecha,
    'presente': presente,
  };
}
