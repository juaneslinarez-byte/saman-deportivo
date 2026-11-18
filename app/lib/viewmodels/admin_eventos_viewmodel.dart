import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/formatos.dart';
import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/deporte_repository.dart';
import '../repositorios/evento_repository.dart';
import '../repositorios/reserva_repository.dart';

enum AdminEventosEstado { cargando, listo, error }

/// Filtro de la lista de eventos del administrador.
enum FiltroEventos { todos, proximos, pasados, cancelados }

/// Eventos del club para el administrador: los publica, los edita y los
/// cancela. La lista se observa en tiempo real.
class AdminEventosViewModel extends ChangeNotifier {
  AdminEventosViewModel({
    required this._eventoRepository,
    required this._deporteRepository,
    required this._reservaRepository,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final EventoRepository _eventoRepository;
  final DeporteRepository _deporteRepository;
  final ReservaRepository _reservaRepository;
  final DateTime Function() _reloj;

  List<Evento> _eventos = const [];
  List<Deporte> _deportes = const [];
  List<Reserva> _enRevision = const [];
  AdminEventosEstado _estado = AdminEventosEstado.cargando;
  FiltroEventos _filtro = FiltroEventos.todos;
  String _busqueda = '';
  bool _guardando = false;
  final Set<String> _enProceso = {};

  StreamSubscription<List<Evento>>? _suscripcion;
  StreamSubscription<List<Deporte>>? _suscripcionDeportes;
  StreamSubscription<List<Reserva>>? _suscripcionReservas;

  AdminEventosEstado get estado => _estado;
  FiltroEventos get filtro => _filtro;
  bool get guardando => _guardando;
  DateTime get ahora => _reloj();
  bool enProceso(Evento evento) => _enProceso.contains(evento.id);

  /// Reservas de todos los eventos que esperan la revisión del pago.
  int get totalEnRevision => _enRevision.length;

  int enRevisionDe(Evento evento) =>
      _enRevision.where((r) => r.idEvento == evento.id).length;

  /// Repositorio de reservas, para la pantalla de reservas de un evento.
  ReservaRepository get reservaRepository => _reservaRepository;

  /// Disciplinas que se pueden relacionar con un evento.
  List<Deporte> get deportes => _deportes;

  String? nombreDeporte(String? idDeporte) {
    if (idDeporte == null) return null;
    for (final d in _deportes) {
      if (d.id == idDeporte) return d.nombre;
    }
    return null;
  }

  /// Próximos arriba (del más cercano al más lejano); pasados y cancelados
  /// abajo, del más reciente al más antiguo.
  List<Evento> get eventos {
    final ahora = _reloj();
    final consulta = Formatos.paraBuscar(_busqueda);
    final filtrados = _eventos.where((e) {
      final vigente = !e.estaCancelado && !e.yaPaso(ahora);
      final coincide = switch (_filtro) {
        FiltroEventos.todos => true,
        FiltroEventos.proximos => vigente,
        FiltroEventos.pasados => !e.estaCancelado && e.yaPaso(ahora),
        FiltroEventos.cancelados => e.estaCancelado,
      };
      if (!coincide) return false;
      if (consulta.isEmpty) return true;
      return Formatos.paraBuscar(e.titulo).contains(consulta) ||
          Formatos.paraBuscar(e.lugar).contains(consulta);
    }).toList();
    final vigentes =
        filtrados.where((e) => !e.estaCancelado && !e.yaPaso(ahora)).toList()
          ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final otros =
        filtrados.where((e) => e.estaCancelado || e.yaPaso(ahora)).toList()
          ..sort((a, b) => b.inicio.compareTo(a.inicio));
    return [...vigentes, ...otros];
  }

  int get totalProximos {
    final ahora = _reloj();
    return _eventos.where((e) => !e.estaCancelado && !e.yaPaso(ahora)).length;
  }

  void cargar() {
    _estado = AdminEventosEstado.cargando;
    notifyListeners();
    _suscripcion?.cancel();
    _suscripcion = _eventoRepository.observarTodos().listen(
      (lista) {
        _eventos = lista;
        _estado = AdminEventosEstado.listo;
        notifyListeners();
      },
      onError: (Object _) {
        _estado = AdminEventosEstado.error;
        notifyListeners();
      },
    );
    _suscripcionDeportes?.cancel();
    _suscripcionDeportes = _deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((lista) {
          _deportes = [...lista]..sort((a, b) => a.nombre.compareTo(b.nombre));
          notifyListeners();
        }, onError: (Object _) {});
    _suscripcionReservas?.cancel();
    _suscripcionReservas = _reservaRepository.observarEnRevision().listen((
      lista,
    ) {
      _enRevision = lista;
      notifyListeners();
    }, onError: (Object _) {});
  }

  void filtrar(FiltroEventos filtro) {
    _filtro = filtro;
    notifyListeners();
  }

  void buscar(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  /// Crea o actualiza el evento. Devuelve null si se guardó, o el mensaje
  /// de error.
  Future<String?> guardar(Evento evento, {required bool nuevo}) async {
    if (_guardando) return 'Ya se está guardando.';
    _guardando = true;
    notifyListeners();
    try {
      if (nuevo) {
        await _eventoRepository.crear(evento);
      } else {
        await _eventoRepository.actualizar(evento);
      }
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  Future<String?> cancelar(Evento evento) =>
      _ejecutar(evento, () => _eventoRepository.cancelar(evento));

  Future<String?> eliminar(Evento evento) =>
      _ejecutar(evento, () => _eventoRepository.eliminar(evento));

  Future<String?> _ejecutar(
    Evento evento,
    Future<void> Function() accion,
  ) async {
    if (_enProceso.contains(evento.id)) return null;
    _enProceso.add(evento.id);
    notifyListeners();
    try {
      await accion();
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _enProceso.remove(evento.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _suscripcionDeportes?.cancel();
    _suscripcionReservas?.cancel();
    super.dispose();
  }
}
