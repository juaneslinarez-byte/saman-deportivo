import 'persona.dart';

class Administrador extends Persona {
  const Administrador({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.cedula,
    required super.correo,
    super.habilitado,
    required this.cargo,
  });

  factory Administrador.fromMap(String id, Map<String, dynamic> datos) {
    return Administrador(
      id: id,
      nombre: datos['nombre'] as String,
      apellido: datos['apellido'] as String,
      cedula: datos['cedula'] as String,
      correo: datos['correo'] as String,
      habilitado: datos['habilitado'] as bool? ?? true,
      cargo: datos['cargo'] as String,
    );
  }

  final String cargo;

  @override
  Actor get actor => Actor.administrador;

  @override
  Map<String, dynamic> toMap() => {...super.toMap(), 'cargo': cargo};
}
