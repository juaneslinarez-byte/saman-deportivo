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
    String? idEntrenador,
    List<String> idsEntrenadores = const [],
    this.visible = false,
  }) : _idEntrenadorAnterior = idEntrenador,
       _asignados = idsEntrenadores;

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
      idsEntrenadores: [
        for (final id in datos['idsEntrenadores'] as List? ?? const [])
          if (id is String && id.isNotEmpty) id,
      ],
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

  /// Entrenadores asignados. Una disciplina puede tener varios; mientras el
  /// administrador no asigne ninguno, la lista está vacía.
  ///
  /// Los deportes creados antes de admitir varios entrenadores solo tienen
  /// el campo `idEntrenador`; en ese caso la lista es ese único entrenador.
  List<String> get idsEntrenadores {
    if (_asignados.isNotEmpty) return _asignados;
    final anterior = _idEntrenadorAnterior;
    if (anterior == null || anterior.isEmpty) return const [];
    return [anterior];
  }

  /// Entrenador principal: el primero asignado. Es nulo si no hay ninguno.
  String? get idEntrenador =>
      idsEntrenadores.isEmpty ? null : idsEntrenadores.first;

  bool get tieneEntrenador => idsEntrenadores.isNotEmpty;

  /// ¿El entrenador [idPersona] da clases en esta disciplina?
  bool tieneAlEntrenador(String idPersona) =>
      idsEntrenadores.contains(idPersona);

  final String? _idEntrenadorAnterior;
  final List<String> _asignados;

  /// Un deporte nuevo se crea oculto hasta que tenga entrenador y sesiones.
  final bool visible;

  bool get hayCupo => cuposDisponibles > 0;

  int get inscritos => cupoMaximo - cuposDisponibles;

  /// Copia el deporte cambiando solo los campos indicados. La usan el
  /// administrador al editarlo y los repositorios al mover los cupos.
  ///
  /// [idsEntrenadores] reemplaza la lista de entrenadores e [idEntrenador]
  /// deja uno solo. Para quitarlos todos se pasa [quitarEntrenador] en true,
  /// porque un null significa «no cambiarlo».
  Deporte copyWith({
    String? codigo,
    String? nombre,
    String? descripcion,
    String? lugar,
    int? cupoMaximo,
    int? cuposDisponibles,
    String? idEntrenador,
    List<String>? idsEntrenadores,
    bool quitarEntrenador = false,
    bool? visible,
  }) {
    final List<String> entrenadores = quitarEntrenador
        ? const []
        : idsEntrenadores ??
              (idEntrenador != null ? [idEntrenador] : this.idsEntrenadores);
    return Deporte(
      id: id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      lugar: lugar ?? this.lugar,
      cupoMaximo: cupoMaximo ?? this.cupoMaximo,
      cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
      idsEntrenadores: List.unmodifiable(entrenadores.toSet()),
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
    // Se guarda también el principal para los datos y reglas anteriores.
    'idEntrenador': idEntrenador,
    'idsEntrenadores': idsEntrenadores,
    'visible': visible,
  };
}
