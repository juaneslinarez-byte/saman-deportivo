import 'conversiones.dart';

enum EstadoEvento { publicado, cancelado }

/// Evento del club (torneo, clínica, jornada abierta) que el estudiante
/// puede reservar. Lo publica el administrador.
class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.inicio,
    required this.duracionMinutos,
    required this.cupo,
    required this.cuposDisponibles,
    required this.monto,
    required this.maxPorReserva,
    this.idDeporte,
    this.estado = EstadoEvento.publicado,
  });

  factory Evento.fromMap(String id, Map<String, dynamic> datos) {
    return Evento(
      id: id,
      titulo: datos['titulo'] as String,
      descripcion: datos['descripcion'] as String? ?? '',
      lugar: datos['lugar'] as String? ?? '',
      inicio: leerFecha(datos['inicio']),
      duracionMinutos: (datos['duracionMinutos'] as num).toInt(),
      cupo: (datos['cupo'] as num).toInt(),
      cuposDisponibles: (datos['cuposDisponibles'] as num).toInt(),
      monto: (datos['monto'] as num? ?? 0).toDouble(),
      maxPorReserva: (datos['maxPorReserva'] as num? ?? 1).toInt(),
      idDeporte: datos['idDeporte'] as String?,
      estado: leerEnum(EstadoEvento.values, datos['estado'], 'estado'),
    );
  }

  final String id;
  final String titulo;
  final String descripcion;

  /// Uno de [Catalogos.lugaresEvento].
  final String lugar;
  final DateTime inicio;
  final int duracionMinutos;

  /// Personas que caben en total.
  final int cupo;

  /// Lo mueven las reservas: baja al reservar y sube al cancelar o rechazar.
  final int cuposDisponibles;

  /// Precio por persona en dólares; 0 es gratis.
  final double monto;

  /// Cuántas personas puede incluir una sola reserva.
  final int maxPorReserva;

  /// Disciplina relacionada, si la hay.
  final String? idDeporte;
  final EstadoEvento estado;

  DateTime get fin => inicio.add(Duration(minutes: duracionMinutos));

  bool get estaCancelado => estado == EstadoEvento.cancelado;

  bool get esGratis => monto <= 0;

  bool get hayCupo => cuposDisponibles > 0;

  /// Personas con una reserva vigente.
  int get reservados => cupo - cuposDisponibles;

  /// Ya empezó: no se puede reservar ni cancelar una reserva.
  bool yaEmpezo(DateTime ahora) => !inicio.isAfter(ahora);

  /// Ya terminó: deja de aparecer entre los próximos.
  bool yaPaso(DateTime ahora) => !fin.isAfter(ahora);

  Evento copyWith({
    String? titulo,
    String? descripcion,
    String? lugar,
    DateTime? inicio,
    int? duracionMinutos,
    int? cupo,
    int? cuposDisponibles,
    double? monto,
    int? maxPorReserva,
    String? idDeporte,
    bool quitarDeporte = false,
    EstadoEvento? estado,
  }) {
    return Evento(
      id: id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      lugar: lugar ?? this.lugar,
      inicio: inicio ?? this.inicio,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      cupo: cupo ?? this.cupo,
      cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
      monto: monto ?? this.monto,
      maxPorReserva: maxPorReserva ?? this.maxPorReserva,
      idDeporte: quitarDeporte ? null : idDeporte ?? this.idDeporte,
      estado: estado ?? this.estado,
    );
  }

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'lugar': lugar,
    'inicio': inicio,
    'duracionMinutos': duracionMinutos,
    'cupo': cupo,
    'cuposDisponibles': cuposDisponibles,
    'monto': monto,
    'maxPorReserva': maxPorReserva,
    'idDeporte': idDeporte,
    'estado': estado.name,
  };
}
