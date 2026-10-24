import 'dart:async';

import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Repositorio de usuarios falso: guarda los perfiles en memoria.
///
/// Sirve para probar ViewModels sin Firebase. Poniendo [debeFallar] en true,
/// todas las operaciones lanzan una excepcion.
class FakeUsuarioRepository implements UsuarioRepository {
  final Map<String, Persona> _perfiles = {};
  final StreamController<MapEntry<String, Persona?>> _cambios =
      StreamController<MapEntry<String, Persona?>>.broadcast();

  /// Si es true, las operaciones fallan como si la base de datos no respondiera.
  bool debeFallar = false;

  /// Agrega un perfil ya existente, para preparar el escenario de una prueba.
  void agregar(Persona persona) {
    _perfiles[persona.id] = persona;
  }

  /// Cantidad de perfiles guardados.
  int get cantidad => _perfiles.length;

  /// Cambia la solvencia de un estudiante, como lo hace el administrador al
  /// aprobar un pago (RF-SIS-07). No usa [actualizarPerfil] porque ese metodo
  /// no puede modificarla.
  void establecerSolvencia(String id, bool solvente) {
    final actual = _perfiles[id];
    if (actual is! Estudiante) {
      throw StateError('No existe el estudiante $id');
    }
    final nuevo = Estudiante(
      id: actual.id,
      nombre: actual.nombre,
      apellido: actual.apellido,
      cedula: actual.cedula,
      correo: actual.correo,
      habilitado: actual.habilitado,
      carnet: actual.carnet,
      carrera: actual.carrera,
      solvente: solvente,
    );
    _perfiles[id] = nuevo;
    _cambios.add(MapEntry(id, nuevo));
  }

  @override
  Future<Persona?> obtener(String id) async {
    _verificarFallo();
    return _perfiles[id];
  }

  @override
  Stream<Persona?> observar(String id) async* {
    _verificarFallo();
    yield _perfiles[id];
    yield* _cambios.stream.where((e) => e.key == id).map((e) => e.value);
  }

  @override
  Future<void> crear(Persona persona) async {
    _verificarFallo();
    _perfiles[persona.id] = persona;
    _cambios.add(MapEntry(persona.id, persona));
  }

  @override
  Future<void> actualizarPerfil(Persona persona) async {
    _verificarFallo();
    final actual = _perfiles[persona.id];
    if (actual == null) {
      throw StateError('No existe el perfil ${persona.id}');
    }
    if (actual.actor != persona.actor) {
      throw StateError('No se puede cambiar el actor de un usuario');
    }

    // La solvencia solo la cambia el administrador (RF-SIS-07): se conserva
    // la que ya tenia el estudiante.
    Persona guardado = persona;
    if (actual is Estudiante && persona is Estudiante) {
      guardado = Estudiante(
        id: persona.id,
        nombre: persona.nombre,
        apellido: persona.apellido,
        cedula: persona.cedula,
        correo: persona.correo,
        habilitado: persona.habilitado,
        carnet: persona.carnet,
        carrera: persona.carrera,
        solvente: actual.solvente,
      );
    }

    _perfiles[persona.id] = guardado;
    _cambios.add(MapEntry(persona.id, guardado));
  }

  @override
  Future<List<Persona>> listar({Actor? actor}) async {
    _verificarFallo();
    return _perfiles.values
        .where((p) => actor == null || p.actor == actor)
        .toList();
  }

  void _verificarFallo() {
    if (debeFallar) throw Exception('Error de base de datos');
  }

  /// Cierra el stream. Llamarlo en tearDown si el test lo escucha.
  Future<void> cerrar() => _cambios.close();
}
