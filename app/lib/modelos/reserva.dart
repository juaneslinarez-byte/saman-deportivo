import 'conversiones.dart';

enum EstadoReserva { enRevision, aprobada, rechazada, cancelada }

/// Reserva de un estudiante en un evento. Queda en revisión hasta que el
/// administrador valida el pago.
class Reserva {
  const Reserva({
    required this.id,
    required this.idEvento,
    required this.idEstudiante,
    required this.nombreEstudiante,
    required this.carnetEstudiante,
    required this.tituloEvento,
    required this.inicioEvento,
    required this.personas,
    required this.monto,
    required this.referencia,
    required this.fecha,
    this.estado = EstadoReserva.enRevision,
  });

  /// `idEstudiante_idEvento`: una sola reserva por estudiante y evento, y
  /// las reglas de seguridad la encuentran sin hacer una consulta.
  static String idPara(String idEstudiante, String idEvento) =>
      '${idEstudiante}_$idEvento';

  factory Reserva.fromMap(String id, Map<String, dynamic> datos) {
    return Reserva(
      id: id,
      idEvento: datos['idEvento'] as String,
      idEstudiante: datos['idEstudiante'] as String,
      nombreEstudiante: datos['nombreEstudiante'] as String? ?? '',
      carnetEstudiante: datos['carnetEstudiante'] as String? ?? '',
      tituloEvento: datos['tituloEvento'] as String? ?? '',
      inicioEvento: leerFecha(datos['inicioEvento']),
      personas: (datos['personas'] as num).toInt(),
      monto: (datos['monto'] as num? ?? 0).toDouble(),
      referencia: datos['referencia'] as String? ?? '',
      fecha: leerFecha(datos['fecha']),
      estado: leerEnum(EstadoReserva.values, datos['estado'], 'estado'),
    );
  }

  final String id;
  final String idEvento;
  final String idEstudiante;

  /// Copiados del perfil al reservar, para la lista del administrador.
  final String nombreEstudiante;
  final String carnetEstudiante;

  /// Copiados del evento, para «Mis reservas».
  final String tituloEvento;
  final DateTime inicioEvento;

  final int personas;

  /// Total: precio por persona por [personas].
  final double monto;

  /// Código de la operación que devuelve la pasarela de pago (vacío si el
  /// evento es gratis).
  final String referencia;
  final DateTime fecha;
  final EstadoReserva estado;

  /// En revisión o aprobada: ocupa cupo.
  bool get vigente =>
      estado == EstadoReserva.enRevision || estado == EstadoReserva.aprobada;

  Map<String, dynamic> toMap() => {
    'idEvento': idEvento,
    'idEstudiante': idEstudiante,
    'nombreEstudiante': nombreEstudiante,
    'carnetEstudiante': carnetEstudiante,
    'tituloEvento': tituloEvento,
    'inicioEvento': inicioEvento,
    'personas': personas,
    'monto': monto,
    'referencia': referencia,
    'fecha': fecha,
    'estado': estado.name,
  };
}
