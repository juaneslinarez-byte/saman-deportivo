import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga de «Mis disciplinas».
enum MisInscripcionesEstado { cargando, listo, error }

/// Una inscripción junto con los datos de su disciplina.
class InscripcionConDeporte {
  const InscripcionConDeporte({
    required this.inscripcion,
    required this.deporte,
    required this.sesiones,
  });

  final Inscripcion inscripcion;

  /// `null` si la disciplina ya no existe.
  final Deporte? deporte;
  final List<Sesion> sesiones;

  String get nombre => deporte?.nombre ?? 'Disciplina no disponible';
  String get lugar => deporte?.lugar ?? '';
}

/// «Mis disciplinas» del estudiante: sus inscripciones activas, su historial
/// y la cancelación (CU-04, RF-EST-05).
///
/// Cancelar devuelve el cupo en la misma operación; eso lo hace el
/// repositorio (RNF-07).
class MisInscripcionesViewModel extends ChangeNotifier {
  final InscripcionRepository inscripcionRepository;
  final DeporteRepository deporteRepository;
  final String idEstudiante;

  List<Inscripcion> _inscripciones = const [];
  Map<String, Deporte> _deportes = const {};
  final Map<String, List<Sesion>> _sesiones = {};
  MisInscripcionesEstado _estado = MisInscripcionesEstado.cargando;
  bool _inscripcionesListas = false;
  bool _deportesListos = false;
  String? _idProcesando;
  String? _error;
  String? _mensaje;
  bool _descartado = false;

  // Patrón Observador: la lista, los cupos y los horarios llegan en vivo.
  StreamSubscription<List<Inscripcion>>? _inscripcionesSubscription;
  StreamSubscription<List<Deporte>>? _deportesSubscription;
  final Map<String, StreamSubscription<List<Sesion>>> _sesionesSubs = {};

  MisInscripcionesViewModel({
    required this.inscripcionRepository,
    required this.deporteRepository,
    required this.idEstudiante,
  });

  MisInscripcionesEstado get estado => _estado;
  bool get procesando => _idProcesando != null;

  /// Motivo del último fallo al cancelar. La pantalla lo muestra al terminar
  /// [cancelar].
  String? get error => _error;

  /// Aviso de la última cancelación exitosa.
  String? get mensaje => _mensaje;

  /// Si se está cancelando justo esta inscripción (para su botón).
  bool estaCancelando(Inscripcion inscripcion) =>
      _idProcesando == inscripcion.id;

  /// Inscripciones activas, las más recientes primero.
  List<InscripcionConDeporte> get activas => _armar(soloActivas: true);

  /// Inscripciones canceladas, las más recientes primero.
  List<InscripcionConDeporte> get historial => _armar(soloActivas: false);

  List<InscripcionConDeporte> _armar({required bool soloActivas}) {
    final lista = [
      for (final inscripcion in _inscripciones)
        if (inscripcion.estaActiva == soloActivas)
          InscripcionConDeporte(
            inscripcion: inscripcion,
            deporte: _deportes[inscripcion.idDeporte],
            sesiones: _sesiones[inscripcion.idDeporte] ?? const [],
          ),
    ];
    lista.sort((a, b) => b.inscripcion.fecha.compareTo(a.inscripcion.fecha));
    return lista;
  }

  /// Empieza a observar las inscripciones y los deportes. La pantalla la
  /// llama al abrirse, y de nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = MisInscripcionesEstado.cargando;
    _inscripcionesListas = false;
    _deportesListos = false;
    _cancelarSuscripciones();

    _inscripcionesSubscription = inscripcionRepository
        .observarPorEstudiante(idEstudiante)
        .listen((inscripciones) {
          _inscripciones = inscripciones;
          _inscripcionesListas = true;
          _observarSesiones();
          _actualizarEstado();
        }, onError: (Object _) => _fallar());

    // Se piden también los deportes ocultos: una inscripción no debe perder
    // su nombre porque el administrador oculte la disciplina.
    _deportesSubscription = deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((deportes) {
          _deportes = {for (final deporte in deportes) deporte.id: deporte};
          _deportesListos = true;
          _actualizarEstado();
        }, onError: (Object _) => _fallar());
  }

  /// Observa el horario de cada disciplina activa; las canceladas solo
  /// muestran el nombre.
  void _observarSesiones() {
    final necesarias = {
      for (final inscripcion in _inscripciones)
        if (inscripcion.estaActiva) inscripcion.idDeporte,
    };

    for (final id in _sesionesSubs.keys.toList()) {
      if (necesarias.contains(id)) continue;
      _sesionesSubs.remove(id)?.cancel();
      _sesiones.remove(id);
    }

    for (final id in necesarias) {
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

  /// Cancela la inscripción y devuelve el cupo. Devuelve `true` si se
  /// canceló; si no, deja el motivo en [error].
  Future<bool> cancelar(Inscripcion inscripcion) async {
    // Evita el doble toque mientras se procesa.
    if (procesando) return false;

    _idProcesando = inscripcion.id;
    _error = null;
    _mensaje = null;
    _notificar();

    try {
      await inscripcionRepository.cancelar(inscripcion);
      final nombre = _deportes[inscripcion.idDeporte]?.nombre;
      _mensaje = nombre == null
          ? 'Cancelaste tu inscripción.'
          : 'Cancelaste tu inscripción en $nombre.';
      return true;
    } catch (_) {
      _error = 'No se pudo cancelar la inscripción. Intenta de nuevo.';
      return false;
    } finally {
      _idProcesando = null;
      _notificar();
    }
  }

  void _actualizarEstado() {
    if (_estado != MisInscripcionesEstado.error &&
        _inscripcionesListas &&
        _deportesListos) {
      _estado = MisInscripcionesEstado.listo;
    }
    _notificar();
  }

  void _fallar() {
    _estado = MisInscripcionesEstado.error;
    _notificar();
  }

  void _cancelarSuscripciones() {
    _inscripcionesSubscription?.cancel();
    _deportesSubscription?.cancel();
    for (final suscripcion in _sesionesSubs.values) {
      suscripcion.cancel();
    }
    _sesionesSubs.clear();
    _sesiones.clear();
  }

  /// Evita avisar a la pantalla cuando ya se cerró (por ejemplo, si la
  /// cancelación termina después de que el usuario salió).
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
