import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga del horario de la disciplina.
enum InscripcionEstado { cargando, listo, error }

/// Lo que muestra «Inscripción confirmada»: la disciplina, con los cupos ya
/// descontados, y su horario.
class ResumenInscripcion {
  const ResumenInscripcion({required this.deporte, required this.sesiones});

  final Deporte deporte;
  final List<Sesion> sesiones;
}

/// Inscribirse en una disciplina (CU-03, RF-EST-04).
///
/// Las reglas de cupo, solvencia y duplicado las aplica el repositorio
/// (RF-SIS-01, RF-SIS-02 y RF-SIS-04); aquí solo se muestra el resultado.
class InscripcionViewModel extends ChangeNotifier {
  final InscripcionRepository inscripcionRepository;
  final DeporteRepository deporteRepository;

  Deporte _deporte;
  List<Sesion> _sesiones = const [];
  InscripcionEstado _estado = InscripcionEstado.cargando;
  bool _procesando = false;
  String? _error;
  bool _descartado = false;

  // Patrón Observador: el horario y los cupos llegan en tiempo real.
  StreamSubscription<List<Sesion>>? _sesionesSubscription;
  StreamSubscription<List<Deporte>>? _deporteSubscription;

  InscripcionViewModel({
    required this.inscripcionRepository,
    required this.deporteRepository,
    required this._deporte,
  });

  /// La disciplina elegida, con los cupos más recientes que se conocen.
  Deporte get deporte => _deporte;
  List<Sesion> get sesiones => _sesiones;
  InscripcionEstado get estado => _estado;
  bool get procesando => _procesando;
  String? get error => _error;

  ResumenInscripcion get resumen =>
      ResumenInscripcion(deporte: _deporte, sesiones: _sesiones);

  /// Empieza a observar el horario y los cupos. La pantalla la llama al
  /// abrirse, y de nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = InscripcionEstado.cargando;
    _sesionesSubscription?.cancel();
    _deporteSubscription?.cancel();

    _sesionesSubscription = deporteRepository
        .observarSesiones(_deporte.id)
        .listen(
          (sesiones) {
            _sesiones = sesiones;
            _estado = InscripcionEstado.listo;
            _notificar();
          },
          onError: (Object _) {
            _estado = InscripcionEstado.error;
            _notificar();
          },
        );

    _deporteSubscription = deporteRepository.observarDeportes().listen(
      (deportes) {
        for (final deporte in deportes) {
          if (deporte.id == _deporte.id) {
            _deporte = deporte;
            _notificar();
          }
        }
      },
      onError: (Object _) {
        // Si fallan los cupos en vivo, se sigue con los últimos conocidos: el
        // repositorio vuelve a revisar el cupo al inscribir.
      },
    );
  }

  /// Motivo por el que no se puede confirmar, para avisarlo antes de
  /// intentarlo. Es `null` si todo está en orden.
  String? motivoBloqueo(Persona? perfil) {
    if (perfil is! Estudiante) return 'No se encontró tu perfil de estudiante.';
    if (!perfil.solvente) return MotivoRechazo.noSolvente.mensaje;
    if (!_deporte.hayCupo) return MotivoRechazo.sinCupo.mensaje;
    return null;
  }

  /// Inscribe al estudiante en [deporte]. Devuelve `true` si quedó inscrito;
  /// si no, deja el motivo en [error].
  Future<bool> inscribir(Persona? perfil, Deporte deporte) async {
    // Evita el doble toque mientras se procesa.
    if (_procesando) return false;

    if (perfil is! Estudiante) {
      _error = 'No se encontró tu perfil de estudiante.';
      _notificar();
      return false;
    }

    _procesando = true;
    _error = null;
    _notificar();

    try {
      await inscripcionRepository.inscribir(perfil, deporte);
      await _actualizarCupos(deporte.id);
      return true;
    } on InscripcionRechazada catch (e) {
      _error = e.motivo.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo completar la inscripción. Intenta de nuevo.';
      return false;
    } finally {
      _procesando = false;
      _notificar();
    }
  }

  /// Pide los cupos ya descontados para mostrarlos en «Inscripción
  /// confirmada». Si falla, se queda con lo último que llegó en vivo: la
  /// inscripción ya se hizo y no debe contarse como fallida.
  Future<void> _actualizarCupos(String idDeporte) async {
    try {
      final actual = await deporteRepository.obtener(idDeporte);
      if (actual != null) _deporte = actual;
    } catch (_) {
      // Se conserva el deporte que ya se tenía.
    }
  }

  /// Evita avisar a la pantalla cuando ya se cerró (por ejemplo, si la
  /// inscripción termina después de que el usuario salió).
  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _sesionesSubscription?.cancel();
    _deporteSubscription?.cancel();
    super.dispose();
  }
}
