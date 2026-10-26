import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final UsuarioRepository usuarioRepository;

  bool _cargando = false;
  String? _error;

  // Patrón Observador: escucha a Firebase Authentication y avisa a las
  // vistas cada vez que la sesión empieza o termina.
  StreamSubscription<String?>? _sesionSubscription;
  String? _idUsuarioActual;

  AuthViewModel({
    required this.authRepository,
    required this.usuarioRepository,
  }) {
    _sesionSubscription = authRepository.observarSesion().listen((id) {
      _idUsuarioActual = id;
      notifyListeners();
    });
  }

  bool get cargando => _cargando;
  String? get error => _error;

  /// Id del usuario con sesión iniciada, o null si no hay sesión.
  String? get idUsuarioActual => _idUsuarioActual;

  /// Indica si hay un usuario con sesión iniciada.
  bool get estaAutenticado => _idUsuarioActual != null;

  Future<bool> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final id = await authRepository.iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );
      final perfil = await usuarioRepository.obtener(id);
      if (perfil == null || !perfil.habilitado) {
        await authRepository.cerrarSesion();
        _error = 'Esta cuenta está deshabilitada.';
        return false;
      }
      return true;
    } on ErrorAutenticacion catch (e) {
      _error = e.mensaje;
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> registrar({
    required String nombre,
    required String apellido,
    required String cedula,
    required String carnet,
    required String carrera,
    required String correo,
    required String contrasena,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final id = await authRepository.registrar(
        correo: correo,
        contrasena: contrasena,
      );
      final estudiante = Estudiante(
        id: id,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        carnet: carnet,
        carrera: carrera,
        correo: correo,
      );
      await usuarioRepository.crear(estudiante);
      return true;
    } on ErrorAutenticacion catch (e) {
      _error = e.mensaje;
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await authRepository.cerrarSesion();
    } on ErrorAutenticacion catch (e) {
      _error = e.mensaje;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> recuperarPassword(String correo) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await authRepository.enviarCorreoRecuperacion(correo);
      return true;
    } on ErrorAutenticacion catch (e) {
      _error = e.mensaje;
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sesionSubscription?.cancel();
    super.dispose();
  }
}
