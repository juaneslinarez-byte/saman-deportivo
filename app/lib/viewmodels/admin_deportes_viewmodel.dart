import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/modelos.dart';
import '../repositorios/deporte_repository.dart';
import '../repositorios/usuario_repository.dart';

/// Gestión de deportes del administrador: alta, edición, publicación,
/// eliminación y entrenadores asignados (RF-ADM-01, RF-ADM-02, RF-ADM-04).
class AdminDeportesViewModel extends ChangeNotifier {
  AdminDeportesViewModel(this._deporteRepository, [this._usuarioRepository]) {
    _escucharDeportes();
    _cargarEntrenadores();
  }

  final DeporteRepository _deporteRepository;
  final UsuarioRepository? _usuarioRepository;

  List<Deporte> _deportes = [];
  List<Deporte> _deportesFiltrados = [];
  String _filtroBusqueda = '';
  bool _cargando = false;
  String? _error;
  StreamSubscription<List<Deporte>>? _deportesSub;
  Map<String, Persona> _entrenadores = {};

  List<Deporte> get deportes => _deportesFiltrados;
  bool get cargando => _cargando;
  String? get error => _error;

  void _escucharDeportes() {
    _cargando = true;
    _error = null;
    notifyListeners();

    _deportesSub?.cancel();
    _deportesSub = _deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen(
          (lista) {
            _deportes = lista;
            _aplicarFiltro();
            _cargando = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object _) {
            _cargando = false;
            _error = 'No se pudieron cargar los deportes.';
            notifyListeners();
          },
        );
  }

  void buscar(String texto) {
    _filtroBusqueda = texto.trim().toLowerCase();
    _aplicarFiltro();
    notifyListeners();
  }

  void _aplicarFiltro() {
    if (_filtroBusqueda.isEmpty) {
      _deportesFiltrados = List.from(_deportes);
      return;
    }
    _deportesFiltrados = _deportes.where((deporte) {
      return deporte.nombre.toLowerCase().contains(_filtroBusqueda) ||
          deporte.codigo.toLowerCase().contains(_filtroBusqueda) ||
          deporte.lugar.toLowerCase().contains(_filtroBusqueda);
    }).toList();
  }

  bool esCodigoUnico(String codigo, {String? idDeporteActual}) {
    final codigoNormalizado = codigo.trim().toLowerCase();
    return !_deportes.any(
      (d) =>
          d.id != idDeporteActual &&
          d.codigo.trim().toLowerCase() == codigoNormalizado,
    );
  }

