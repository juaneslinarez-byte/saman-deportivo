import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga del detalle de una disciplina.
enum DetalleEstado { cargando, listo, noExiste, error }

/// Detalle de una disciplina del catálogo (RF-EST-03): sus datos, su horario
/// semanal y los cupos en tiempo real.
///
/// Si la disciplina se oculta o se elimina mientras el estudiante la mira, el
/// estado pasa a [DetalleEstado.noExiste] en vez de dejar la pantalla vacía.
class DetalleDisciplinaViewModel extends ChangeNotifier {
  final DeporteRepository deporteRepository;
  final String idDeporte;

  Deporte? _deporte;
  List<Sesion> _sesiones = const [];
  bool _deportesListos = false;
  bool _sesionesListas = false;
  bool _fallo = false;
  bool _descartado = false;

  // Patrón Observador: los cupos y el horario llegan en vivo.
  StreamSubscription<List<Deporte>>? _deporteSubscription;
  StreamSubscription<List<Sesion>>? _sesionesSubscription;

  DetalleDisciplinaViewModel({
    required this.deporteRepository,
    required this.idDeporte,
  });

  Deporte? get deporte => _deporte;

  /// Sesiones de lunes a domingo y, dentro de cada día, por hora.
  List<Sesion> get sesiones => _sesiones;

  DetalleEstado get estado {
    if (_fallo) return DetalleEstado.error;
    if (!_deportesListos) return DetalleEstado.cargando;
    if (_deporte == null) return DetalleEstado.noExiste;
    if (!_sesionesListas) return DetalleEstado.cargando;
    return DetalleEstado.listo;
  }

  /// Fracción de cupos ocupados, de 0 a 1, para la barra de ocupación.
  double get ocupacion {
    final deporte = _deporte;
    if (deporte == null || deporte.cupoMaximo <= 0) return 0;
    return (deporte.inscritos / deporte.cupoMaximo).clamp(0.0, 1.0);
  }

  /// Empieza a observar la disciplina. La pantalla la llama al abrirse, y de
  /// nuevo si el usuario pide reintentar.
  void cargar() {
    _cancelarSuscripciones();
    _deporte = null;
    _sesiones = const [];
    _deportesListos = false;
    _sesionesListas = false;
    _fallo = false;
    _notificar();

    // Se observa el catálogo visible y se busca la disciplina por su id: así
    // los cupos cambian solos y, si la ocultan, se avisa.
    _deporteSubscription = deporteRepository.observarDeportes().listen((
      deportes,
    ) {
      _deporte = deportes.where((d) => d.id == idDeporte).firstOrNull;
      _deportesListos = true;
      _notificar();
    }, onError: (Object _) => _fallar());

    _sesionesSubscription = deporteRepository
        .observarSesiones(idDeporte)
        .listen((sesiones) {
          _sesiones = [...sesiones]
            ..sort((a, b) {
              final porDia = a.dia.index.compareTo(b.dia.index);
              return porDia != 0
                  ? porDia
                  : a.horaInicio.compareTo(b.horaInicio);
            });
          _sesionesListas = true;
          _notificar();
        }, onError: (Object _) => _fallar());
  }

  void _fallar() {
    _fallo = true;
    _notificar();
  }

  void _cancelarSuscripciones() {
    _deporteSubscription?.cancel();
    _sesionesSubscription?.cancel();
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
