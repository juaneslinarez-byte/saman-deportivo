import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga del historial.
enum HistorialEstado { cargando, listo, error }

/// Una clase del historial: una sesión en una fecha.
class ClaseHistorial {
  const ClaseHistorial({
    required this.idSesion,
    required this.fecha,
    required this.sesion,
    required this.presentes,
    required this.total,
  });

  final String idSesion;
  final DateTime fecha;

  /// Null si el administrador eliminó la sesión después de la clase.
  final Sesion? sesion;
  final int presentes;
  final int total;
}

/// La asistencia de un estudiante en todas las clases registradas.
class AsistenciaDeEstudiante {
  const AsistenciaDeEstudiante({
    required this.idEstudiante,
    required this.nombre,
    required this.carnet,
    required this.activo,
    required this.presentes,
    required this.total,
  });

  final String idEstudiante;
  final String nombre;
  final String carnet;

  /// Si sigue inscrito; quien canceló conserva su historial.
  final bool activo;
  final int presentes;
  final int total;

  /// De 0 a 100, redondeado.
  int get porcentaje => total == 0 ? 0 : (presentes * 100 / total).round();
}

/// Historial de asistencia de una disciplina para su entrenador (RF-ENT-04):
/// las clases registradas, de la más reciente a la más antigua, y el
/// porcentaje de asistencia de cada estudiante.
class HistorialAsistenciaViewModel extends ChangeNotifier {
  final AsistenciaRepository asistenciaRepository;
  final InscripcionRepository inscripcionRepository;
  final DeporteRepository deporteRepository;
  final UsuarioRepository usuarioRepository;
  final String idDeporte;

  HistorialAsistenciaViewModel({
    required this.asistenciaRepository,
    required this.inscripcionRepository,
    required this.deporteRepository,
    required this.usuarioRepository,
    required this.idDeporte,
  });

  HistorialEstado _estado = HistorialEstado.cargando;
  List<Asistencia> _registros = const [];
  Map<String, Inscripcion> _inscritosPorEstudiante = const {};
  Map<String, Sesion> _sesionesPorId = const {};
  final Map<String, Persona?> _perfiles = {};
  bool _registrosListos = false;
  bool _inscritosListos = false;
  bool _sesionesListas = false;
  bool _descartado = false;

  List<ClaseHistorial> _clases = const [];
  List<AsistenciaDeEstudiante> _estudiantes = const [];

  // Patrón Observador: si el entrenador corrige una clase, el historial se
  // actualiza solo.
  StreamSubscription<List<Asistencia>>? _registrosSubscription;
  StreamSubscription<List<Inscripcion>>? _inscritosSubscription;
  StreamSubscription<List<Sesion>>? _sesionesSubscription;
  final Map<String, StreamSubscription<Persona?>> _perfilesSubs = {};

  HistorialEstado get estado => _estado;

  /// Clases registradas, de la más reciente a la más antigua.
  List<ClaseHistorial> get clases => _clases;

  /// Estudiantes con al menos un registro, ordenados por nombre.
  List<AsistenciaDeEstudiante> get estudiantes => _estudiantes;

  /// Asistencia de todas las clases juntas, de 0 a 100.
  int get porcentajeGeneral {
    if (_registros.isEmpty) return 0;
    final presentes = _registros.where((r) => r.presente).length;
    return (presentes * 100 / _registros.length).round();
  }

  /// Empieza a observar el historial. La pantalla la llama al abrirse, y de
  /// nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = HistorialEstado.cargando;
    _registrosListos = false;
    _inscritosListos = false;
    _sesionesListas = false;
    _cancelarSuscripciones();
    _notificar();

    _registrosSubscription = asistenciaRepository
        .observarPorDeporte(idDeporte)
        .listen((registros) {
          _registros = registros;
          _registrosListos = true;
          _observarPerfilesFaltantes();
          _recalcular();
        }, onError: _alFallar);

    _inscritosSubscription = inscripcionRepository
        .observarPorDeporte(idDeporte)
        .listen((inscripciones) {
          _inscritosPorEstudiante = {
            for (final inscripcion in inscripciones)
              if (inscripcion.estaActiva) inscripcion.idEstudiante: inscripcion,
          };
          _inscritosListos = true;
          _observarPerfilesFaltantes();
          _recalcular();
        }, onError: _alFallar);

