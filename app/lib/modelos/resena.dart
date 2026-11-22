/// Reseña de un estudiante sobre una disciplina en la que se inscribió.
///
/// Se guarda en `resenas/{idEstudiante_idDeporte}`: el mismo id de su
/// inscripción, así que hay una sola reseña por estudiante y disciplina.
class Resena {
  const Resena({
    required this.idDeporte,
    required this.idEstudiante,
    required this.nombreEstudiante,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
    this.calificacionEntrenador,
    this.editada = false,
  });

  final String idDeporte;
  final String idEstudiante;

  /// Copiado del perfil al publicar, porque los demás no pueden leer el
  /// perfil del estudiante.
  final String nombreEstudiante;

  /// De 1 a 5 estrellas, para la disciplina.
  final int calificacion;

  /// De 1 a 5 estrellas, para el entrenador de la disciplina (RF-EST-09).
  /// Es nula en las reseñas escritas antes de calificar al entrenador.
  final int? calificacionEntrenador;
  final String comentario;

  /// Fecha de la última edición.
  final DateTime fecha;
  final bool editada;

  String get id => idPara(idEstudiante, idDeporte);

  static String idPara(String idEstudiante, String idDeporte) =>
      '${idEstudiante}_$idDeporte';

  factory Resena.fromMap(Map<String, dynamic> datos) {
    final fecha = datos['fecha'];
    return Resena(
      idDeporte: datos['idDeporte'] as String? ?? '',
      idEstudiante: datos['idEstudiante'] as String? ?? '',
      nombreEstudiante: datos['nombreEstudiante'] as String? ?? '',
      calificacion: (datos['calificacion'] as num?)?.toInt() ?? 0,
      comentario: datos['comentario'] as String? ?? '',
      fecha: fecha is String
          ? DateTime.tryParse(fecha) ?? DateTime.now()
          : DateTime.now(),
      calificacionEntrenador: (datos['calificacionEntrenador'] as num?)
          ?.toInt(),
      editada: datos['editada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'idDeporte': idDeporte,
    'idEstudiante': idEstudiante,
    'nombreEstudiante': nombreEstudiante,
    'calificacion': calificacion,
    'calificacionEntrenador': ?calificacionEntrenador,
    'comentario': comentario,
    'fecha': fecha.toIso8601String(),
    'editada': editada,
  };
}
