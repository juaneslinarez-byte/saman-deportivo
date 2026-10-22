import 'persona.dart';

class Entrenador extends Persona {
  const Entrenador({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.cedula,
    required super.correo,
    super.habilitado,
    required this.especialidad,
  });

  factory Entrenador.fromMap(String id, Map<String, dynamic> datos) {
    return Entrenador(
      id: id,
      nombre: datos['nombre'] as String,
      apellido: datos['apellido'] as String,
      cedula: datos['cedula'] as String,
      correo: datos['correo'] as String,
      habilitado: datos['habilitado'] as bool? ?? true,
      especialidad: datos['especialidad'] as String,
    );
  }

  final String especialidad;

  @override
  Actor get actor => Actor.entrenador;

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'especialidad': especialidad,
  };
}
