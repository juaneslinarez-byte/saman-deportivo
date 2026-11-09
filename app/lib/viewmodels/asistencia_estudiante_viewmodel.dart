import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga del historial de asistencia.
enum AsistenciaEstudianteEstado { cargando, listo, error }

/// El historial de asistencia de un deporte: cuántas clases hubo, cuántas
/// asistió el estudiante y la lista completa de más reciente a más antigua.
class AsistenciaPorDeporte {
  const AsistenciaPorDeporte({
    required this.idDeporte,
    required this.nombreDeporte,
    required this.registros,
  });

  final String idDeporte;
  final String nombreDeporte;

  /// Registros ordenados de más reciente a más antiguo.
  final List<Asistencia> registros;

  int get total => registros.length;
  int get presentes => registros.where((r) => r.presente).length;
  int get ausentes => total - presentes;

  /// Porcentaje de asistencia, 0–100. Es 0 si no hubo clases.
  double get porcentaje => total == 0 ? 0 : presentes / total * 100;
}

/// Historial de asistencia del estudiante, agrupado por disciplina
/// (RF-EST-06).
class AsistenciaEstudianteViewModel extends ChangeNotifier {
  final AsistenciaRepository asistenciaRepository;
  final DeporteRepository deporteRepository;
  final String idEstudiante;

  /// Si se indica, solo se muestra el historial de esa disciplina (al abrir
  /// «Mi asistencia» desde su tarjeta en «Mis disciplinas»).
  final String? idDeporte;

  List<AsistenciaPorDeporte> _grupos = const [];
  Map<String, Deporte> _deportes = const {};
  AsistenciaEstudianteEstado _estado = AsistenciaEstudianteEstado.cargando;
  bool _asistenciasListas = false;
  bool _deportesListos = false;
  bool _descartado = false;

  StreamSubscription<List<Asistencia>>? _asistenciasSubscription;
  StreamSubscription<List<Deporte>>? _deportesSubscription;

  // Guarda la última lista para volver a agrupar cuando lleguen los deportes.
  List<Asistencia> _ultimasAsistencias = const [];

  AsistenciaEstudianteViewModel({
    required this.asistenciaRepository,
    required this.deporteRepository,
    required this.idEstudiante,
    this.idDeporte,
  });

  /// Nombre de la disciplina filtrada, o null si se muestran todas.
  String? get nombreFiltro {
    final id = idDeporte;
    if (id == null) return null;
    return _deportes[id]?.nombre ?? 'Disciplina no disponible';
  }

  AsistenciaEstudianteEstado get estado => _estado;

  /// Historial agrupado por disciplina, de mayor a menor porcentaje.
  List<AsistenciaPorDeporte> get grupos => _grupos;

  /// Empieza a observar el historial. La pantalla la llama al abrirse, y de
  /// nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = AsistenciaEstudianteEstado.cargando;
    _asistenciasListas = false;
    _deportesListos = false;
    _ultimasAsistencias = const [];
    _asistenciasSubscription?.cancel();
    _deportesSubscription?.cancel();

    _asistenciasSubscription = asistenciaRepository
        .observarPorEstudiante(idEstudiante)
        .listen((asistencias) {
          _ultimasAsistencias = asistencias;
          _asistenciasListas = true;
          _agrupar();
          _actualizarEstado();
        }, onError: (Object _) => _fallar());

    _deportesSubscription = deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((deportes) {
          _deportes = {for (final deporte in deportes) deporte.id: deporte};
          _deportesListos = true;
          _agrupar();
          _actualizarEstado();
        }, onError: (Object _) => _fallar());
  }

  /// Agrupa los registros por disciplina y los ordena de más reciente a más
  /// antigua dentro de cada grupo.
  void _agrupar() {
    final porDeporte = <String, List<Asistencia>>{};
    for (final asistencia in _ultimasAsistencias) {
      if (idDeporte != null && asistencia.idDeporte != idDeporte) continue;
      porDeporte.putIfAbsent(asistencia.idDeporte, () => []).add(asistencia);
    }

    _grupos = [
      for (final entrada in porDeporte.entries)
        AsistenciaPorDeporte(
          idDeporte: entrada.key,
          nombreDeporte:
              _deportes[entrada.key]?.nombre ?? 'Disciplina no disponible',
          registros: entrada.value..sort((a, b) => b.fecha.compareTo(a.fecha)),
        ),
    ]..sort((a, b) => b.porcentaje.compareTo(a.porcentaje));
  }

  void _actualizarEstado() {
    if (_asistenciasListas && _deportesListos) {
      _estado = AsistenciaEstudianteEstado.listo;
    }
    _notificar();
  }

  void _fallar() {
    _estado = AsistenciaEstudianteEstado.error;
    _notificar();
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _asistenciasSubscription?.cancel();
    _deportesSubscription?.cancel();
    super.dispose();
  }
}
