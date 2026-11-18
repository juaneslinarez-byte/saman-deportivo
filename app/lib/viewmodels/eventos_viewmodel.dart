import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/formatos.dart';
import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/evento_repository.dart';
import '../repositorios/reserva_repository.dart';

enum EventosEstado { cargando, listo, error }

/// Eventos próximos y reservas del estudiante. Se observan en tiempo real:
/// si alguien reserva o el administrador cambia un evento, la pantalla se
/// actualiza sola.
class EventosViewModel extends ChangeNotifier {
  EventosViewModel({
    required this._eventoRepository,
    required this._reservaRepository,
    required this._idEstudiante,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final EventoRepository _eventoRepository;
  final ReservaRepository _reservaRepository;
  final String _idEstudiante;
  final DateTime Function() _reloj;

  List<Evento> _eventos = const [];
  List<Reserva> _reservas = const [];
  bool _eventosListos = false;
  bool _reservasListas = false;
  EventosEstado _estado = EventosEstado.cargando;
  String _busqueda = '';
  bool _soloConCupo = false;
  bool _soloGratis = false;
  bool _reservando = false;
  final Set<String> _cancelando = {};
  String? _error;

  StreamSubscription<List<Evento>>? _subEventos;
  StreamSubscription<List<Reserva>>? _subReservas;

  EventosEstado get estado => _estado;
  bool get soloConCupo => _soloConCupo;
  bool get soloGratis => _soloGratis;
  bool get reservando => _reservando;
  String? get error => _error;
  DateTime get ahora => _reloj();
  bool cancelando(Reserva reserva) => _cancelando.contains(reserva.id);

  /// Próximos eventos con la búsqueda y los filtros aplicados.
  List<Evento> get eventos {
    final consulta = Formatos.paraBuscar(_busqueda);
    return _eventos.where((e) {
      if (_soloConCupo && !e.hayCupo) return false;
      if (_soloGratis && !e.esGratis) return false;
      if (consulta.isEmpty) return true;
      return Formatos.paraBuscar(e.titulo).contains(consulta) ||
          Formatos.paraBuscar(e.lugar).contains(consulta);
    }).toList();
  }

  bool get hayEventos => _eventos.isNotEmpty;

  /// Reservas del estudiante: las de eventos por venir primero.
  List<Reserva> get reservas {
    final ahora = _reloj();
    final proximas =
        _reservas.where((r) => r.inicioEvento.isAfter(ahora)).toList()
          ..sort((a, b) => a.inicioEvento.compareTo(b.inicioEvento));
    final pasadas =
        _reservas.where((r) => !r.inicioEvento.isAfter(ahora)).toList()
          ..sort((a, b) => b.inicioEvento.compareTo(a.inicioEvento));
    return [...proximas, ...pasadas];
  }

  int get reservasVigentes => _reservas.where((r) => r.vigente).length;

  /// Reserva vigente del estudiante en el evento, si la tiene.
  Reserva? reservaEn(Evento evento) {
    for (final r in _reservas) {
      if (r.idEvento == evento.id && r.vigente) return r;
    }
    return null;
  }

  /// Evento más reciente con ese id (para el detalle en tiempo real).
  Evento? evento(String id) {
    for (final e in _eventos) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Por qué no se puede reservar el evento, o null si se puede.
  String? motivoParaNoReservar(Evento evento, Persona? perfil) {
    if (perfil is! Estudiante) return 'Solo los estudiantes pueden reservar.';
    if (!perfil.habilitado) return 'Tu cuenta está deshabilitada.';
    if (evento.estaCancelado) return 'El evento fue cancelado.';
    if (evento.yaEmpezo(_reloj())) return 'El evento ya empezó.';
    if (reservaEn(evento) != null) {
      return 'Ya tienes una reserva en este evento.';
    }
    if (!evento.hayCupo) return 'No quedan cupos.';
    return null;
  }

  /// Máximo de personas que se pueden elegir al reservar.
  int maxPersonas(Evento evento) =>
      min(evento.maxPorReserva, evento.cuposDisponibles);

  void cargar() {
    _estado = EventosEstado.cargando;
    _eventosListos = false;
    _reservasListas = false;
    notifyListeners();
    _subEventos?.cancel();
    _subReservas?.cancel();
    _subEventos = _eventoRepository.observarProximos().listen((lista) {
      _eventos = lista;
      _eventosListos = true;
      _actualizarEstado();
    }, onError: _alFallar);
    _subReservas = _reservaRepository
        .observarPorEstudiante(_idEstudiante)
        .listen((lista) {
          _reservas = lista;
          _reservasListas = true;
          _actualizarEstado();
        }, onError: _alFallar);
  }

  void _actualizarEstado() {
    if (_eventosListos && _reservasListas) _estado = EventosEstado.listo;
    notifyListeners();
  }

  void _alFallar(Object _) {
    _estado = EventosEstado.error;
    notifyListeners();
  }

  void buscar(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  void alternarConCupo() {
    _soloConCupo = !_soloConCupo;
    notifyListeners();
  }

  void alternarGratis() {
    _soloGratis = !_soloGratis;
    notifyListeners();
  }

  /// Registra la reserva con la [referencia] que devolvió la pasarela.
  /// Devuelve la reserva, o null si no se pudo (el motivo queda en [error]).
  Future<Reserva?> reservar({
    required Evento evento,
    required Persona? perfil,
    required int personas,
    required String referencia,
  }) async {
    if (_reservando) return null;
    final motivo = motivoParaNoReservar(evento, perfil);
    if (motivo != null) {
      _error = motivo;
      notifyListeners();
      return null;
    }
    _reservando = true;
    _error = null;
    notifyListeners();
    try {
      return await _reservaRepository.reservar(
        estudiante: perfil! as Estudiante,
        evento: evento,
        personas: personas,
        referencia: referencia,
      );
    } catch (e) {
      _error = mensajeDeError(
        e,
        porDefecto:
            'No se pudo registrar la reserva. Revisa tu conexión e '
            'inténtalo de nuevo.',
      );
      return null;
    } finally {
      _reservando = false;
      notifyListeners();
    }
  }

  /// Devuelve null si se canceló, o el mensaje de error.
  Future<String?> cancelar(Reserva reserva) async {
    if (_cancelando.contains(reserva.id)) return null;
    _cancelando.add(reserva.id);
    notifyListeners();
    try {
      await _reservaRepository.cancelar(reserva);
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _cancelando.remove(reserva.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subEventos?.cancel();
    _subReservas?.cancel();
    super.dispose();
  }
}
