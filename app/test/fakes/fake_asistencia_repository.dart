import 'dart:async';

import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Repositorio de asistencias falso: guarda los registros en memoria.
///
/// Sirve para probar ViewModels sin Firebase. Poniendo [debeFallar] en true,
/// todas las operaciones lanzan una excepción.
class FakeAsistenciaRepository implements AsistenciaRepository {
  final Map<String, Asistencia> _registros = {};
  final StreamController<void> _cambios = StreamController<void>.broadcast();

  /// Si es true, las operaciones fallan como si la base de datos no respondiera.
  bool debeFallar = false;

  /// Cantidad de registros guardados.
  int get cantidad => _registros.length;

  @override
  Future<void> registrar(List<Asistencia> asistencias) async {
    _verificarFallo();
    for (final asistencia in asistencias) {
      final id = Asistencia.idPara(
        asistencia.idInscripcion,
        asistencia.idSesion,
        asistencia.fecha,
      );
      _registros[id] = asistencia;
    }
    _cambios.add(null);
  }

  @override
  Stream<List<Asistencia>> observarPorSesion(
    String idSesion,
    DateTime fecha,
  ) async* {
    _verificarFallo();
    yield _deLaSesion(idSesion, fecha);
    await for (final _ in _cambios.stream) {
      yield _deLaSesion(idSesion, fecha);
    }
  }

  @override
  Stream<List<Asistencia>> observarPorDeporte(String idDeporte) async* {
    _verificarFallo();
    yield _delDeporte(idDeporte);
    await for (final _ in _cambios.stream) {
      yield _delDeporte(idDeporte);
    }
  }

  @override
  Stream<List<Asistencia>> observarPorEstudiante(String idEstudiante) async* {
    _verificarFallo();
    yield _delEstudiante(idEstudiante);
    await for (final _ in _cambios.stream) {
      yield _delEstudiante(idEstudiante);
    }
  }

  List<Asistencia> _deLaSesion(String idSesion, DateTime fecha) {
    return _registros.values
        .where((a) => a.idSesion == idSesion && _mismoDia(a.fecha, fecha))
        .toList();
  }

  List<Asistencia> _delDeporte(String idDeporte) {
    return _registros.values.where((a) => a.idDeporte == idDeporte).toList();
  }

  List<Asistencia> _delEstudiante(String idEstudiante) {
    return _registros.values
        .where((a) => a.idEstudiante == idEstudiante)
        .toList();
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _verificarFallo() {
    if (debeFallar) throw Exception('Error de base de datos');
  }

  /// Cierra el stream. Llamarlo en tearDown si el test lo escucha.
  Future<void> cerrar() => _cambios.close();
}
