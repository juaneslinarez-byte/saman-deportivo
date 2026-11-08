import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/mensajes.dart';
import '../core/solvencia.dart';
import '../modelos/modelos.dart';
import '../repositorios/pago_repository.dart';

enum SolvenciaEstado { cargando, listo, error }

/// Situación de la solvencia del estudiante y su pago (RF-EST-08).
///
/// El estudiante paga con la pasarela (simulada por ahora) y el pago queda
/// en revisión. Mientras haya uno pendiente no puede pagar otra vez, y si
/// ya está solvente no necesita pagar. Los pagos se observan en tiempo
/// real: cuando el administrador aprueba o rechaza, la pantalla cambia sola.
class SolvenciaViewModel extends ChangeNotifier {
  SolvenciaViewModel({
    required this._pagoRepository,
    required this._idEstudiante,
  });

  final PagoRepository _pagoRepository;
  final String _idEstudiante;

  List<Pago> _pagos = [];
  SolvenciaEstado _estado = SolvenciaEstado.cargando;
  bool _pagando = false;
  String? _error;
  StreamSubscription<List<Pago>>? _suscripcion;

  SolvenciaEstado get estado => _estado;
  bool get pagando => _pagando;
  String? get error => _error;
  double get monto => Solvencia.monto;

  /// Pagos del estudiante, del más reciente al más antiguo.
  List<Pago> get pagos {
    final lista = List.of(_pagos);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  /// Pago que espera la revisión del administrador, si lo hay.
  Pago? get pagoEnRevision {
    for (final pago in pagos) {
      if (pago.estado == EstadoPago.pendiente) return pago;
    }
    return null;
  }

  /// El último pago revisado fue rechazado: se le avisa al estudiante para
  /// que vuelva a intentarlo.
  bool get ultimoRechazado {
    final lista = pagos;
    return lista.isNotEmpty && lista.first.estado == EstadoPago.rechazado;
  }

  /// Motivo por el que no puede pagar ahora, o null si puede.
  String? motivoParaNoPagar(Persona? perfil) {
    if (perfil is! Estudiante) return 'No se encontró tu perfil de estudiante.';
    if (!perfil.habilitado) return 'Tu cuenta está deshabilitada.';
    if (perfil.solvente) return 'Ya estás solvente. No necesitas pagar.';
    if (pagoEnRevision != null) {
      return 'Tu pago está en revisión. Espera la respuesta del '
          'administrador.';
    }
    return null;
  }

  void cargar() {
    _estado = SolvenciaEstado.cargando;
    notifyListeners();
    _suscripcion?.cancel();
    _suscripcion = _pagoRepository
        .observarPorEstudiante(_idEstudiante)
        .listen(
          (lista) {
            _pagos = lista;
            _estado = SolvenciaEstado.listo;
            notifyListeners();
          },
          onError: (Object _) {
            _estado = SolvenciaEstado.error;
            notifyListeners();
          },
        );
  }

  /// Procesa el pago con la pasarela. Devuelve el pago registrado, o null
  /// si no se pudo (el motivo queda en [error]).
  Future<Pago?> pagar(Persona? perfil) async {
    if (_pagando) return null;
    final motivo = motivoParaNoPagar(perfil);
    if (motivo != null) {
      _error = motivo;
      notifyListeners();
      return null;
    }
    _pagando = true;
    _error = null;
    notifyListeners();
    try {
      return await _pagoRepository.pagar(
        estudiante: perfil! as Estudiante,
        monto: Solvencia.monto,
      );
    } catch (e) {
      _error = mensajeDeError(
        e,
        porDefecto:
            'No se pudo procesar el pago. Revisa tu conexión e inténtalo '
            'de nuevo; no se hizo ningún cobro.',
      );
      return null;
    } finally {
      _pagando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
