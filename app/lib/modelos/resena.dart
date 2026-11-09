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
    this.editada = false,
  });

  final String idDeporte;
  final String idEstudiante;

  /// Copiado del perfil al publicar, porque los demás no pueden leer el
  /// perfil del estudiante.
  final String nombreEstudiante;

  /// De 1 a 5 estrellas.
  final int calificacion;
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
      editada: datos['editada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'idDeporte': idDeporte,
    'idEstudiante': idEstudiante,
    'nombreEstudiante': nombreEstudiante,
    'calificacion': calificacion,
    'comentario': comentario,
    'fecha': fecha.toIso8601String(),
    'editada': editada,
  };
}
