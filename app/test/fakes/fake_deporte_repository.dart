import 'dart:async';

import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Repositorio de deportes falso: guarda deportes y sesiones en memoria.
///
/// Sirve para probar ViewModels sin Firebase. Poniendo [debeFallar] en true,
/// todas las operaciones lanzan una excepcion.
class FakeDeporteRepository implements DeporteRepository {
  final Map<String, Deporte> _deportes = {};
  final List<Sesion> _sesiones = [];
  final StreamController<void> _cambios = StreamController<void>.broadcast();

  int _contador = 0;

  /// Si es true, las operaciones fallan como si la base de datos no respondiera.
  bool debeFallar = false;

  /// Agrega un deporte ya existente, para preparar el escenario de una prueba.
  void agregar(Deporte deporte) {
    _deportes[deporte.id] = deporte;
    _cambios.add(null);
  }

  /// Agrega una sesion ya existente, para preparar el escenario de una prueba.
  void agregarSesion(Sesion sesion) {
    _sesiones.add(sesion);
    _cambios.add(null);
  }

  /// Cantidad de deportes guardados.
  int get cantidad => _deportes.length;

  @override
  Stream<List<Deporte>> observarDeportes({bool soloVisibles = true}) async* {
    _verificarFallo();
    yield _listar(soloVisibles);
    await for (final _ in _cambios.stream) {
      yield _listar(soloVisibles);
    }
  }

  @override
  Future<Deporte?> obtener(String id) async {
    _verificarFallo();
    return _deportes[id];
  }

  @override
  Stream<List<Deporte>> observarPorEntrenador(String idEntrenador) async* {
    _verificarFallo();
    yield _delEntrenador(idEntrenador);
    await for (final _ in _cambios.stream) {
      yield _delEntrenador(idEntrenador);
    }
  }

  @override
  Stream<List<Sesion>> observarSesiones(String idDeporte) async* {
    _verificarFallo();
    yield _sesionesDe(idDeporte);
    await for (final _ in _cambios.stream) {
      yield _sesionesDe(idDeporte);
    }
  }

  @override
  Future<String> crearSesion(Sesion sesion) async {
    _verificarFallo();
    final id = 's${++_contador}';
    _sesiones.add(Sesion.fromMap(id, sesion.toMap()));
    _cambios.add(null);
    return id;
  }

  @override
  Future<void> actualizarSesion(Sesion sesion) async {
    _verificarFallo();
    final indice = _sesiones.indexWhere((s) => s.id == sesion.id);
    if (indice < 0) {
      throw StateError('No existe la sesion ${sesion.id}');
    }
    _sesiones[indice] = sesion;
    _cambios.add(null);
  }

  @override
  Future<void> eliminarSesion(String idSesion) async {
    _verificarFallo();
    _sesiones.removeWhere((s) => s.id == idSesion);
    _cambios.add(null);
  }

  @override
  Future<String> crear(Deporte deporte) async {
    _verificarFallo();
    final id = 'd${++_contador}';
    _deportes[id] = Deporte.fromMap(id, deporte.toMap());
    _cambios.add(null);
    return id;
  }

  @override
  Future<void> actualizar(Deporte deporte) async {
    _verificarFallo();
    if (!_deportes.containsKey(deporte.id)) {
      throw StateError('No existe el deporte ${deporte.id}');
    }
    _deportes[deporte.id] = deporte;
    _cambios.add(null);
  }

  /// Solo elimina deportes sin inscritos activos (RF-SIS-09).
  @override
  Future<void> eliminar(String id) async {
    _verificarFallo();
    final deporte = _deportes[id];
    if (deporte == null) {
      throw StateError('No existe el deporte $id');
    }
    if (deporte.inscritos > 0) {
      throw StateError('No se puede eliminar un deporte con inscritos');
    }
    _deportes.remove(id);
    _sesiones.removeWhere((s) => s.idDeporte == id);
    _cambios.add(null);
  }

  List<Deporte> _listar(bool soloVisibles) {
    return _deportes.values.where((d) => !soloVisibles || d.visible).toList();
  }

  List<Deporte> _delEntrenador(String idEntrenador) {
    return _deportes.values
        .where((d) => d.idEntrenador == idEntrenador)
        .toList();
  }

  List<Sesion> _sesionesDe(String idDeporte) {
    return _sesiones.where((s) => s.idDeporte == idDeporte).toList();
  }

  void _verificarFallo() {
    if (debeFallar) throw Exception('Error de base de datos');
  }

  /// Cierra el stream. Llamarlo en tearDown si el test lo escucha.
  Future<void> cerrar() => _cambios.close();
}
