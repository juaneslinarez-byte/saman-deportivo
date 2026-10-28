import 'dart:async';

import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

import 'fake_deporte_repository.dart';

/// Repositorio de inscripciones falso: guarda todo en memoria.
///
/// Recibe un [FakeDeporteRepository] para descontar y devolver cupos como lo
/// hace el repositorio real (RNF-07). Poniendo [debeFallar] en true, todas las
/// operaciones lanzan una excepcion.
class FakeInscripcionRepository implements InscripcionRepository {
  FakeInscripcionRepository(this._deportes);

  final FakeDeporteRepository _deportes;
  final Map<String, Inscripcion> _inscripciones = {};
  final StreamController<void> _cambios = StreamController<void>.broadcast();

  int _contador = 0;

  /// Si es true, las operaciones fallan como si la base de datos no respondiera.
  bool debeFallar = false;

  /// Agrega una inscripcion ya existente, para preparar el escenario.
  void agregar(Inscripcion inscripcion) {
    _inscripciones[inscripcion.id] = inscripcion;
    _cambios.add(null);
  }

  /// Cantidad de inscripciones guardadas (activas y canceladas).
  int get cantidad => _inscripciones.length;

  /// Reglas de RF-SIS-01, RF-SIS-02 y RF-SIS-04, en este orden: solvencia,
  /// inscripcion duplicada y cupo.
  @override
  Future<Inscripcion> inscribir(Estudiante estudiante, Deporte deporte) async {
    _verificarFallo();

    if (!estudiante.solvente) {
      throw const InscripcionRechazada(MotivoRechazo.noSolvente);
    }

    final yaInscrito = _inscripciones.values.any(
      (i) =>
          i.idEstudiante == estudiante.id &&
          i.idDeporte == deporte.id &&
          i.estaActiva,
    );
    if (yaInscrito) {
      throw const InscripcionRechazada(MotivoRechazo.yaInscrito);
    }

    // Se usa el deporte guardado, que tiene los cupos al dia.
    final guardado = await _deportes.obtener(deporte.id);
    final actual = guardado ?? deporte;
    if (!actual.hayCupo) {
      throw const InscripcionRechazada(MotivoRechazo.sinCupo);
    }

    final inscripcion = Inscripcion(
      id: 'i${++_contador}',
      idEstudiante: estudiante.id,
      idDeporte: deporte.id,
      fecha: DateTime.now(),
    );
    _inscripciones[inscripcion.id] = inscripcion;

    if (guardado != null) {
      await _deportes.actualizar(
        _conCupos(guardado, guardado.cuposDisponibles - 1),
      );
    }
    _cambios.add(null);
    return inscripcion;
  }

  @override
  Future<void> cancelar(Inscripcion inscripcion) async {
    _verificarFallo();
    final guardada = _inscripciones[inscripcion.id];
    if (guardada == null) {
      throw StateError('No existe la inscripcion ${inscripcion.id}');
    }
    if (!guardada.estaActiva) return;

    // No se borra: queda en el historial como cancelada.
    _inscripciones[guardada.id] = Inscripcion(
      id: guardada.id,
      idEstudiante: guardada.idEstudiante,
      idDeporte: guardada.idDeporte,
      fecha: guardada.fecha,
      estado: EstadoInscripcion.cancelada,
    );

    final deporte = await _deportes.obtener(guardada.idDeporte);
    if (deporte != null && deporte.cuposDisponibles < deporte.cupoMaximo) {
      await _deportes.actualizar(
        _conCupos(deporte, deporte.cuposDisponibles + 1),
      );
    }
    _cambios.add(null);
  }

  @override
  Stream<List<Inscripcion>> observarPorEstudiante(String idEstudiante) async* {
    _verificarFallo();
    yield _delEstudiante(idEstudiante);
    await for (final _ in _cambios.stream) {
      yield _delEstudiante(idEstudiante);
    }
  }

  @override
  Stream<List<Inscripcion>> observarPorDeporte(String idDeporte) async* {
    _verificarFallo();
    yield _delDeporte(idDeporte);
    await for (final _ in _cambios.stream) {
      yield _delDeporte(idDeporte);
    }
  }

  List<Inscripcion> _delEstudiante(String idEstudiante) {
    return _inscripciones.values
        .where((i) => i.idEstudiante == idEstudiante)
        .toList();
  }

  /// Solo las activas, para la nomina del entrenador.
  List<Inscripcion> _delDeporte(String idDeporte) {
    return _inscripciones.values
        .where((i) => i.idDeporte == idDeporte && i.estaActiva)
        .toList();
  }

  Deporte _conCupos(Deporte d, int cupos) =>
      d.copyWith(cuposDisponibles: cupos);

  void _verificarFallo() {
    if (debeFallar) throw Exception('Error de base de datos');
  }

  /// Cierra el stream. Llamarlo en tearDown si el test lo escucha.
  Future<void> cerrar() => _cambios.close();
}