  /// Crea o edita un deporte. Un deporte nuevo nace oculto y con todos los
  /// cupos libres; al editar, los cupos disponibles se recalculan para que
  /// los inscritos no cambien.
  Future<bool> guardarDeporte({
    String? id,
    required String codigo,
    required String nombre,
    required String descripcion,
    required String lugar,
    required int cupoMaximo,
  }) async {
    final codigoLimpio = codigo.trim().toUpperCase();
    if (!esCodigoUnico(codigoLimpio, idDeporteActual: id)) {
      _error =
          'El código "$codigoLimpio" ya está registrado en otra disciplina.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      if (id == null) {
        await _deporteRepository.crear(
          Deporte(
            id: '',
            codigo: codigoLimpio,
            nombre: nombre.trim(),
            descripcion: descripcion.trim(),
            lugar: lugar.trim(),
            cupoMaximo: cupoMaximo,
            cuposDisponibles: cupoMaximo,
            visible: false,
          ),
        );
      } else {
        final actual = _deportes.firstWhere((d) => d.id == id);
        if (cupoMaximo < actual.inscritos) {
          _error =
              'El cupo no puede ser menor que los inscritos actuales '
              '(${actual.inscritos}).';
          return false;
        }
        await _deporteRepository.actualizar(
          actual.copyWith(
            codigo: codigoLimpio,
            nombre: nombre.trim(),
            descripcion: descripcion.trim(),
            lugar: lugar.trim(),
            cupoMaximo: cupoMaximo,
            cuposDisponibles: cupoMaximo - actual.inscritos,
          ),
        );
      }
      return true;
    } catch (_) {
      _error = 'No se pudo guardar el deporte. Inténtalo de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Solo se publica un deporte con entrenador y al menos una sesión.
  Future<bool> alternarVisibilidad(Deporte deporte) async {
    _error = null;
    if (!deporte.visible) {
      if (!deporte.tieneEntrenador) {
        _error = 'Asigna un entrenador antes de publicar el deporte.';
        notifyListeners();
        return false;
      }
      try {
        final sesiones = await _deporteRepository
            .observarSesiones(deporte.id)
            .first;
        if (sesiones.isEmpty) {
          _error = 'Agrega al menos una sesión antes de publicar el deporte.';
          notifyListeners();
          return false;
        }
      } catch (_) {
        _error = 'No se pudieron revisar las sesiones. Inténtalo de nuevo.';
        notifyListeners();
        return false;
      }
    }
    return _actualizar(
      deporte.copyWith(visible: !deporte.visible),
      'No se pudo cambiar la visibilidad. Inténtalo de nuevo.',
    );
  }

  /// Entrenadores registrados, para asignarlos a un deporte. Se guardan
  /// para mostrar en cada tarjeta quién da la disciplina.
  Future<List<Persona>> obtenerEntrenadores() async {
    final repositorio = _usuarioRepository;
    if (repositorio == null) return [];
    try {
      final lista = await repositorio.listar(actor: Actor.entrenador);
      lista.sort(
        (a, b) => '${a.nombre} ${a.apellido}'.toLowerCase().compareTo(
          '${b.nombre} ${b.apellido}'.toLowerCase(),
        ),
      );
      _entrenadores = {for (final e in lista) e.id: e};
      return lista;
    } catch (_) {
      _error = 'No se pudieron cargar los entrenadores.';
      notifyListeners();
      return [];
    }
  }

  Future<void> _cargarEntrenadores() async {
    if (_usuarioRepository == null) return;
    await obtenerEntrenadores();
    notifyListeners();
  }

  /// Nombres de los entrenadores de la disciplina, en el orden asignado.
  /// Si un entrenador ya no aparece entre los registrados (por ejemplo,
  /// volvió a ser estudiante), se indica en lugar de su nombre.
  List<String> nombresEntrenadores(Deporte deporte) => [
    for (final id in deporte.idsEntrenadores)
      _entrenadores[id] == null
          ? 'Entrenador no disponible'
          : '${_entrenadores[id]!.nombre} ${_entrenadores[id]!.apellido}',
  ];

  /// Deja la disciplina con los entrenadores [idsEntrenadores]: sirve para
  /// agregar, cambiar o quitar instructores. Sin ninguno, la disciplina se
  /// oculta del catálogo, porque nadie daría las clases.
  Future<bool> guardarEntrenadores(
    Deporte deporte,
    List<String> idsEntrenadores,
  ) {
    if (idsEntrenadores.isEmpty) {
      return _actualizar(
        deporte.copyWith(quitarEntrenador: true, visible: false),
        'No se pudieron quitar los entrenadores. Inténtalo de nuevo.',
      );
    }
    return _actualizar(
      deporte.copyWith(idsEntrenadores: idsEntrenadores),
      'No se pudieron guardar los entrenadores. Inténtalo de nuevo.',
    );
  }

  Future<bool> ocultarDeporte(Deporte deporte) => _actualizar(
    deporte.copyWith(visible: false),
    'No se pudo ocultar el deporte. Inténtalo de nuevo.',
  );

  /// Un deporte con inscritos no se elimina (RF-SIS-09): se ofrece ocultarlo.
  Future<bool> eliminarDeporte(Deporte deporte) async {
    _error = null;
    if (deporte.inscritos > 0) {
      _error = 'No se puede eliminar un deporte con inscritos.';
      notifyListeners();
      return false;
    }
    try {
      await _deporteRepository.eliminar(deporte.id);
      return true;
    } catch (_) {
      _error = 'No se pudo eliminar el deporte. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _actualizar(Deporte deporte, String mensajeError) async {
    _error = null;
    try {
      await _deporteRepository.actualizar(deporte);
      return true;
    } catch (_) {
      _error = mensajeError;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _deportesSub?.cancel();
    super.dispose();
  }
}
