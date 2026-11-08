import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/core/horarios.dart';
import 'package:saman_deportivo/core/validadores.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga de las sesiones y de los inscritos.
enum TomarAsistenciaEstado { cargando, listo, error }

/// Tomar la asistencia de una clase (RF-ENT-03, CU-07).
///
/// El entrenador elige la sesión y la fecha, marca a los presentes y guarda
/// toda la lista en una sola operación. Si esa clase ya tenía asistencia, se
/// precarga para corregirla: el id de cada registro es fijo
/// ([Asistencia.idPara]), así que guardar de nuevo corrige y no duplica.
///
/// Una clase nueva empieza con todos ausentes, para no dar por presente a
/// alguien que no vino.
class TomarAsistenciaViewModel extends ChangeNotifier {
  final DeporteRepository deporteRepository;
  final InscripcionRepository inscripcionRepository;
  final AsistenciaRepository asistenciaRepository;
  final Deporte deporte;

  /// Hoy; se puede cambiar para probar con otra fecha.
  final DateTime Function() _reloj;

  /// Cuántas semanas hacia atrás se ofrecen para elegir la fecha.
  static const int semanasAtras = 16;

  TomarAsistenciaViewModel({
    required this.deporteRepository,
    required this.inscripcionRepository,
    required this.asistenciaRepository,
    required this.deporte,
    this.idSesionInicial,
    this.fechaInicial,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  /// La clase que se abre al venir del historial, para corregirla.
  final String? idSesionInicial;
  final DateTime? fechaInicial;

  TomarAsistenciaEstado _estado = TomarAsistenciaEstado.cargando;
  List<Sesion> _sesiones = const [];
  List<Inscripcion> _inscritos = const [];
  bool _sesionesListas = false;
  bool _inscritosListos = false;

  Sesion? _sesion;
  DateTime? _fecha;

  /// Lo que se ve en pantalla, lo último guardado y quiénes ya tienen
  /// registro en esta clase.
  final Map<String, bool> _marcas = {};
  final Map<String, bool> _guardado = {};
  final Set<String> _conRegistro = {};
  bool _cargandoRegistro = false;
  bool _tocado = false;

  bool _guardando = false;
  bool _guardadoConExito = false;
  String? _error;
  bool _descartado = false;

  StreamSubscription<List<Sesion>>? _sesionesSubscription;
  StreamSubscription<List<Inscripcion>>? _inscritosSubscription;
  StreamSubscription<List<Asistencia>>? _registroSubscription;

  TomarAsistenciaEstado get estado => _estado;

  /// Sesiones semanales, de lunes a domingo y por hora.
  List<Sesion> get sesiones => _sesiones;

  /// Inscritos activos, ordenados por nombre.
  List<Inscripcion> get inscritos => _inscritos;

  Sesion? get sesion => _sesion;
  DateTime? get fecha => _fecha;

  /// Mensaje si la fecha no sirve para la sesión elegida.
  String? get errorFecha => _sesion == null
      ? null
      : Validadores.fechaDeClase(_fecha, _sesion!.dia, hoy: _reloj());

  /// Las fechas que se pueden elegir: las últimas en que tocó esta sesión,
  /// de la más reciente a la más antigua. Nunca hay fechas futuras.
  List<DateTime> get fechasDisponibles {
    final sesion = _sesion;
    if (sesion == null) return const [];
    final ahora = _reloj();
    var dia = DateTime(ahora.year, ahora.month, ahora.day);
    while (Horarios.diaDe(dia) != sesion.dia) {
      dia = DateTime(dia.year, dia.month, dia.day - 1);
    }
    final fechas = [
      for (var semana = 0; semana < semanasAtras; semana++)
        DateTime(dia.year, dia.month, dia.day - 7 * semana),
    ];
    // Una clase más antigua abierta desde el historial también se ofrece.
    final elegida = _fecha;
    if (elegida != null &&
        Validadores.fechaDeClase(elegida, sesion.dia, hoy: ahora) == null &&
        !fechas.contains(elegida)) {
      fechas.add(elegida);
    }
    return fechas;
  }

  bool get cargandoRegistro => _cargandoRegistro;

  /// Si esta clase ya tenía asistencia guardada.
  bool get yaRegistrada => _conRegistro.isNotEmpty;

  bool get guardando => _guardando;
  bool get guardadoConExito => _guardadoConExito;
  String? get error => _error;

  bool presente(String idInscripcion) => _marcas[idInscripcion] ?? false;

  int get presentes => _inscritos.where((i) => presente(i.id)).length;

  /// «12 de 15 presentes».
  String get resumen => '$presentes de ${_inscritos.length} presentes';

  /// Cambios que todavía no se guardaron.
  bool get hayCambios => _inscritos.any(
    (i) => !_conRegistro.contains(i.id) || presente(i.id) != _guardado[i.id],
  );

  /// Solo se guarda una clase válida, con inscritos y algo nuevo que guardar.
  bool get puedeGuardar =>
      _sesion != null &&
      errorFecha == null &&
      _inscritos.isNotEmpty &&
      !_cargandoRegistro &&
      !_guardando &&
      hayCambios;

  /// Hay marcas sin guardar que se perderían al salir.
  bool get hayMarcasSinGuardar => _tocado && hayCambios;

  /// Empieza a observar las sesiones y los inscritos. La pantalla la llama
  /// al abrirse, y de nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = TomarAsistenciaEstado.cargando;
    _sesionesListas = false;
    _inscritosListos = false;
    _sesionesSubscription?.cancel();
    _inscritosSubscription?.cancel();
    _notificar();

    _sesionesSubscription = deporteRepository
        .observarSesiones(deporte.id)
        .listen(_alLlegarSesiones, onError: _alFallarCarga);

    _inscritosSubscription = inscripcionRepository
        .observarPorDeporte(deporte.id)
        .listen(_alLlegarInscritos, onError: _alFallarCarga);
  }

  void _alLlegarSesiones(List<Sesion> sesiones) {
    _sesiones = [...sesiones]
      ..sort((a, b) {
        final porDia = a.dia.index.compareTo(b.dia.index);
        return porDia != 0 ? porDia : a.horaInicio.compareTo(b.horaInicio);
      });
    _sesionesListas = true;

    final actual = _sesion;
    if (actual != null) {
      // Si el administrador eliminó la sesión elegida, se vuelve a elegir.
      final sigue = _sesiones.where((s) => s.id == actual.id);
      if (sigue.isEmpty) {
        _sesion = null;
        _fecha = null;
        _escucharRegistro();
      } else {
        _sesion = sigue.first;
      }
    } else {
      _elegirInicial();
    }
    _revisarListo();
  }

  void _alLlegarInscritos(List<Inscripcion> inscripciones) {
    _inscritos =
        [
          for (final inscripcion in inscripciones)
            if (inscripcion.estaActiva) inscripcion,
        ]..sort(
          (a, b) => a.nombreEstudiante.toLowerCase().compareTo(
            b.nombreEstudiante.toLowerCase(),
          ),
        );
    _inscritosListos = true;
    _revisarListo();
  }

  void _alFallarCarga(Object _) {
    _estado = TomarAsistenciaEstado.error;
    _notificar();
  }

  void _revisarListo() {
    if (_sesionesListas && _inscritosListos) {
      _estado = TomarAsistenciaEstado.listo;
    }
    _notificar();
  }

  /// Al venir del historial se abre esa clase; si el deporte tiene una sola
  /// sesión, se elige sola con su fecha más reciente.
  void _elegirInicial() {
    Sesion? inicial;
    if (idSesionInicial != null) {
      final encontradas = _sesiones.where((s) => s.id == idSesionInicial);
      if (encontradas.isNotEmpty) inicial = encontradas.first;
    } else if (_sesiones.length == 1) {
      inicial = _sesiones.first;
    }
    if (inicial == null) return;

    _sesion = inicial;
    final fecha = fechaInicial;
    _fecha = fecha != null && idSesionInicial == inicial.id
        ? DateTime(fecha.year, fecha.month, fecha.day)
        : fechasDisponibles.first;
    _escucharRegistro();
  }

  /// El entrenador elige la sesión; se propone su fecha más reciente.
  void elegirSesion(Sesion sesion) {
    if (_sesion?.id == sesion.id) return;
    _sesion = sesion;
    _fecha = fechasDisponibles.first;
    _escucharRegistro();
    _notificar();
  }

  void elegirFecha(DateTime fecha) {
    _fecha = DateTime(fecha.year, fecha.month, fecha.day);
    _escucharRegistro();
    _notificar();
  }

  /// Observa la asistencia ya guardada de la clase elegida para precargarla.
  void _escucharRegistro() {
    _registroSubscription?.cancel();
    _registroSubscription = null;
    _marcas.clear();
    _guardado.clear();
    _conRegistro.clear();
    _tocado = false;
    _guardadoConExito = false;
    _error = null;

    final sesion = _sesion;
    final fecha = _fecha;
    if (sesion == null || fecha == null || errorFecha != null) {
      _cargandoRegistro = false;
      return;
    }

    _cargandoRegistro = true;
    _registroSubscription = asistenciaRepository
        .observarPorSesion(sesion.id, fecha)
        .listen(
          (registros) {
            _guardado.clear();
            _conRegistro.clear();
            for (final registro in registros) {
              _guardado[registro.idInscripcion] = registro.presente;
              _conRegistro.add(registro.idInscripcion);
            }
            // No se pisan las marcas que el entrenador está cambiando.
            if (!_tocado) {
              _marcas
                ..clear()
                ..addAll(_guardado);
            }
            _cargandoRegistro = false;
            _notificar();
          },
          onError: (Object _) {
            _cargandoRegistro = false;
            _error =
                'No se pudo revisar si esta clase ya tenía asistencia. '
                'Revisa tu conexión e intenta de nuevo.';
            _notificar();
          },
        );
  }

  void alternar(String idInscripcion) {
    if (_guardando) return;
    _marcas[idInscripcion] = !presente(idInscripcion);
    _tocado = true;
    _guardadoConExito = false;
    _notificar();
  }

  void marcarTodos(bool presentes) {
    if (_guardando) return;
    for (final inscripcion in _inscritos) {
      _marcas[inscripcion.id] = presentes;
    }
    _tocado = true;
    _guardadoConExito = false;
    _notificar();
  }

  /// Guarda un registro por inscrito en una sola operación (RF-ENT-03).
  /// Devuelve true si se guardó.
  Future<bool> guardar() async {
    final sesion = _sesion;
    final fecha = _fecha;
    if (!puedeGuardar || sesion == null || fecha == null) return false;

    _guardando = true;
    _error = null;
    _guardadoConExito = false;
    _notificar();

    final registros = [
      for (final inscripcion in _inscritos)
        Asistencia(
          id: Asistencia.idPara(inscripcion.id, sesion.id, fecha),
          idInscripcion: inscripcion.id,
          idEstudiante: inscripcion.idEstudiante,
          idDeporte: deporte.id,
          idSesion: sesion.id,
          fecha: fecha,
          presente: presente(inscripcion.id),
        ),
    ];

    try {
      await asistenciaRepository.registrar(registros);
      for (final registro in registros) {
        _guardado[registro.idInscripcion] = registro.presente;
        _conRegistro.add(registro.idInscripcion);
      }
      _tocado = false;
      _guardadoConExito = true;
      return true;
    } catch (_) {
      _error =
          'No se pudo guardar la asistencia. Revisa tu conexión e intenta '
          'de nuevo.';
      return false;
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  /// Evita avisar a la pantalla cuando ya se cerró.
  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _sesionesSubscription?.cancel();
    _inscritosSubscription?.cancel();
    _registroSubscription?.cancel();
    super.dispose();
  }
}
