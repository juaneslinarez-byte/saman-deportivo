class Resena {
  final String idDeporte;
  final String idEstudiante;
  final String nombreEstudiante;
  final int calificacion;
  final String comentario;
  final DateTime fecha;
  final bool editada;

  Resena({
    required this.idDeporte,
    required this.idEstudiante,
    required this.nombreEstudiante,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
    required this.editada,
  });

  String get id => '${idEstudiante}_$idDeporte';

  factory Resena.fromMap(Map<String, dynamic> data) {
    return Resena(
      idDeporte: data['idDeporte'] as String,
      idEstudiante: data['idEstudiante'] as String,
      nombreEstudiante: data['nombreEstudiante'] as String,
      calificacion: data['calificacion'] as int,
      comentario: data['comentario'] as String,
      fecha: DateTime.parse(data['fecha'] as String),
      editada: data['editada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idDeporte': idDeporte,
      'idEstudiante': idEstudiante,
      'nombreEstudiante': nombreEstudiante,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
      'editada': editada,
    };
  }
}
