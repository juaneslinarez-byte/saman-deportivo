import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/rutas.dart';
import '../modelos/modelos.dart';
import '../repositorios/repositorios.dart';

enum PanelAdminEstado { cargando, listo, error }

/// Datos de una disciplina para el panel: ocupación, asistencia y horario.
class ResumenDisciplina {
  const ResumenDisciplina({
    required this.deporte,
    required this.sesiones,
    required this.registros,
    required this.presentes,
    required this.clases,
  });

  final Deporte deporte;

  /// Sesiones semanales del horario.
  final int sesiones;

  /// Registros de asistencia (uno por inscrito y clase) y cuántos fueron
  /// presentes.
  final int registros;
  final int presentes;

  /// Clases distintas en las que se tomó la asistencia.
  final int clases;

  double get ocupacion =>
      deporte.cupoMaximo == 0 ? 0 : deporte.inscritos / deporte.cupoMaximo;

  /// Porcentaje de asistencia, o null si todavía no se ha tomado.
  double? get asistencia => registros == 0 ? null : presentes / registros;
}

/// Algo que el administrador debería atender, con la ruta para hacerlo.
class AlertaPanel {
  const AlertaPanel(this.texto, {this.ruta});

  final String texto;
  final String? ruta;
}

/// Panel resumen del administrador (CU-17, RF-ADM-07): cifras reales de
/// usuarios, disciplinas, inscripciones, asistencia y pagos.
///
/// Todo se calcula con los datos de Firestore y se observa en tiempo real:
/// si un estudiante se inscribe, un entrenador toma la asistencia o llega
/// un pago, el panel cambia sin recargar.
class PanelAdminViewModel extends ChangeNotifier {
  PanelAdminViewModel({
    required this._deporteRepository,
    required this._usuarioRepository,
    required this._pagoRepository,
    required this._asistenciaRepository,
  });

  final DeporteRepository _deporteRepository;
  final UsuarioRepository _usuarioRepository;
  final PagoRepository _pagoRepository;
  final AsistenciaRepository _asistenciaRepository;

  PanelAdminEstado _estado = PanelAdminEstado.cargando;
  List<Deporte> _deportes = [];
  List<Persona> _usuarios = [];
  List<Pago> _pagosPendientes = [];
  final Map<String, List<Asistencia>> _asistencias = {};
  final Map<String, int> _sesiones = {};
  DateTime? _actualizado;

  bool _cargoDeportes = false;
  bool _cargoUsuarios = false;
  bool _cargoPagos = false;

  StreamSubscription<List<Deporte>>? _deportesSub;
  StreamSubscription<List<Pago>>? _pagosSub;
  final Map<String, StreamSubscription<List<Asistencia>>> _asistenciaSubs = {};
  final Map<String, StreamSubscription<List<Sesion>>> _sesionesSubs = {};

  PanelAdminEstado get estado => _estado;
  DateTime? get actualizado => _actualizado;

  // ---------------------------------------------------------------------
  // Usuarios
  // ---------------------------------------------------------------------
  List<Estudiante> get _estudiantes =>
      _usuarios.whereType<Estudiante>().toList();

  int get totalEstudiantes => _estudiantes.length;
  int get estudiantesSolventes => _estudiantes.where((e) => e.solvente).length;
  int get estudiantesNoSolventes => totalEstudiantes - estudiantesSolventes;
  int get totalEntrenadores => _usuarios.whereType<Entrenador>().length;
  int get cuentasDeshabilitadas => _usuarios.where((u) => !u.habilitado).length;

  // ---------------------------------------------------------------------
  // Disciplinas e inscripciones
  // ---------------------------------------------------------------------
  int get totalDisciplinas => _deportes.length;
  int get disciplinasPublicadas => _deportes.where((d) => d.visible).length;
  int get inscripcionesActivas =>
      _deportes.fold(0, (total, d) => total + d.inscritos);
  int get cupoTotal => _deportes.fold(0, (total, d) => total + d.cupoMaximo);
  double get ocupacionGlobal =>
      cupoTotal == 0 ? 0 : inscripcionesActivas / cupoTotal;

  /// Disciplinas de la más llena a la más vacía.
  List<ResumenDisciplina> get disciplinas {
    final lista = [for (final d in _deportes) _resumen(d)];
    lista.sort((a, b) {
      final porOcupacion = b.ocupacion.compareTo(a.ocupacion);
      return porOcupacion != 0
          ? porOcupacion
          : a.deporte.nombre.compareTo(b.deporte.nombre);
    });
    return lista;
  }

  /// Disciplinas con asistencia tomada, de mayor a menor asistencia.
  List<ResumenDisciplina> get disciplinasConAsistencia {
    final lista = disciplinas.where((r) => r.asistencia != null).toList();
    lista.sort((a, b) => b.asistencia!.compareTo(a.asistencia!));
    return lista;
  }

  ResumenDisciplina _resumen(Deporte d) {
    final registros = _asistencias[d.id] ?? const [];
    return ResumenDisciplina(
      deporte: d,
      sesiones: _sesiones[d.id] ?? 0,
      registros: registros.length,
      presentes: registros.where((a) => a.presente).length,
      clases: {
        for (final a in registros)
          '${a.idSesion}_${a.fecha.year}${a.fecha.month}${a.fecha.day}',
      }.length,
    );
  }

