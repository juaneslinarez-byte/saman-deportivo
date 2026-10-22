import 'persona.dart';

class Estudiante extends Persona {
  const Estudiante({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.cedula,
    required super.correo,
    super.habilitado,
    required this.carnet,
    required this.carrera,
    this.solvente = false,
  });

  factory Estudiante.fromMap(String id, Map<String, dynamic> datos) {
    return Estudiante(
      id: id,
      nombre: datos['nombre'] as String,
      apellido: datos['apellido'] as String,
      cedula: datos['cedula'] as String,
      correo: datos['correo'] as String,
      habilitado: datos['habilitado'] as bool? ?? true,
      carnet: datos['carnet'] as String,
      carrera: datos['carrera'] as String,
      solvente: datos['solvente'] as bool? ?? false,
    );
  }

  final String carnet;
  final String carrera;

  /// Solo un estudiante solvente puede inscribirse (RF-SIS-02). Lo actualiza
  /// el administrador al aprobar o rechazar un pago (RF-SIS-07).
  final bool solvente;

  @override
  Actor get actor => Actor.estudiante;

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'carnet': carnet,
    'carrera': carrera,
    'solvente': solvente,
  };
}
