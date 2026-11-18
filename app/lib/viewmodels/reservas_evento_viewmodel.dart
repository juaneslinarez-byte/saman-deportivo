import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/reserva_repository.dart';

enum ReservasEventoEstado { cargando, listo, error }

/// Reservas de un evento para el administrador: valida los pagos
/// aprobando o rechazando cada reserva en revisión. Rechazar devuelve los
/// cupos en la misma operación.
class ReservasEventoViewModel extends ChangeNotifier {
  ReservasEventoViewModel({
    required this._reservaRepository,
    required this.evento,
  });

  final ReservaRepository _reservaRepository;
  final Evento evento;

  List<Reserva> _reservas = const [];
  ReservasEventoEstado _estado = ReservasEventoEstado.cargando;
  EstadoReserva? _filtro = EstadoReserva.enRevision;
  final Set<String> _enProceso = {};
  StreamSubscription<List<Reserva>>? _suscripcion;

  ReservasEventoEstado get estado => _estado;
  EstadoReserva? get filtro => _filtro;
  bool enProceso(Reserva r) => _enProceso.contains(r.id);

  List<Reserva> get reservas => _filtro == null
      ? _reservas
      : _reservas.where((r) => r.estado == _filtro).toList();

  int cuantas(EstadoReserva? estado) => estado == null
      ? _reservas.length
      : _reservas.where((r) => r.estado == estado).length;

  /// Personas con la reserva aprobada.
  int get personasConfirmadas => _reservas
      .where((r) => r.estado == EstadoReserva.aprobada)
      .fold(0, (total, r) => total + r.personas);

  /// Dinero de las reservas aprobadas.
  double get montoAprobado => _reservas
      .where((r) => r.estado == EstadoReserva.aprobada)
      .fold(0.0, (total, r) => total + r.monto);

  void cargar() {
    _estado = ReservasEventoEstado.cargando;
    notifyListeners();
    _suscripcion?.cancel();
    _suscripcion = _reservaRepository
        .observarPorEvento(evento.id)
        .listen(
          (lista) {
            _reservas = lista;
            _estado = ReservasEventoEstado.listo;
            notifyListeners();
          },
          onError: (Object _) {
            _estado = ReservasEventoEstado.error;
            notifyListeners();
          },
        );
  }

  void filtrar(EstadoReserva? estado) {
    _filtro = estado;
    notifyListeners();
  }

  Future<String?> aprobar(Reserva r) =>
      _ejecutar(r, () => _reservaRepository.aprobar(r));

  Future<String?> rechazar(Reserva r) =>
      _ejecutar(r, () => _reservaRepository.rechazar(r));

  Future<String?> _ejecutar(Reserva r, Future<void> Function() accion) async {
    if (_enProceso.contains(r.id)) return null;
    _enProceso.add(r.id);
    notifyListeners();
    try {
      await accion();
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _enProceso.remove(r.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
