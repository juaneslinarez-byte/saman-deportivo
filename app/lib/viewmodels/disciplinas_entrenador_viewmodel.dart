import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga de las disciplinas del entrenador.
enum DisciplinasEntrenadorEstado { cargando, listo, error }

/// «Mis disciplinas» del entrenador: los deportes que el administrador le
/// asignó, con sus cupos y su horario (RF-ENT-01).
class DisciplinasEntrenadorViewModel extends ChangeNotifier {
  final DeporteRepository deporteRepository;
  final String idEntrenador;

  List<Deporte> _deportes = const [];
  final Map<String, List<Sesion>> _sesiones = {};
  DisciplinasEntrenadorEstado _estado = DisciplinasEntrenadorEstado.cargando;
  bool _descartado = false;

  // Patrón Observador: los cupos y los horarios llegan en vivo, por ejemplo
  // cuando un estudiante se inscribe o el administrador cambia una sesión.
  StreamSubscription<List<Deporte>>? _deportesSubscription;
  final Map<String, StreamSubscription<List<Sesion>>> _sesionesSubs = {};

  DisciplinasEntrenadorViewModel({
    required this.deporteRepository,
    required this.idEntrenador,
  });

  DisciplinasEntrenadorEstado get estado => _estado;

  /// Deportes asignados, ordenados por nombre.
  List<Deporte> get deportes => _deportes;

  /// Sesiones semanales de un deporte; vacía mientras no lleguen.
  List<Sesion> sesionesDe(String idDeporte) => _sesiones[idDeporte] ?? const [];

  /// Empieza a observar los deportes del entrenador. La pantalla la llama
  /// al abrirse, y de nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = DisciplinasEntrenadorEstado.cargando;
    _cancelarSuscripciones();
    _notificar();

    _deportesSubscription = deporteRepository
        .observarPorEntrenador(idEntrenador)
        .listen(
          (deportes) {
            _deportes = [...deportes]
              ..sort(
                (a, b) =>
                    a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
              );
            _observarSesiones();
            _estado = DisciplinasEntrenadorEstado.listo;
            _notificar();
          },
          onError: (Object _) {
            _estado = DisciplinasEntrenadorEstado.error;
            _notificar();
          },
        );
  }

  /// Observa el horario de cada deporte asignado y deja de observar los que
  /// el administrador le quitó.
  void _observarSesiones() {
    final necesarios = {for (final deporte in _deportes) deporte.id};

    for (final id in _sesionesSubs.keys.toList()) {
      if (necesarios.contains(id)) continue;
      _sesionesSubs.remove(id)?.cancel();
      _sesiones.remove(id);
    }

    for (final id in necesarios) {
      if (_sesionesSubs.containsKey(id)) continue;
      _sesionesSubs[id] = deporteRepository
          .observarSesiones(id)
          .listen(
            (sesiones) {
              _sesiones[id] = sesiones;
              _notificar();
            },
            onError: (Object _) {
              // Sin horario, la tarjeta se muestra igual con el nombre.
            },
          );
    }
  }

  void _cancelarSuscripciones() {
    _deportesSubscription?.cancel();
    for (final suscripcion in _sesionesSubs.values) {
      suscripcion.cancel();
    }
    _sesionesSubs.clear();
    _sesiones.clear();
  }

  /// Evita avisar a la pantalla cuando ya se cerró.
  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _cancelarSuscripciones();
    super.dispose();
  }
}
