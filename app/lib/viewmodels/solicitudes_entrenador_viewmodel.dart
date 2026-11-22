import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/formatos.dart';
import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/deporte_repository.dart';
import '../repositorios/solicitud_repository.dart';

enum SolicitudesEntrenadorEstado { cargando, listo, error }

/// Una disciplina que el entrenador no dirige y, si la hay, su solicitud.
typedef OpcionSolicitud = ({Deporte deporte, Solicitud? solicitud});

/// «Solicitar disciplina» del entrenador (RF-ENT-06): las disciplinas que
/// todavía no dirige, con el estado de lo que ya pidió.
class SolicitudesEntrenadorViewModel extends ChangeNotifier {
  SolicitudesEntrenadorViewModel({
    required this._deporteRepository,
    required this._solicitudRepository,
    required this._entrenador,
  });

  final DeporteRepository _deporteRepository;
  final SolicitudRepository _solicitudRepository;
  final Entrenador _entrenador;

  SolicitudesEntrenadorEstado _estado = SolicitudesEntrenadorEstado.cargando;
  List<Deporte> _deportes = [];
  Map<String, Solicitud> _solicitudes = {};
  bool _deportesListos = false;
  bool _solicitudesListas = false;
  String _busqueda = '';
  final Set<String> _enviando = {};
  StreamSubscription<List<Deporte>>? _subDeportes;
  StreamSubscription<List<Solicitud>>? _subSolicitudes;

  SolicitudesEntrenadorEstado get estado => _estado;

  bool enviando(Deporte deporte) => _enviando.contains(deporte.id);

  String get busqueda => _busqueda;

  set busqueda(String valor) {
    _busqueda = valor;
    notifyListeners();
  }

  /// Disciplinas que no dirige, ordenadas: primero las que puede pedir.
  List<OpcionSolicitud> get opciones {
    final texto = Formatos.paraBuscar(_busqueda);
    final lista = <OpcionSolicitud>[
      for (final d in _deportes)
        if (!d.tieneAlEntrenador(_entrenador.id) &&
            (texto.isEmpty ||
                Formatos.paraBuscar('${d.nombre} ${d.codigo}').contains(texto)))
          (deporte: d, solicitud: _solicitudes[d.id]),
    ];
    int orden(OpcionSolicitud o) => switch (o.solicitud?.estado) {
      null => 0,
      EstadoSolicitud.rechazada => 0,
      EstadoSolicitud.pendiente => 1,
      EstadoSolicitud.aprobada => 2,
    };
    lista.sort((a, b) {
      final porEstado = orden(a).compareTo(orden(b));
      if (porEstado != 0) return porEstado;
      return a.deporte.nombre.compareTo(b.deporte.nombre);
    });
    return lista;
  }

  /// Solicitudes que esperan respuesta.
  int get pendientes =>
      _solicitudes.values.where((s) => s.estaPendiente).length;

  void cargar() {
    _estado = SolicitudesEntrenadorEstado.cargando;
    _deportesListos = false;
    _solicitudesListas = false;
    notifyListeners();
    _subDeportes?.cancel();
    _subSolicitudes?.cancel();
    _subDeportes = _deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((lista) {
          _deportes = lista;
          _deportesListos = true;
          _actualizar();
        }, onError: _fallo);
    _subSolicitudes = _solicitudRepository
        .observarPorEntrenador(_entrenador.id)
        .listen((lista) {
          _solicitudes = {for (final s in lista) s.idDeporte: s};
          _solicitudesListas = true;
          _actualizar();
        }, onError: _fallo);
  }

  void _actualizar() {
    if (_deportesListos && _solicitudesListas) {
      _estado = SolicitudesEntrenadorEstado.listo;
    }
    notifyListeners();
  }

  void _fallo(Object _) {
    _estado = SolicitudesEntrenadorEstado.error;
    notifyListeners();
  }

  /// Devuelve null si se envió o el motivo del error.
  Future<String?> solicitar(Deporte deporte, {String mensaje = ''}) async {
    if (_enviando.contains(deporte.id)) return null;
    _enviando.add(deporte.id);
    notifyListeners();
    try {
      await _solicitudRepository.solicitar(
        entrenador: _entrenador,
        deporte: deporte,
        mensaje: mensaje,
      );
      return null;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _enviando.remove(deporte.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subDeportes?.cancel();
    _subSolicitudes?.cancel();
    super.dispose();
  }
}
