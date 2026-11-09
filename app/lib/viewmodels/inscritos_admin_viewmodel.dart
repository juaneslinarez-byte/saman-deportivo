import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/mensajes.dart';
import '../modelos/modelos.dart';
import '../repositorios/repositorios.dart';

enum InscritosAdminEstado { cargando, listo, error }

/// Inscritos de una disciplina vistos por el administrador: puede inscribir
/// a un estudiante y sacar a quien esté inscrito (RF-ADM-04).
///
/// Usa las mismas transacciones que el estudiante, así el cupo se descuenta
/// o se devuelve en la misma operación y nunca se pasa del cupo máximo.
/// Todo se observa en tiempo real: si un estudiante se inscribe o cancela
/// mientras el administrador mira la lista, la pantalla se actualiza sola.
class InscritosAdminViewModel extends ChangeNotifier {
  InscritosAdminViewModel({
    required this._inscripcionRepository,
    required this._usuarioRepository,
    required this._deporteRepository,
    required this._deporte,
  });

  final InscripcionRepository _inscripcionRepository;
  final UsuarioRepository _usuarioRepository;
  final DeporteRepository _deporteRepository;

  Deporte _deporte;
  List<Inscripcion> _inscripciones = [];
  Map<String, Estudiante> _estudiantes = {};
  InscritosAdminEstado _estado = InscritosAdminEstado.cargando;
  bool _procesando = false;
  bool _cargoInscritos = false;
  bool _cargoEstudiantes = false;

  StreamSubscription<List<Inscripcion>>? _inscripcionesSub;
  StreamSubscription<List<Deporte>>? _deporteSub;

  Deporte get deporte => _deporte;
  InscritosAdminEstado get estado => _estado;

  /// Hay una inscripción o una salida en curso: los botones se desactivan
  /// para no repetirla con un doble clic.
  bool get procesando => _procesando;

  /// Inscritos activos, ordenados por nombre.
  List<Inscripcion> get inscritos {
    final lista = List.of(_inscripciones);
    lista.sort(
      (a, b) => a.nombreEstudiante.toLowerCase().compareTo(
        b.nombreEstudiante.toLowerCase(),
      ),
    );
    return lista;
  }

  /// Perfil del inscrito, para mostrar su solvencia y su carrera. Es nulo
  /// si el perfil ya no existe.
  Estudiante? perfilDe(Inscripcion inscripcion) =>
      _estudiantes[inscripcion.idEstudiante];

  /// Estudiantes que se pueden inscribir: habilitados y sin una inscripción
  /// activa en esta disciplina. Se filtran por nombre, carnet o correo.
  /// Los no solventes aparecen, pero la pantalla no deja elegirlos.
  List<Estudiante> candidatos(String busqueda) {
    final inscritosIds = {for (final i in _inscripciones) i.idEstudiante};
    final consulta = _normalizar(busqueda);
    final lista = _estudiantes.values.where((e) {
      if (!e.habilitado || inscritosIds.contains(e.id)) return false;
      if (consulta.isEmpty) return true;
      return _normalizar(e.nombreCompleto).contains(consulta) ||
          e.carnet.contains(consulta) ||
          e.correo.toLowerCase().contains(consulta);
    }).toList();
    lista.sort((a, b) {
      // Primero los solventes, que son los que se pueden inscribir.
      if (a.solvente != b.solvente) return a.solvente ? -1 : 1;
      return _normalizar(a.nombreCompleto)
          .compareTo(_normalizar(b.nombreCompleto));
    });
    return lista;
  }

  void cargar() {
    _estado = InscritosAdminEstado.cargando;
    _cargoInscritos = false;
    _cargoEstudiantes = false;
    notifyListeners();

    _inscripcionesSub?.cancel();
    _inscripcionesSub = _inscripcionRepository
        .observarPorDeporte(_deporte.id)
        .listen((lista) {
          _inscripciones = lista;
          _cargoInscritos = true;
          _actualizarEstado();
        }, onError: (Object _) => _fallo());

    // El cupo cambia cada vez que alguien entra o sale.
    _deporteSub?.cancel();
    _deporteSub = _deporteRepository
        .observarDeportes(soloVisibles: false)
        .listen((deportes) {
          for (final d in deportes) {
            if (d.id == _deporte.id) {
              _deporte = d;
              notifyListeners();
              return;
            }
          }
        }, onError: (Object _) {});

    recargarEstudiantes();
  }

  /// Vuelve a leer los estudiantes, por ejemplo después de que el
  /// administrador aprobó un pago y alguien pasó a estar solvente.
  Future<void> recargarEstudiantes() async {
    try {
      final personas = await _usuarioRepository.listar(actor: Actor.estudiante);
      _estudiantes = {
        for (final p in personas.whereType<Estudiante>()) p.id: p,
      };
      _cargoEstudiantes = true;
      _actualizarEstado();
    } catch (_) {
      _fallo();
    }
  }

  /// Inscribe al estudiante. Devuelve null si salió bien o el motivo por el
  /// que no se pudo.
  Future<String?> inscribir(Estudiante estudiante) async {
    if (_procesando) return null;
    if (!estudiante.habilitado) {
      return 'La cuenta de ${estudiante.nombreCompleto} está deshabilitada.';
    }
    if (!estudiante.solvente) {
      return '${estudiante.nombreCompleto} no está solvente. Debe tener su '
          'pago aprobado antes de inscribirse.';
    }
    if (!_deporte.hayCupo) {
      return '${_deporte.nombre} no tiene cupos disponibles.';
    }
    return _ejecutar(
      () => _inscripcionRepository.inscribir(estudiante, _deporte),
    );
  }

  /// Saca al estudiante de la disciplina y libera su cupo. La inscripción
  /// queda cancelada en el historial y el estudiante puede volver a
  /// inscribirse.
  Future<String?> sacar(Inscripcion inscripcion) =>
      _ejecutar(() => _inscripcionRepository.cancelar(inscripcion));

  Future<String?> _ejecutar(Future<void> Function() accion) async {
    _procesando = true;
    notifyListeners();
    try {
      await accion();
      return null;
    } on InscripcionRechazada catch (e) {
      return e.motivo == MotivoRechazo.yaInscrito
          ? 'El estudiante ya está inscrito en esta disciplina.'
          : e.motivo.mensaje;
    } catch (e) {
      return mensajeDeError(e);
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  void _actualizarEstado() {
    if (_cargoInscritos && _cargoEstudiantes) {
      _estado = InscritosAdminEstado.listo;
    }
    notifyListeners();
  }

  void _fallo() {
    _estado = InscritosAdminEstado.error;
    notifyListeners();
  }

  static String _normalizar(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().trim().split('')) {
      final i = conTilde.indexOf(letra);
      buffer.write(i == -1 ? letra : sinTilde[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _inscripcionesSub?.cancel();
    _deporteSub?.cancel();
    super.dispose();
  }
}