    _sesionesSubscription = deporteRepository
        .observarSesiones(idDeporte)
        .listen((sesiones) {
          _sesionesPorId = {for (final sesion in sesiones) sesion.id: sesion};
          _sesionesListas = true;
          _recalcular();
        }, onError: _alFallar);
  }

  void _alFallar(Object _) {
    _estado = HistorialEstado.error;
    _notificar();
  }

  /// Quien canceló su inscripción ya no sale en las inscripciones activas;
  /// su nombre se toma del perfil para no mostrar un historial sin nombre.
  void _observarPerfilesFaltantes() {
    if (!_inscritosListos) return;
    final faltantes = {
      for (final registro in _registros)
        if (!_inscritosPorEstudiante.containsKey(registro.idEstudiante))
          registro.idEstudiante,
    };
    for (final id in faltantes) {
      if (_perfilesSubs.containsKey(id)) continue;
      _perfilesSubs[id] = usuarioRepository
          .observar(id)
          .listen(
            (persona) {
              _perfiles[id] = persona;
              _recalcular();
            },
            onError: (Object _) {
              // Se muestra igual, con un nombre genérico.
            },
          );
    }
  }

  void _recalcular() {
    if (!_registrosListos || !_inscritosListos || !_sesionesListas) return;
    _clases = _agruparPorClase();
    _estudiantes = _agruparPorEstudiante();
    _estado = HistorialEstado.listo;
    _notificar();
  }

  List<ClaseHistorial> _agruparPorClase() {
    final grupos = <String, List<Asistencia>>{};
    for (final registro in _registros) {
      final fecha = _soloDia(registro.fecha);
      grupos
          .putIfAbsent(
            '${registro.idSesion}|${fecha.toIso8601String()}',
            () => [],
          )
          .add(registro);
    }

    final clases = [
      for (final grupo in grupos.values)
        ClaseHistorial(
          idSesion: grupo.first.idSesion,
          fecha: _soloDia(grupo.first.fecha),
          sesion: _sesionesPorId[grupo.first.idSesion],
          presentes: grupo.where((r) => r.presente).length,
          total: grupo.length,
        ),
    ];
    // La más reciente primero; el mismo día, por hora de inicio.
    clases.sort((a, b) {
      final porFecha = b.fecha.compareTo(a.fecha);
      if (porFecha != 0) return porFecha;
      return (a.sesion?.horaInicio ?? '').compareTo(b.sesion?.horaInicio ?? '');
    });
    return clases;
  }

  List<AsistenciaDeEstudiante> _agruparPorEstudiante() {
    final grupos = <String, List<Asistencia>>{};
    for (final registro in _registros) {
      grupos.putIfAbsent(registro.idEstudiante, () => []).add(registro);
    }

    final estudiantes = [
      for (final MapEntry(key: id, value: registros) in grupos.entries)
        AsistenciaDeEstudiante(
          idEstudiante: id,
          nombre: _nombreDe(id),
          carnet: _carnetDe(id),
          activo: _inscritosPorEstudiante.containsKey(id),
          presentes: registros.where((r) => r.presente).length,
          total: registros.length,
        ),
    ];
    estudiantes.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return estudiantes;
  }

  String _nombreDe(String idEstudiante) {
    final copiado = _inscritosPorEstudiante[idEstudiante]?.nombreEstudiante;
    if (copiado != null && copiado.trim().isNotEmpty) return copiado;
    return _perfiles[idEstudiante]?.nombreCompleto ?? 'Estudiante';
  }

  String _carnetDe(String idEstudiante) {
    final copiado = _inscritosPorEstudiante[idEstudiante]?.carnetEstudiante;
    if (copiado != null && copiado.isNotEmpty) return copiado;
    final perfil = _perfiles[idEstudiante];
    return perfil is Estudiante ? perfil.carnet : '';
  }

  DateTime _soloDia(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  void _cancelarSuscripciones() {
    _registrosSubscription?.cancel();
    _inscritosSubscription?.cancel();
    _sesionesSubscription?.cancel();
    for (final suscripcion in _perfilesSubs.values) {
      suscripcion.cancel();
    }
    _perfilesSubs.clear();
    _perfiles.clear();
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
