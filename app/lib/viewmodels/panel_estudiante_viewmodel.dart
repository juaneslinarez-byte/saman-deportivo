import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/horarios.dart';
import '../modelos/modelos.dart';
import '../repositorios/repositorios.dart';

enum PanelEstudianteEstado { cargando, listo, error }

/// Asistencia del estudiante en una de sus disciplinas.
class MiDisciplina {
  const MiDisciplina({
    required this.inscripcion,
    required this.deporte,
    required this.sesiones,
    required this.registros,
    required this.presentes,
  });

  final Inscripcion inscripcion;

  /// Es null si la disciplina ya no existe.
  final Deporte? deporte;
  final List<Sesion> sesiones;
  final int registros;
  final int presentes;

  String get nombre => deporte?.nombre ?? 'Disciplina no disponible';
  int get faltas => registros - presentes;
  double? get asistencia => registros == 0 ? null : presentes / registros;
}

/// Panel resumen del estudiante: sus disciplinas, su asistencia y su
/// próxima clase. Todo se observa en tiempo real, así que si el entrenador
/// toma la asistencia el porcentaje cambia sin recargar.
class PanelEstudianteViewModel extends ChangeNotifier {
  PanelEstudianteViewModel({
    required this._inscripcionRepository,
    required this._asistenciaRepository,
    required this._deporteRepository,
    required this._idEstudiante,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final InscripcionRepository _inscripcionRepository;
  final AsistenciaRepository _asistenciaRepository;
  final DeporteRepository _deporteRepository;
  final String _idEstudiante;
  final DateTime Function() _reloj;

  static const double _asistenciaBaja = 0.6;
  static const int _clasesMinimas = 3;

  PanelEstudianteEstado _estado = PanelEstudianteEstado.cargando;
  List<Inscripcion> _inscripciones = [];
  List<Asistencia> _asistencias = [];
  Map<String, Deporte> _deportes = {};
  final Map<String, List<Sesion>> _sesiones = {};
  bool _cargoInscripciones = false;
  bool _cargoAsistencia = false;
  bool _cargoDeportes = false;

  StreamSubscription<List<Inscripcion>>? _inscripcionesSub;
  StreamSubscription<List<Asistencia>>? _asistenciaSub;
  StreamSubscription<List<Deporte>>? _deportesSub;
  final Map<String, StreamSubscription<List<Sesion>>> _sesionesSubs = {};

  PanelEstudianteEstado get estado => _estado;

  List<Inscripcion> get _activas =>
      _inscripciones.where((i) => i.estaActiva).toList();

  /// Disciplinas en las que está inscrito, por nombre.
  List<MiDisciplina> get disciplinas {
    final lista = [
      for (final i in _activas)
        () {
          final suyas = _asistencias.where((a) => a.idInscripcion == i.id);
          return MiDisciplina(
            inscripcion: i,
            deporte: _deportes[i.idDeporte],
            sesiones: _sesiones[i.idDeporte] ?? const [],
            registros: suyas.length,
            presentes: suyas.where((a) => a.presente).length,
          );
        }(),
    ];
    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  int get totalActivas => _activas.length;

  /// Asistencia en todas sus disciplinas, incluidas las que ya canceló.
  double? get asistenciaGlobal {
    if (_asistencias.isEmpty) return null;
    return _asistencias.where((a) => a.presente).length / _asistencias.length;
  }

  int get clasesRegistradas => _asistencias.length;
  int get faltas => _asistencias.where((a) => !a.presente).length;

  /// Próxima clase entre sus disciplinas activas.
  ({String disciplina, Sesion sesion, DateTime inicio})? get proximaClase {
    final ahora = _reloj();
    ({String disciplina, Sesion sesion, DateTime inicio})? proxima;
    for (final d in disciplinas) {
      final p = Horarios.proximaClase(d.sesiones, ahora);
      if (p == null) continue;
      if (proxima == null || p.inicio.isBefore(proxima.inicio)) {
        proxima = (disciplina: d.nombre, sesion: p.sesion, inicio: p.inicio);
      }
    }
    return proxima;
  }

  String cuando(DateTime inicio) => Horarios.cuando(inicio, _reloj());

  /// Disciplinas en las que falta mucho, para avisarle.
  List<MiDisciplina> get conPocaAsistencia => [
    for (final d in disciplinas)
      if (d.registros >= _clasesMinimas && d.asistencia! < _asistenciaBaja) d,
  ];

  void cargar() {
    _estado = PanelEstudianteEstado.cargando;
    notifyListeners();

    _inscripcionesSub?.cancel();
    _inscripcionesSub = _inscripcionRepository
        .observarPorEstudiante(_idEstudiante)
        .listen((lista) {
          _inscripciones = lista;
          _cargoInscripciones = true;
          _observarSesiones();
          _listo();
        }, onError: (Object _) => _fallo());

    _asistenciaSub?.cancel();
    _asistenciaSub = _asistenciaRepository
        .observarPorEstudiante(_idEstudiante)
        .listen((lista) {
          _asistencias = lista;
          _cargoAsistencia = true;
          _listo();
        }, onError: (Object _) => _fallo());

    _deportesSub?.cancel();
    _deportesSub = _deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((lista) {
          _deportes = {for (final d in lista) d.id: d};
          _cargoDeportes = true;
          _listo();
        }, onError: (Object _) => _fallo());
  }

  void _observarSesiones() {
    final ids = {for (final i in _activas) i.idDeporte};
    for (final id in _sesionesSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _sesionesSubs.remove(id)?.cancel();
        _sesiones.remove(id);
      }
    }
    for (final id in ids) {
      _sesionesSubs.putIfAbsent(
        id,
        () => _deporteRepository.observarSesiones(id).listen((lista) {
          _sesiones[id] = lista;
          notifyListeners();
        }, onError: (Object _) {}),
      );
    }
  }

  void _listo() {
    if (_cargoInscripciones && _cargoAsistencia && _cargoDeportes) {
      _estado = PanelEstudianteEstado.listo;
    }
    notifyListeners();
  }

  void _fallo() {
    _estado = PanelEstudianteEstado.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _inscripcionesSub?.cancel();
    _asistenciaSub?.cancel();
    _deportesSub?.cancel();
    for (final s in _sesionesSubs.values) {
      s.cancel();
    }
    super.dispose();
  }
}
