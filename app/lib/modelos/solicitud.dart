import 'conversiones.dart';

enum EstadoSolicitud { pendiente, aprobada, rechazada }

/// Solicitud de un entrenador para dirigir otra disciplina (RF-ENT-06). La
/// aprueba o rechaza el administrador (RF-ADM-07).
///
/// Se guarda en `solicitudes/{idEntrenador_idDeporte}`: hay una sola por
/// entrenador y disciplina, y si la rechazan puede volver a enviarla.
class Solicitud {
  const Solicitud({
    required this.idEntrenador,
    required this.nombreEntrenador,
    required this.idDeporte,
    required this.nombreDeporte,
    required this.fecha,
    this.mensaje = '',
    this.estado = EstadoSolicitud.pendiente,
  });

  factory Solicitud.fromMap(Map<String, dynamic> datos) {
    return Solicitud(
      idEntrenador: datos['idEntrenador'] as String,
      nombreEntrenador: datos['nombreEntrenador'] as String? ?? '',
      idDeporte: datos['idDeporte'] as String,
      nombreDeporte: datos['nombreDeporte'] as String? ?? '',
      fecha: leerFecha(datos['fecha']),
      mensaje: datos['mensaje'] as String? ?? '',
      estado: leerEnum(EstadoSolicitud.values, datos['estado'], 'estado'),
    );
  }

  final String idEntrenador;

  /// Copiado del perfil al enviarla, para que el administrador lo vea sin
  /// leer el perfil.
  final String nombreEntrenador;
  final String idDeporte;
  final String nombreDeporte;
  final DateTime fecha;

  /// Motivo opcional que escribe el entrenador.
  final String mensaje;
  final EstadoSolicitud estado;

  String get id => idPara(idEntrenador, idDeporte);

  static String idPara(String idEntrenador, String idDeporte) =>
      '${idEntrenador}_$idDeporte';

  bool get estaPendiente => estado == EstadoSolicitud.pendiente;

  Solicitud copyWith({EstadoSolicitud? estado}) => Solicitud(
    idEntrenador: idEntrenador,
    nombreEntrenador: nombreEntrenador,
    idDeporte: idDeporte,
    nombreDeporte: nombreDeporte,
    fecha: fecha,
    mensaje: mensaje,
    estado: estado ?? this.estado,
  );

  Map<String, dynamic> toMap() => {
    'idEntrenador': idEntrenador,
    'nombreEntrenador': nombreEntrenador,
    'idDeporte': idDeporte,
    'nombreDeporte': nombreDeporte,
    'fecha': fecha,
    'mensaje': mensaje,
    'estado': estado.name,
  };
}
