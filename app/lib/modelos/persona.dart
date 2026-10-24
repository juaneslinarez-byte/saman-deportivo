import 'administrador.dart';
import 'conversiones.dart';
import 'entrenador.dart';
import 'estudiante.dart';

/// Tipo de usuario del sistema. Se guarda en el campo «actor» de cada usuario.
enum Actor { estudiante, entrenador, administrador }

/// Datos comunes a todos los usuarios del sistema.
abstract class Persona {
  const Persona({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    this.habilitado = true,
  });

  /// Fábrica simple: crea la subclase que corresponde al campo «actor».
  ///
  /// Todos los usuarios se guardan juntos, y aquí se decide si cada uno es
  /// un [Estudiante], un [Entrenador] o un [Administrador].
  factory Persona.fromMap(String id, Map<String, dynamic> datos) {
    final actor = leerEnum(Actor.values, datos['actor'], 'actor');
    return switch (actor) {
      Actor.estudiante => Estudiante.fromMap(id, datos),
      Actor.entrenador => Entrenador.fromMap(id, datos),
      Actor.administrador => Administrador.fromMap(id, datos),
    };
  }

  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String correo;

  /// Un usuario deshabilitado no puede iniciar sesión (RF-SIS-08).
  final bool habilitado;

  Actor get actor;

  String get nombreCompleto => '$nombre $apellido';

  /// Datos comunes para guardar. Cada subclase agrega los suyos.
  Map<String, dynamic> toMap() => {
    'actor': actor.name,
    'nombre': nombre,
    'apellido': apellido,
    'cedula': cedula,
    'correo': correo,
    'habilitado': habilitado,
  };
}
