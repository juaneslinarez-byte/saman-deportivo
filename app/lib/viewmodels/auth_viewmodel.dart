import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final UsuarioRepository usuarioRepository;

  bool _cargando = false;
  String? _error;

  AuthViewModel({
    required this.authRepository,
    required this.usuarioRepository,
  });

  bool get cargando => _cargando;
  String? get error => _error;

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
}
