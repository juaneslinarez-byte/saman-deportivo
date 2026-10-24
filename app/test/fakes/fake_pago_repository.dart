import 'dart:async';

import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

import 'fake_usuario_repository.dart';

/// Repositorio de pagos falso: guarda los pagos en memoria.
///
/// Recibe un [FakeUsuarioRepository] para marcar al estudiante como solvente
/// cuando se aprueba un pago (RF-SIS-07). Con [pasarelaRechaza] en true simula
/// que la pasarela de pagos no procesa el pago, y con [debeFallar] en true
/// todas las operaciones lanzan una excepcion.
class FakePagoRepository implements PagoRepository {
  FakePagoRepository(this._usuarios);

  final FakeUsuarioRepository _usuarios;
  final Map<String, Pago> _pagos = {};
  final StreamController<void> _cambios = StreamController<void>.broadcast();

  int _contador = 0;

  /// Si es true, las operaciones fallan como si la base de datos no respondiera.
  bool debeFallar = false;

  /// Si es true, la pasarela rechaza el pago y [pagar] lanza una excepcion.
  bool pasarelaRechaza = false;

  /// Agrega un pago ya existente, para preparar el escenario de una prueba.
  void agregar(Pago pago) {
    _pagos[pago.id] = pago;
    _cambios.add(null);
  }

  /// Cantidad de pagos guardados.
  int get cantidad => _pagos.length;

  /// Procesa el pago con la pasarela y lo registra como pendiente de revision.
  @override
  Future<Pago> pagar({
    required Estudiante estudiante,
    required double monto,
  }) async {
    _verificarFallo();
    if (pasarelaRechaza) {
      throw Exception('La pasarela rechazo el pago');
    }

    final numero = ++_contador;
    final pago = Pago(
      id: 'p$numero',
      idEstudiante: estudiante.id,
      monto: monto,
      fecha: DateTime.now(),
      referencia: 'REF-${numero.toString().padLeft(4, '0')}',
    );
    _pagos[pago.id] = pago;
    _cambios.add(null);
    return pago;
  }

  @override
  Stream<List<Pago>> observarPorEstudiante(String idEstudiante) async* {
    _verificarFallo();
    yield _delEstudiante(idEstudiante);
    await for (final _ in _cambios.stream) {
      yield _delEstudiante(idEstudiante);
    }
  }

  @override
  Stream<List<Pago>> observarPendientes() async* {
    _verificarFallo();
    yield _pendientes();
    await for (final _ in _cambios.stream) {
      yield _pendientes();
    }
  }

  /// Aprueba el pago y marca al estudiante como solvente (RF-ADM-05, RF-SIS-07).
  @override
  Future<void> aprobar(Pago pago) async {
    _verificarFallo();
    final guardado = _pendiente(pago.id);
    _usuarios.establecerSolvencia(guardado.idEstudiante, true);
    _pagos[guardado.id] = _conEstado(guardado, EstadoPago.aprobado);
    _cambios.add(null);
  }

  /// Rechaza el pago. El estudiante sigue sin ser solvente.
  @override
  Future<void> rechazar(Pago pago) async {
    _verificarFallo();
    final guardado = _pendiente(pago.id);
    _pagos[guardado.id] = _conEstado(guardado, EstadoPago.rechazado);
    _cambios.add(null);
  }

  /// Devuelve el pago guardado, que debe existir y seguir pendiente.
  Pago _pendiente(String id) {
    final pago = _pagos[id];
    if (pago == null) {
      throw StateError('No existe el pago $id');
    }
    if (pago.estado != EstadoPago.pendiente) {
      throw StateError('El pago $id ya fue revisado');
    }
    return pago;
  }

  List<Pago> _delEstudiante(String idEstudiante) {
    return _pagos.values.where((p) => p.idEstudiante == idEstudiante).toList();
  }

  List<Pago> _pendientes() {
    return _pagos.values
        .where((p) => p.estado == EstadoPago.pendiente)
        .toList();
  }

  Pago _conEstado(Pago p, EstadoPago estado) {
    return Pago(
      id: p.id,
      idEstudiante: p.idEstudiante,
      monto: p.monto,
      fecha: p.fecha,
      referencia: p.referencia,
      estado: estado,
    );
  }

  void _verificarFallo() {
    if (debeFallar) throw Exception('Error de base de datos');
  }

  /// Cierra el stream. Llamarlo en tearDown si el test lo escucha.
  Future<void> cerrar() => _cambios.close();
}
