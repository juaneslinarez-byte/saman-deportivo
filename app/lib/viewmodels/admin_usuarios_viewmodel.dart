import 'package:flutter/foundation.dart';

import '../modelos/modelos.dart';
import '../repositorios/usuario_repository.dart';

class AdminUsuariosViewModel extends ChangeNotifier {
  final UsuarioRepository _usuarioRepository;

  List<Persona> _todosLosUsuarios = [];
  List<Persona> _usuariosFiltrados = [];
  bool _cargando = true;
  String? _error;
  Actor? _filtroActor;
  String _busqueda = '';

  List<Persona> get usuarios => _usuariosFiltrados;
  bool get cargando => _cargando;
  String? get error => _error;
  Actor? get filtroActor => _filtroActor;

  AdminUsuariosViewModel(this._usuarioRepository) {
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    _cargando = true;
    notifyListeners();

    try {
      _todosLosUsuarios = await _usuarioRepository.listar();
      _aplicarFiltros();
      _cargando = false;
      _error = null;
    } catch (e) {
      _cargando = false;
      _error = 'No se pudieron cargar los usuarios.';
    }
    notifyListeners();
  }

  void filtrarPorActor(Actor? actor) {
    _filtroActor = actor;
    _aplicarFiltros();
    notifyListeners();
  }

  void buscar(String query) {
    _busqueda = query.trim().toLowerCase();
    _aplicarFiltros();
    notifyListeners();
  }

  void _aplicarFiltros() {
    _usuariosFiltrados = _todosLosUsuarios.where((u) {
      if (_filtroActor != null) {
        if (_filtroActor == Actor.estudiante && u is! Estudiante) return false;
        if (_filtroActor == Actor.entrenador && u.actor != Actor.entrenador) {
          return false;
        }
        if (_filtroActor == Actor.administrador &&
            u.actor != Actor.administrador) {
          return false;
        }
      }

      if (_busqueda.isNotEmpty) {
        final nombreCompleto = '${u.nombre} ${u.apellido}'.toLowerCase();
        final correo = u.correo.toLowerCase();
        final cedula = u.cedula.toLowerCase();
        final carnet = (u is Estudiante) ? u.carnet.toLowerCase() : '';

        return nombreCompleto.contains(_busqueda) ||
            correo.contains(_busqueda) ||
            cedula.contains(_busqueda) ||
            carnet.contains(_busqueda);
      }
      return true;
    }).toList();
  }

  // Auxiliar para extraer los datos de la Persona hacia un Map
  Map<String, dynamic> _personaToMap(Persona u) {
    final map = <String, dynamic>{
      'nombre': u.nombre,
      'apellido': u.apellido,
      'cedula': u.cedula,
      'correo': u.correo,
      'habilitado': u.habilitado,
      'actor': u.actor.name,
    };
    if (u is Estudiante) {
      map['carnet'] = u.carnet;
      map['carrera'] = u.carrera;
      map['solvente'] = u.solvente;
    }
    return map;
  }

  // ==========================================
  // ACCIONES ADMINISTRATIVAS (CU-18, RF-ADM-05, RF-SIS-07)
  // ==========================================

  Future<void> alternarHabilitado(Persona usuario, String idAdminActual) async {
    if (usuario.id == idAdminActual) {
      throw Exception('El administrador no puede deshabilitarse a sí mismo.');
    }

    final nuevoEstado = !usuario.habilitado;
    late final Persona actualizado;

    if (usuario is Estudiante) {
      actualizado = Estudiante(
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        cedula: usuario.cedula,
        correo: usuario.correo,
        habilitado: nuevoEstado,
        carnet: usuario.carnet,
        carrera: usuario.carrera,
        solvente: usuario.solvente,
      );
    } else {
      final datos = _personaToMap(usuario);
      datos['habilitado'] = nuevoEstado;
      actualizado = Persona.fromMap(usuario.id, datos);
    }

    await _usuarioRepository.actualizarComoAdministrador(actualizado);
    await cargarUsuarios();
  }

  Future<void> alternarSolvente(Persona usuario) async {
    if (usuario is! Estudiante) {
      throw Exception('La solvencia solo se aplica a estudiantes.');
    }
    final e = usuario;
    final actualizado = Estudiante(
      id: e.id,
      nombre: e.nombre,
      apellido: e.apellido,
      cedula: e.cedula,
      correo: e.correo,
      habilitado: e.habilitado,
      carnet: e.carnet,
      carrera: e.carrera,
      solvente: !e.solvente,
    );

    await _usuarioRepository.actualizarComoAdministrador(actualizado);
    await cargarUsuarios();
  }

  Future<void> convertirEnEntrenador({
    required Persona usuario,
    required String especialidad,
    required int aniosExperiencia,
  }) async {
    if (especialidad.trim().isEmpty) {
      throw Exception('La especialidad es obligatoria.');
    }
    if (aniosExperiencia < 0) {
      throw Exception(
        'Los años de experiencia deben ser mayores o iguales a 0.',
      );
    }

    final datos = _personaToMap(usuario);
    datos['actor'] = 'entrenador';
    datos['especialidad'] = especialidad.trim();
    datos['aniosExperiencia'] = aniosExperiencia;

    final entrenadorActualizado = Persona.fromMap(usuario.id, datos);

    await _usuarioRepository.actualizarComoAdministrador(entrenadorActualizado);
    await cargarUsuarios();
  }
}
