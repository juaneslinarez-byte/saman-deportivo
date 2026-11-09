import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/horarios.dart';
import '../core/rutas.dart';
import '../modelos/modelos.dart';
import '../repositorios/repositorios.dart';

enum PanelEntrenadorEstado { cargando, listo, error }

/// Resumen de una disciplina del entrenador.
class ResumenClase {
  const ResumenClase({
    required this.deporte,
    required this.inscritos,
    required this.noSolventes,
    required this.registros,
    required this.presentes,
    required this.clases,
    required this.ultimaClase,
  });

  final Deporte deporte;
  final int inscritos;
  final int noSolventes;
  final int registros;
  final int presentes;

  /// Clases distintas en las que se tomó la asistencia y la más reciente.
  final int clases;
  final DateTime? ultimaClase;

  double? get asistencia => registros == 0 ? null : presentes / registros;
}

/// Aviso del panel del entrenador, con la pantalla y la disciplina donde se
/// atiende.
class AvisoEntrenador {
  const AvisoEntrenador(this.texto, {this.ruta, this.deporte});

  final String texto;
  final String? ruta;
  final Deporte? deporte;
}

/// Panel resumen del entrenador: sus disciplinas, inscritos, asistencia,
/// próxima clase y los estudiantes que necesitan atención. Todo se observa
/// en tiempo real.
class PanelEntrenadorViewModel extends ChangeNotifier {
  PanelEntrenadorViewModel({
    required this._deporteRepository,
    required this._inscripcionRepository,
    required this._asistenciaRepository,
    required this._usuarioRepository,
    required this._idEntrenador,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final DeporteRepository _deporteRepository;
  final InscripcionRepository _inscripcionRepository;
  final AsistenciaRepository _asistenciaRepository;
  final UsuarioRepository _usuarioRepository;
  final String _idEntrenador;
  final DateTime Function() _reloj;

  /// Asistencia por debajo de la cual se avisa, con al menos
  /// [_clasesMinimas] registros para que el porcentaje signifique algo.
  static const double _asistenciaBaja = 0.6;
  static const int _clasesMinimas = 3;

  PanelEntrenadorEstado _estado = PanelEntrenadorEstado.cargando;
  List<Deporte> _deportes = [];
  final Map<String, List<Inscripcion>> _inscritos = {};
  final Map<String, List<Asistencia>> _asistencias = {};
  final Map<String, List<Sesion>> _sesiones = {};
  Map<String, Estudiante> _perfiles = {};

  StreamSubscription<List<Deporte>>? _deportesSub;
  final Map<String, List<StreamSubscription<Object?>>> _subs = {};

  PanelEntrenadorEstado get estado => _estado;

  int get totalDisciplinas => _deportes.length;

  int get totalInscritos =>
      _inscritos.values.fold(0, (total, l) => total + l.length);

  int get totalNoSolventes => _inscritos.values.fold(
    0,
    (total, l) => total + l.where(_noSolvente).length,
  );

  int get registrosAsistencia =>
      _asistencias.values.fold(0, (total, l) => total + l.length);

  double? get asistenciaGlobal {
    final total = registrosAsistencia;
    if (total == 0) return null;
    final presentes = _asistencias.values.fold<int>(
      0,
      (suma, l) => suma + l.where((a) => a.presente).length,
    );
    return presentes / total;
  }

  int get clasesTomadas => disciplinas.fold(0, (total, r) => total + r.clases);

  /// Próxima clase entre todas sus disciplinas.
  ({Deporte deporte, Sesion sesion, DateTime inicio})? get proximaClase {
    final ahora = _reloj();
    ({Deporte deporte, Sesion sesion, DateTime inicio})? proxima;
    for (final d in _deportes) {
      final p = Horarios.proximaClase(_sesiones[d.id] ?? const [], ahora);
      if (p == null) continue;
      if (proxima == null || p.inicio.isBefore(proxima.inicio)) {
        proxima = (deporte: d, sesion: p.sesion, inicio: p.inicio);
      }
    }
    return proxima;
  }

  String cuando(DateTime inicio) => Horarios.cuando(inicio, _reloj());

  List<ResumenClase> get disciplinas {
    final lista = [for (final d in _deportes) _resumen(d)];
    lista.sort((a, b) => a.deporte.nombre.compareTo(b.deporte.nombre));
    return lista;
  }

  ResumenClase _resumen(Deporte d) {
    final registros = _asistencias[d.id] ?? const <Asistencia>[];
    final inscritos = _inscritos[d.id] ?? const <Inscripcion>[];
    DateTime? ultima;
    final clases = <String>{};
    for (final a in registros) {
      clases.add('${a.idSesion}_${_dia(a.fecha)}');
      if (ultima == null || a.fecha.isAfter(ultima)) ultima = a.fecha;
    }
    return ResumenClase(
      deporte: d,
      inscritos: inscritos.length,
      noSolventes: inscritos.where(_noSolvente).length,
      registros: registros.length,
      presentes: registros.where((a) => a.presente).length,
      clases: clases.length,
      ultimaClase: ultima,
    );
  }

  /// Lo que conviene atender: estudiantes que faltan mucho, inscritos sin
  /// solvencia y clases recientes sin asistencia tomada.
  List<AvisoEntrenador> get avisos {
    final avisos = <AvisoEntrenador>[];
    final ahora = _reloj();
    for (final d in _deportes) {
      final inscritos = _inscritos[d.id] ?? const <Inscripcion>[];
      final registros = _asistencias[d.id] ?? const <Asistencia>[];

      // Hubo clase en los últimos 7 días y no se tomó la asistencia.
      final sesiones = _sesiones[d.id] ?? const <Sesion>[];
      if (inscritos.isNotEmpty && sesiones.isNotEmpty) {
        final haceUnaSemana = ahora.subtract(const Duration(days: 7));
        final tomadaReciente = registros.any(
          (a) => a.fecha.isAfter(haceUnaSemana),
        );
        if (!tomadaReciente) {
          avisos.add(
            AvisoEntrenador(
              'No has tomado la asistencia de ${d.nombre} en los últimos '
              '7 días.',
              ruta: Rutas.asistenciaEntrenador,
              deporte: d,
            ),
          );
        }
      }

      final noSolventes = inscritos.where(_noSolvente).length;
      if (noSolventes > 0) {
        avisos.add(
          AvisoEntrenador(
            noSolventes == 1
                ? '1 inscrito de ${d.nombre} no está solvente.'
                : '$noSolventes inscritos de ${d.nombre} no están solventes.',
            ruta: Rutas.nominaEntrenador,
            deporte: d,
          ),
        );
      }

      // Estudiantes con poca asistencia.
      final porInscripcion = <String, List<Asistencia>>{};
      for (final a in registros) {
        porInscripcion.putIfAbsent(a.idInscripcion, () => []).add(a);
      }
      for (final inscripcion in inscritos) {
        final suyos = porInscripcion[inscripcion.id] ?? const <Asistencia>[];
        if (suyos.length < _clasesMinimas) continue;
        final porcentaje = suyos.where((a) => a.presente).length / suyos.length;
        if (porcentaje < _asistenciaBaja) {
          avisos.add(
            AvisoEntrenador(
              '${inscripcion.nombreEstudiante} asistió al '
              '${(porcentaje * 100).round()} % de las clases de '
              '${d.nombre}.',
              ruta: Rutas.historialEntrenador,
              deporte: d,
            ),
          );
        }
      }
    }
    return avisos;
  }

  bool _noSolvente(Inscripcion i) {
    final perfil = _perfiles[i.idEstudiante];
    return perfil != null && !perfil.solvente;
  }

  static String _dia(DateTime f) => '${f.year}-${f.month}-${f.day}';

  void cargar() {
    _estado = PanelEntrenadorEstado.cargando;
    notifyListeners();
    _deportesSub?.cancel();
    _deportesSub = _deporteRepository
        .observarPorEntrenador(_idEntrenador)
        .listen(
          (lista) {
            _deportes = lista;
            _observarDetalles();
            _estado = PanelEntrenadorEstado.listo;
            notifyListeners();
          },
          onError: (Object _) {
            _estado = PanelEntrenadorEstado.error;
            notifyListeners();
          },
        );
    _cargarPerfiles();
  }

  Future<void> _cargarPerfiles() async {
    try {
      final personas = await _usuarioRepository.listar(actor: Actor.estudiante);
      _perfiles = {for (final p in personas.whereType<Estudiante>()) p.id: p};
      notifyListeners();
    } catch (_) {
      // Sin perfiles solo se pierde el dato de solvencia.
    }
  }

  void _observarDetalles() {
    final ids = {for (final d in _deportes) d.id};
    for (final id in _subs.keys.toList()) {
      if (!ids.contains(id)) {
        for (final s in _subs.remove(id)!) {
          s.cancel();
        }
        _inscritos.remove(id);
        _asistencias.remove(id);
        _sesiones.remove(id);
      }
    }
    for (final id in ids) {
      if (_subs.containsKey(id)) continue;
      _subs[id] = [
        _inscripcionRepository.observarPorDeporte(id).listen((lista) {
          _inscritos[id] = lista;
          // Un inscrito nuevo puede no estar entre los perfiles leídos.
          if (lista.any((i) => !_perfiles.containsKey(i.idEstudiante))) {
            _cargarPerfiles();
          }
          notifyListeners();
        }, onError: (Object _) {}),
        _asistenciaRepository.observarPorDeporte(id).listen((lista) {
          _asistencias[id] = lista;
          notifyListeners();
        }, onError: (Object _) {}),
        _deporteRepository.observarSesiones(id).listen((lista) {
          _sesiones[id] = lista;
          notifyListeners();
        }, onError: (Object _) {}),
      ];
    }
  }

  @override
  void dispose() {
    _deportesSub?.cancel();
    for (final lista in _subs.values) {
      for (final s in lista) {
        s.cancel();
      }
    }
    super.dispose();
  }
}
