import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga de la nómina.
enum NominaEstado { cargando, listo, error }

/// Solvencia de un inscrito según su perfil. Queda en [verificando]
/// mientras llega el perfil y en [desconocida] si no se pudo leer.
enum Solvencia { verificando, solvente, noSolvente, desconocida }

/// Una fila de la nómina: el inscrito y su solvencia.
class FilaNomina {
  const FilaNomina({
    required this.inscripcion,
    required this.nombre,
    required this.carnet,
    required this.solvencia,
  });

  final Inscripcion inscripcion;
  final String nombre;
  final String carnet;
  final Solvencia solvencia;
}

/// Nómina de una disciplina: los inscritos activos con su carnet y su
/// solvencia (RF-ENT-02, RF-ENT-05).
///
/// El nombre y el carnet vienen copiados en la inscripción. La solvencia se
/// lee del perfil de cada estudiante; si un perfil no carga, la fila se
/// muestra igual con la solvencia «desconocida».
class NominaViewModel extends ChangeNotifier {
  final InscripcionRepository inscripcionRepository;
  final UsuarioRepository usuarioRepository;
  final String idDeporte;

  List<Inscripcion> _inscripciones = const [];
  final Map<String, Persona?> _perfiles = {};
  final Set<String> _perfilesConError = {};
  NominaEstado _estado = NominaEstado.cargando;
  bool _descartado = false;

  // Patrón Observador: la nómina y la solvencia llegan en vivo, por ejemplo
  // cuando un estudiante cancela o el administrador aprueba un pago.
  StreamSubscription<List<Inscripcion>>? _inscripcionesSubscription;
  final Map<String, StreamSubscription<Persona?>> _perfilesSubs = {};

  NominaViewModel({
    required this.inscripcionRepository,
    required this.usuarioRepository,
    required this.idDeporte,
  });

  NominaEstado get estado => _estado;

  /// Inscritos activos, ordenados por nombre.
  List<FilaNomina> get filas {
    final lista = [
      for (final inscripcion in _inscripciones)
        FilaNomina(
          inscripcion: inscripcion,
          nombre: _nombreDe(inscripcion),
          carnet: inscripcion.carnetEstudiante,
          solvencia: _solvenciaDe(inscripcion.idEstudiante),
        ),
    ];
    lista.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return lista;
  }

  int get totalInscritos => _inscripciones.length;

  int get totalNoSolventes => _inscripciones
      .where((i) => _solvenciaDe(i.idEstudiante) == Solvencia.noSolvente)
      .length;

  /// Empieza a observar la nómina. La pantalla la llama al abrirse, y de
  /// nuevo si el usuario pide reintentar.
  void cargar() {
    _estado = NominaEstado.cargando;
    _cancelarSuscripciones();
    _notificar();

    _inscripcionesSubscription = inscripcionRepository
        .observarPorDeporte(idDeporte)
        .listen(
          (inscripciones) {
            // Las canceladas quedan en el historial, pero no en la nómina.
            _inscripciones = [
              for (final inscripcion in inscripciones)
                if (inscripcion.estaActiva) inscripcion,
            ];
            _observarPerfiles();
            _estado = NominaEstado.listo;
            _notificar();
          },
          onError: (Object _) {
            _estado = NominaEstado.error;
            _notificar();
          },
        );
  }

  /// Observa el perfil de cada inscrito para conocer su solvencia, y deja de
  /// observar los que ya no están en la nómina.
  void _observarPerfiles() {
    final necesarios = {
      for (final inscripcion in _inscripciones) inscripcion.idEstudiante,
    };

    for (final id in _perfilesSubs.keys.toList()) {
      if (necesarios.contains(id)) continue;
      _perfilesSubs.remove(id)?.cancel();
      _perfiles.remove(id);
      _perfilesConError.remove(id);
    }

    for (final id in necesarios) {
      if (_perfilesSubs.containsKey(id)) continue;
      _perfilesSubs[id] = usuarioRepository
          .observar(id)
          .listen(
            (persona) {
              _perfiles[id] = persona;
              _perfilesConError.remove(id);
              _notificar();
            },
            onError: (Object _) {
              // La fila se sigue mostrando, con la solvencia desconocida.
              _perfilesConError.add(id);
              _notificar();
            },
          );
    }
  }

  Solvencia _solvenciaDe(String idEstudiante) {
    if (_perfilesConError.contains(idEstudiante)) return Solvencia.desconocida;
    if (!_perfiles.containsKey(idEstudiante)) return Solvencia.verificando;
    final perfil = _perfiles[idEstudiante];
    if (perfil is! Estudiante) return Solvencia.desconocida;
    return perfil.solvente ? Solvencia.solvente : Solvencia.noSolvente;
  }

  /// El nombre copiado en la inscripción; si falta, el del perfil.
  String _nombreDe(Inscripcion inscripcion) {
    if (inscripcion.nombreEstudiante.trim().isNotEmpty) {
      return inscripcion.nombreEstudiante;
    }
    return _perfiles[inscripcion.idEstudiante]?.nombreCompleto ??
        'Estudiante sin nombre';
  }

  void _cancelarSuscripciones() {
    _inscripcionesSubscription?.cancel();
    for (final suscripcion in _perfilesSubs.values) {
      suscripcion.cancel();
    }
    _perfilesSubs.clear();
    _perfiles.clear();
    _perfilesConError.clear();
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
