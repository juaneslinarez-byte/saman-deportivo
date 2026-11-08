import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/pago_repository.dart';
import '../repositorios/usuario_repository.dart';

enum PagosAdminEstado { cargando, listo, error }

/// Pagos de solvencia que esperan la revisión del administrador
/// (RF-ADM-05). Al aprobar uno, el estudiante queda solvente y ya puede
/// inscribirse; al rechazarlo, puede volver a pagar.
class PagosAdminViewModel extends ChangeNotifier {
  PagosAdminViewModel({
    required this._pagoRepository,
    required this._usuarioRepository,
  });

  final PagoRepository _pagoRepository;
  final UsuarioRepository _usuarioRepository;

  List<Pago> _pendientes = [];
  Map<String, Estudiante> _estudiantes = {};
  PagosAdminEstado _estado = PagosAdminEstado.cargando;
  final Set<String> _enProceso = {};
  StreamSubscription<List<Pago>>? _suscripcion;

  PagosAdminEstado get estado => _estado;

  /// Del más antiguo al más reciente: se atiende primero a quien pagó antes.
  List<Pago> get pendientes {
    final lista = List.of(_pendientes);
    lista.sort((a, b) => a.fecha.compareTo(b.fecha));
    return lista;
  }

  double get totalPendiente =>
      _pendientes.fold<double>(0, (total, pago) => total + pago.monto);

  bool enProceso(Pago pago) => _enProceso.contains(pago.id);

  /// Estudiante que hizo el pago, para mostrar su nombre y carnet. Es nulo
  /// si su perfil ya no existe.
  Estudiante? estudianteDe(Pago pago) => _estudiantes[pago.idEstudiante];

  Future<void> cargar() async {
    _estado = PagosAdminEstado.cargando;
    notifyListeners();
    try {
      final personas = await _usuarioRepository.listar(actor: Actor.estudiante);
      _estudiantes = {
        for (final p in personas.whereType<Estudiante>()) p.id: p,
      };
    } catch (_) {
      _estado = PagosAdminEstado.error;
      notifyListeners();
      return;
    }
    _suscripcion?.cancel();
    _suscripcion = _pagoRepository.observarPendientes().listen(
      (lista) async {
        // Si llega el pago de alguien que se registró después de abrir la
        // pantalla, se vuelven a leer los estudiantes para mostrar su nombre.
        if (lista.any((p) => !_estudiantes.containsKey(p.idEstudiante))) {
          try {
            final personas = await _usuarioRepository.listar(
              actor: Actor.estudiante,
            );
            _estudiantes = {
              for (final p in personas.whereType<Estudiante>()) p.id: p,
            };
          } catch (_) {
            // Se muestra el pago aunque falte el nombre.
          }
        }
        _pendientes = lista;
        _estado = PagosAdminEstado.listo;
        notifyListeners();
      },
      onError: (Object _) {
        _estado = PagosAdminEstado.error;
        notifyListeners();
      },
    );
  }

  /// Devuelve null si salió bien o el motivo del error.
  Future<String?> aprobar(Pago pago) =>
      _revisar(pago, () => _pagoRepository.aprobar(pago));

  Future<String?> rechazar(Pago pago) =>
      _revisar(pago, () => _pagoRepository.rechazar(pago));

  Future<String?> _revisar(Pago pago, Future<void> Function() accion) async {
    if (_enProceso.contains(pago.id)) return null;
    _enProceso.add(pago.id);
    notifyListeners();
    try {
      await accion();
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _enProceso.remove(pago.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
