import 'conversiones.dart';

enum DiaSemana { lunes, martes, miercoles, jueves, viernes, sabado, domingo }

/// Horario semanal de un deporte. Un deporte puede tener varias sesiones.
class Sesion {
  const Sesion({
    required this.id,
    required this.idDeporte,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.lugar,
  });

  factory Sesion.fromMap(String id, Map<String, dynamic> datos) {
    return Sesion(
      id: id,
      idDeporte: datos['idDeporte'] as String,
      dia: leerEnum(DiaSemana.values, datos['dia'], 'dia'),
      horaInicio: datos['horaInicio'] as String,
      horaFin: datos['horaFin'] as String,
      lugar: datos['lugar'] as String,
    );
  }

  final String id;
  final String idDeporte;
  final DiaSemana dia;

  /// Horas en formato de 24 horas, por ejemplo "16:30".
  final String horaInicio;
  final String horaFin;
  final String lugar;

  Map<String, dynamic> toMap() => {
    'idDeporte': idDeporte,
    'dia': dia.name,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'lugar': lugar,
  };
}
