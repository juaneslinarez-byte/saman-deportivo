import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/solicitud_repository.dart';

enum SolicitudesAdminEstado { cargando, listo, error }

/// Solicitudes de los entrenadores para dirigir otra disciplina que esperan
/// la decisión del administrador (RF-ADM-07).
class SolicitudesAdminViewModel extends ChangeNotifier {
  SolicitudesAdminViewModel({required this._solicitudRepository});

  final SolicitudRepository _solicitudRepository;

  SolicitudesAdminEstado _estado = SolicitudesAdminEstado.cargando;
  List<Solicitud> _pendientes = [];
  final Set<String> _enProceso = {};
  StreamSubscription<List<Solicitud>>? _suscripcion;

  SolicitudesAdminEstado get estado => _estado;
  List<Solicitud> get pendientes => List.unmodifiable(_pendientes);
  bool enProceso(Solicitud solicitud) => _enProceso.contains(solicitud.id);

  void cargar() {
    _estado = SolicitudesAdminEstado.cargando;
    notifyListeners();
    _suscripcion?.cancel();
    _suscripcion = _solicitudRepository.observarPendientes().listen(
      (lista) {
        _pendientes = lista;
        _estado = SolicitudesAdminEstado.listo;
        notifyListeners();
      },
      onError: (Object _) {
        _estado = SolicitudesAdminEstado.error;
        notifyListeners();
      },
    );
  }

  /// Devuelve null si salió bien o el motivo del error.
  Future<String?> aprobar(Solicitud solicitud) =>
      _revisar(solicitud, () => _solicitudRepository.aprobar(solicitud));

  Future<String?> rechazar(Solicitud solicitud) =>
      _revisar(solicitud, () => _solicitudRepository.rechazar(solicitud));

  Future<String?> _revisar(
    Solicitud solicitud,
    Future<void> Function() accion,
  ) async {
    if (_enProceso.contains(solicitud.id)) return null;
    _enProceso.add(solicitud.id);
    notifyListeners();
    try {
      await accion();
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _enProceso.remove(solicitud.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
