import 'dart:async';

import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

import 'fake_deporte_repository.dart';

/// Repositorio de solicitudes falso: las guarda en memoria y, al aprobar
/// una, agrega al entrenador a la disciplina del [FakeDeporteRepository].
class FakeSolicitudRepository implements SolicitudRepository {
  FakeSolicitudRepository(this._deportes);

  final FakeDeporteRepository _deportes;
  final Map<String, Solicitud> _solicitudes = {};
  final StreamController<void> _cambios = StreamController<void>.broadcast();

  Solicitud? buscar(String id) => _solicitudes[id];

  @override
  Stream<List<Solicitud>> observarPorEntrenador(String idEntrenador) async* {
    List<Solicitud> lista() => _solicitudes.values
        .where((s) => s.idEntrenador == idEntrenador)
        .toList();
    yield lista();
    await for (final _ in _cambios.stream) {
      yield lista();
    }
  }

  @override
  Stream<List<Solicitud>> observarPendientes() async* {
    List<Solicitud> lista() =>
        _solicitudes.values.where((s) => s.estaPendiente).toList();
    yield lista();
    await for (final _ in _cambios.stream) {
      yield lista();
    }
  }

  @override
  Future<void> solicitar({
    required Entrenador entrenador,
    required Deporte deporte,
    String mensaje = '',
  }) async {
    if (deporte.tieneAlEntrenador(entrenador.id)) {
      throw Exception('Ya diriges esta disciplina.');
    }
    final id = Solicitud.idPara(entrenador.id, deporte.id);
    if (_solicitudes[id]?.estaPendiente ?? false) {
      throw Exception('Ya enviaste una solicitud para esta disciplina.');
    }
    _solicitudes[id] = Solicitud(
      idEntrenador: entrenador.id,
      nombreEntrenador: entrenador.nombreCompleto,
      idDeporte: deporte.id,
      nombreDeporte: deporte.nombre,
      fecha: DateTime.now(),
      mensaje: mensaje.trim(),
    );
    _cambios.add(null);
  }

  @override
  Future<void> aprobar(Solicitud solicitud) async {
    final actual = _solicitudes[solicitud.id];
    if (actual == null || !actual.estaPendiente) {
      throw Exception('Esta solicitud ya fue revisada.');
    }
    final deporte = await _deportes.obtener(solicitud.idDeporte);
    if (deporte == null) throw Exception('La disciplina ya no existe.');
    await _deportes.actualizar(
      deporte.copyWith(
        idsEntrenadores: [...deporte.idsEntrenadores, solicitud.idEntrenador],
      ),
    );
    _solicitudes[solicitud.id] = actual.copyWith(
      estado: EstadoSolicitud.aprobada,
    );
    _cambios.add(null);
  }

  @override
  Future<void> rechazar(Solicitud solicitud) async {
    final actual = _solicitudes[solicitud.id];
    if (actual == null) return;
    _solicitudes[solicitud.id] = actual.copyWith(
      estado: EstadoSolicitud.rechazada,
    );
    _cambios.add(null);
  }
}
