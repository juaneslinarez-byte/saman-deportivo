/// Disciplina deportiva que se ofrece en el catálogo.
class Deporte {
  const Deporte({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.lugar,
    required this.cupoMaximo,
    required this.cuposDisponibles,
    this.idEntrenador,
    this.visible = false,
  });

  factory Deporte.fromMap(String id, Map<String, dynamic> datos) {
    return Deporte(
      id: id,
      codigo: datos['codigo'] as String? ?? '',
      nombre: datos['nombre'] as String,
      descripcion: datos['descripcion'] as String? ?? '',
      lugar: datos['lugar'] as String? ?? '',
      cupoMaximo: datos['cupoMaximo'] as int,
      cuposDisponibles: datos['cuposDisponibles'] as int,
      idEntrenador: datos['idEntrenador'] as String?,
      visible: datos['visible'] as bool? ?? false,
    );
  }

  final String id;

  /// Código único del deporte, por ejemplo «FUT-01». Lo asigna el
  /// administrador al crearlo y sirve para buscarlo en el catálogo.
  final String codigo;
  final String nombre;
  final String descripcion;
  final String lugar;
  final int cupoMaximo;

  /// Se descuenta y se devuelve dentro de una transacción al inscribir y
  /// cancelar, para que nunca se asignen más cupos de los que hay (RNF-07).
  final int cuposDisponibles;

  /// Entrenador asignado. Es nulo mientras el administrador no asigne uno.
  final String? idEntrenador;

  /// Un deporte nuevo se crea oculto hasta que tenga entrenador y sesiones.
  final bool visible;

  bool get hayCupo => cuposDisponibles > 0;

  int get inscritos => cupoMaximo - cuposDisponibles;

  /// Copia el deporte cambiando solo los campos indicados. La usan el
  /// administrador al editarlo y los repositorios al mover los cupos.
  ///
  /// Para quitar el entrenador asignado se pasa [quitarEntrenador] en true,
  /// porque un null en [idEntrenador] significa «no cambiarlo».
  Deporte copyWith({
    String? codigo,
    String? nombre,
    String? descripcion,
    String? lugar,
    int? cupoMaximo,
    int? cuposDisponibles,
    String? idEntrenador,
    bool quitarEntrenador = false,
    bool? visible,
  }) {
    return Deporte(
      id: id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      lugar: lugar ?? this.lugar,
      cupoMaximo: cupoMaximo ?? this.cupoMaximo,
      cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
      idEntrenador: quitarEntrenador ? null : idEntrenador ?? this.idEntrenador,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toMap() => {
    'codigo': codigo,
    'nombre': nombre,
    'descripcion': descripcion,
    'lugar': lugar,
    'cupoMaximo': cupoMaximo,
    'cuposDisponibles': cuposDisponibles,
    'idEntrenador': idEntrenador,
    'visible': visible,
  };
}
