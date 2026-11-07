import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/core/formatos.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga del catálogo.
enum CatalogoEstado { cargando, listo, error }

/// Franja del día en que empieza una sesión.
enum FranjaHoraria { manana, tarde, noche }

/// Catálogo de disciplinas del estudiante, con búsqueda y filtros
/// (RF-EST-02, RF-EST-03).
///
/// Observa los deportes visibles y el horario de cada uno, así que los cupos
/// bajan solos cuando alguien se inscribe (RF-SIS-03).
class CatalogoViewModel extends ChangeNotifier {
  final DeporteRepository deporteRepository;

  List<Deporte> _deportes = const [];
  final Map<String, List<Sesion>> _sesiones = {};
  CatalogoEstado _estado = CatalogoEstado.cargando;
  bool _descartado = false;

  String _busqueda = '';
  bool _soloConCupos = false;
  DiaSemana? _dia;
  FranjaHoraria? _franja;

  // Patrón Observador: los deportes y sus horarios llegan en vivo.
  StreamSubscription<List<Deporte>>? _deportesSubscription;
  final Map<String, StreamSubscription<List<Sesion>>> _sesionesSubs = {};

  CatalogoViewModel({required this.deporteRepository});

  CatalogoEstado get estado => _estado;

  String get busqueda => _busqueda;
  bool get soloConCupos => _soloConCupos;
  DiaSemana? get dia => _dia;
  FranjaHoraria? get franja => _franja;

  /// Hay algún filtro o búsqueda activa.
  bool get hayFiltros =>
      _busqueda.trim().isNotEmpty ||
      _soloConCupos ||
      _dia != null ||
      _franja != null;

  /// Deportes visibles, sin aplicar filtros. Sirve para distinguir «no hay
  /// disciplinas» de «ningún resultado con estos filtros».
  int get totalDeportes => _deportes.length;

  /// Horario de un deporte (vacío si todavía no llega o no tiene sesiones).
  List<Sesion> sesionesDe(String idDeporte) =>
      _sesiones[idDeporte] ?? const [];

  /// Deportes que cumplen todos los filtros activos: primero los que tienen
  /// cupo y luego por nombre.
  List<Deporte> get deportesFiltrados {
    final consulta = _normalizar(_busqueda);

    final lista = [
      for (final deporte in _deportes)
        if ((!_soloConCupos || deporte.hayCupo) &&
            (consulta.isEmpty || _coincide(deporte, consulta)) &&
            _cumpleHorario(deporte))
          deporte,
    ];

    lista.sort((a, b) {
      if (a.hayCupo != b.hayCupo) return a.hayCupo ? -1 : 1;
      return _normalizar(a.nombre).compareTo(_normalizar(b.nombre));
    });
    return lista;
  }

  /// Empieza a observar el catálogo. La pantalla la llama al abrirse, y de
  /// nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = CatalogoEstado.cargando;
    _cancelarSuscripciones();
    _notificar();

    _deportesSubscription = deporteRepository.observarDeportes().listen(
      (deportes) {
        _deportes = deportes;
        _observarSesiones();
        _estado = CatalogoEstado.listo;
        _notificar();
      },
      onError: (Object _) {
        _estado = CatalogoEstado.error;
        _notificar();
      },
    );
  }

  void cambiarBusqueda(String texto) {
    _busqueda = texto;
    _notificar();
  }

  void cambiarSoloConCupos(bool valor) {
    _soloConCupos = valor;
    _notificar();
  }

  /// `null` quita el filtro de día.
  void cambiarDia(DiaSemana? dia) {
    _dia = dia;
    _notificar();
  }

  /// `null` quita el filtro de franja.
  void cambiarFranja(FranjaHoraria? franja) {
    _franja = franja;
    _notificar();
  }

  void limpiarFiltros() {
    _busqueda = '';
    _soloConCupos = false;
    _dia = null;
    _franja = null;
    _notificar();
  }

  /// Franja según la hora de inicio «HH:MM»: mañana antes de las 12:00, tarde
  /// de 12:00 a 18:00 y noche después de las 18:00. `null` si la hora no tiene
  /// el formato esperado.
  static FranjaHoraria? franjaDe(String hora) {
    final partes = hora.split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;

    final minutos = h * 60 + m;
    if (minutos < 12 * 60) return FranjaHoraria.manana;
    if (minutos <= 18 * 60) return FranjaHoraria.tarde;
    return FranjaHoraria.noche;
  }

  /// Si hay filtro de día o de franja, alguna sesión debe cumplir ambos a la
  /// vez («los martes en la noche» no es «un martes y una noche cualquiera»).
  bool _cumpleHorario(Deporte deporte) {
    if (_dia == null && _franja == null) return true;
    return sesionesDe(deporte.id).any(
      (sesion) =>
          (_dia == null || sesion.dia == _dia) &&
          (_franja == null || franjaDe(sesion.horaInicio) == _franja),
    );
  }

  bool _coincide(Deporte deporte, String consulta) {
    return _normalizar(deporte.nombre).contains(consulta) ||
        _normalizar(deporte.codigo).contains(consulta) ||
        _normalizar(deporte.descripcion).contains(consulta);
  }

  /// Minúsculas y sin tildes, para que «fútbol» y «futbol» coincidan. La «ñ»
  /// se conserva: «año» no es «ano».
  static String _normalizar(String texto) {
    const conTilde = 'áàäâéèëêíìïîóòöôúùüû';
    const sinTilde = 'aaaaeeeeiiiioooouuuu';

    var resultado = Formatos.espacios(texto).toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  /// Observa el horario de cada deporte visible y deja de observar los que
  /// ya no están.
  void _observarSesiones() {
    final ids = {for (final deporte in _deportes) deporte.id};

    for (final id in _sesionesSubs.keys.toList()) {
      if (ids.contains(id)) continue;
      _sesionesSubs.remove(id)?.cancel();
      _sesiones.remove(id);
    }

    for (final id in ids) {
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
