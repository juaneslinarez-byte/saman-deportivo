/// Disciplina deportiva que se ofrece en el catálogo.
class Deporte {
  const Deporte({
    required this.id,
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

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'lugar': lugar,
    'cupoMaximo': cupoMaximo,
    'cuposDisponibles': cuposDisponibles,
    'idEntrenador': idEntrenador,
    'visible': visible,
  };
}