  // ---------------------------------------------------------------------
  // Asistencia y pagos
  // ---------------------------------------------------------------------
  int get registrosAsistencia =>
      _asistencias.values.fold(0, (total, l) => total + l.length);

  /// Asistencia de todas las disciplinas, o null si nadie la ha tomado.
  double? get asistenciaGlobal {
    final total = registrosAsistencia;
    if (total == 0) return null;
    final presentes = _asistencias.values.fold<int>(
      0,
      (suma, l) => suma + l.where((a) => a.presente).length,
    );
    return presentes / total;
  }

  int get pagosEnRevision => _pagosPendientes.length;
  double get montoEnRevision =>
      _pagosPendientes.fold<double>(0, (total, p) => total + p.monto);

  /// Lo que conviene atender, de lo más urgente a lo menos.
  List<AlertaPanel> get alertas {
    final alertas = <AlertaPanel>[];
    if (pagosEnRevision > 0) {
      alertas.add(
        AlertaPanel(
          pagosEnRevision == 1
              ? 'Hay 1 pago de solvencia esperando revisión.'
              : 'Hay $pagosEnRevision pagos de solvencia esperando revisión.',
          ruta: Rutas.adminPagos,
        ),
      );
    }
    for (final r in disciplinas) {
      final d = r.deporte;
      if (!d.tieneEntrenador) {
        alertas.add(
          AlertaPanel(
            '${d.nombre} no tiene entrenador asignado.',
            ruta: Rutas.adminDeportes,
          ),
        );
      }
      if (r.sesiones == 0) {
        alertas.add(
          AlertaPanel(
            '${d.nombre} no tiene horario: agrégale sesiones.',
            ruta: Rutas.adminDeportes,
          ),
        );
      }
      if (d.visible && !d.hayCupo) {
        alertas.add(
          AlertaPanel(
            '${d.nombre} está llena (${d.cupoMaximo} de ${d.cupoMaximo}). '
            'Considera ampliar el cupo.',
            ruta: Rutas.adminDeportes,
          ),
        );
      }
      if (!d.visible && d.tieneEntrenador && r.sesiones > 0) {
        alertas.add(
          AlertaPanel(
            '${d.nombre} está lista pero oculta del catálogo.',
            ruta: Rutas.adminDeportes,
          ),
        );
      }
    }
    if (cuentasDeshabilitadas > 0) {
      alertas.add(
        AlertaPanel(
          cuentasDeshabilitadas == 1
              ? '1 cuenta está deshabilitada.'
              : '$cuentasDeshabilitadas cuentas están deshabilitadas.',
          ruta: Rutas.adminUsuarios,
        ),
      );
    }
    return alertas;
  }

  // ---------------------------------------------------------------------
  // Carga
  // ---------------------------------------------------------------------
  void cargar() {
    _estado = PanelAdminEstado.cargando;
    _cargoDeportes = false;
    _cargoUsuarios = false;
    _cargoPagos = false;
    notifyListeners();

    _deportesSub?.cancel();
    _deportesSub = _deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((lista) {
          _deportes = lista;
          _cargoDeportes = true;
          _observarDetalles();
          _listo();
        }, onError: (Object _) => _fallo());

    // Cuando cambian los pagos (llega uno o se aprueba), también cambia la
    // solvencia de alguien: se vuelven a leer los usuarios.
    _pagosSub?.cancel();
    _pagosSub = _pagoRepository.observarPendientes().listen((lista) {
      _pagosPendientes = lista;
      _cargoPagos = true;
      _cargarUsuarios();
    }, onError: (Object _) => _fallo());
  }

  Future<void> _cargarUsuarios() async {
    try {
      _usuarios = await _usuarioRepository.listar();
      _cargoUsuarios = true;
      _listo();
    } catch (_) {
      _fallo();
    }
  }

  /// Recarga los usuarios a mano, por si se registró alguien nuevo.
  Future<void> actualizar() => _cargarUsuarios();

  /// Observa la asistencia y el horario de cada disciplina; deja de
  /// observar las que se eliminaron.
  void _observarDetalles() {
    final ids = {for (final d in _deportes) d.id};
    for (final id in _asistenciaSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _asistenciaSubs.remove(id)?.cancel();
        _sesionesSubs.remove(id)?.cancel();
        _asistencias.remove(id);
        _sesiones.remove(id);
      }
    }
    for (final id in ids) {
      _asistenciaSubs.putIfAbsent(
        id,
        () => _asistenciaRepository.observarPorDeporte(id).listen((lista) {
          _asistencias[id] = lista;
          _listo();
        }, onError: (Object _) {}),
      );
      _sesionesSubs.putIfAbsent(
        id,
        () => _deporteRepository.observarSesiones(id).listen((lista) {
          _sesiones[id] = lista.length;
          _listo();
        }, onError: (Object _) {}),
      );
    }
  }

  void _listo() {
    if (_cargoDeportes && _cargoUsuarios && _cargoPagos) {
      _estado = PanelAdminEstado.listo;
      _actualizado = DateTime.now();
    }
    notifyListeners();
  }

  void _fallo() {
    _estado = PanelAdminEstado.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _deportesSub?.cancel();
    _pagosSub?.cancel();
    for (final s in _asistenciaSubs.values) {
      s.cancel();
    }
    for (final s in _sesionesSubs.values) {
      s.cancel();
    }
    super.dispose();
  }
}
