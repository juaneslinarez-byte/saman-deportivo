import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/deporte.dart';
import '../repositorios/deporte_repository.dart';

/// ViewModel para la administración del catálogo de deportes (RF-ADM-01, RF-ADM-02).
class AdminDeportesViewModel extends ChangeNotifier {
  final DeporteRepository _deporteRepository;

  List<Deporte> _deportes = [];
  List<Deporte> _deportesFiltrados = [];
  String _filtroBusqueda = '';
  bool _cargando = false;
  String? _error;
  StreamSubscription<List<Deporte>>? _deportesSub;

  AdminDeportesViewModel(this._deporteRepository) {
    _escucharDeportes();
  }

  List<Deporte> get deportes => _deportesFiltrados;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Observa todos los deportes (visibles y ocultos) en tiempo real (RF-ADM-01).
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
            notifyListeners();
          },
          onError: (Object e) {
            _cargando = false;
            _error = 'No se pudieron cargar los deportes.';
            notifyListeners();
          },
        );
  }

  /// Filtra la lista por nombre o por código de disciplina.
  void buscar(String texto) {
    _filtroBusqueda = texto.trim().toLowerCase();
    _aplicarFiltro();
    notifyListeners();
  }

  void _aplicarFiltro() {
    if (_filtroBusqueda.isEmpty) {
      _deportesFiltrados = List.from(_deportes);
    } else {
      _deportesFiltrados = _deportes.where((deporte) {
        final nombreCoincide = deporte.nombre.toLowerCase().contains(
          _filtroBusqueda,
        );
        final codigoCoincide = deporte.codigo.toLowerCase().contains(
          _filtroBusqueda,
        );
        return nombreCoincide || codigoCoincide;
      }).toList();
    }
  }

  /// Verifica la unicidad del código independientemente de mayúsculas/minúsculas.
  bool esCodigoUnico(String codigo, {String? idDeporteActual}) {
    final codigoNormalizado = codigo.trim().toLowerCase();
    return !_deportes.any(
      (d) =>
          d.id != idDeporteActual &&
          d.codigo.trim().toLowerCase() == codigoNormalizado,
    );
  }

  /// Crea o actualiza un deporte validando el código único (RF-ADM-01).
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
        /// Un deporte nuevo se crea oculto (RF-ADM-01).
        final nuevoDeporte = Deporte(
          id: '',
          codigo: codigoLimpio,
          nombre: nombre.trim(),
          descripcion: descripcion.trim(),
          lugar: lugar.trim(),
          cupoMaximo: cupoMaximo,
          cuposDisponibles: cupoMaximo,
          idEntrenador: null,
          visible: false,
        );
        await _deporteRepository.crear(nuevoDeporte);
      } else {
        final actual = _deportes.firstWhere((d) => d.id == id);
        final inscritosActuales = actual.inscritos;
        final actualizacion = actual.copyWith(
          codigo: codigoLimpio,
          nombre: nombre.trim(),
          descripcion: descripcion.trim(),
          lugar: lugar.trim(),
          cupoMaximo: cupoMaximo,
          cuposDisponibles: cupoMaximo - inscritosActuales,
        );
        await _deporteRepository.actualizar(actualizacion);
      }
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la información del deporte.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Alterna la visibilidad. Solo permite activar si tiene entrenador y sesiones (RF-ADM-01).
  Future<bool> alternarVisibilidad(Deporte deporte) async {
    if (!deporte.visible) {
      if (deporte.idEntrenador == null || deporte.idEntrenador!.isEmpty) {
        _error = 'Asigna un entrenador antes de publicar el deporte.';
        notifyListeners();
        return false;
      }

      final sesiones = await _deporteRepository
          .observarSesiones(deporte.id)
          .first;
      if (sesiones.isEmpty) {
        _error =
            'Agrega al menos una sesión de entrenamiento antes de publicar.';
        notifyListeners();
        return false;
      }
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final deporteActualizado = deporte.copyWith(visible: !deporte.visible);
      await _deporteRepository.actualizar(deporteActualizado);
      return true;
    } catch (e) {
      _error = 'Ocurrió un error al cambiar la visibilidad.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _deportesSub?.cancel();
    super.dispose();
  }
}
