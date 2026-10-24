import 'dart:async';

import 'package:saman_deportivo/repositorios/repositorios.dart';

class _Cuenta {
  _Cuenta(this.id, this.contrasena);

  final String id;
  final String contrasena;
}

/// Repositorio de autenticacion falso: guarda las cuentas en memoria.
///
/// Sirve para probar ViewModels sin Firebase. Poniendo [debeFallar] en true,
/// todas las operaciones lanzan [ErrorAutenticacion] con [mensajeError].
class FakeAuthRepository implements AuthRepository {
  final Map<String, _Cuenta> _cuentas = {};
  final StreamController<String?> _controlador =
      StreamController<String?>.broadcast();

  String? _idActual;
  int _contador = 0;

  /// Si es true, las operaciones fallan como si Firebase rechazara la solicitud.
  bool debeFallar = false;
  String mensajeError = 'Error de autenticacion.';

  /// Correos a los que se pidio recuperar la contrasena.
  final List<String> correosRecuperacion = [];

  /// Crea una cuenta ya existente, para probar el inicio de sesion.
  String agregarCuenta({
    required String correo,
    required String contrasena,
    String? id,
  }) {
    final idCuenta = id ?? 'u${++_contador}';
    _cuentas[correo] = _Cuenta(idCuenta, contrasena);
    return idCuenta;
  }

  @override
  Stream<String?> observarSesion() => _controlador.stream;

  @override
  String? get idUsuarioActual => _idActual;

  @override
  Future<String> registrar({
    required String correo,
    required String contrasena,
  }) async {
    if (debeFallar) throw ErrorAutenticacion(mensajeError);
    if (_cuentas.containsKey(correo)) {
      throw const ErrorAutenticacion('El correo ya esta registrado.');
    }
    final id = agregarCuenta(correo: correo, contrasena: contrasena);
    _abrirSesion(id);
    return id;
  }

  @override
  Future<String> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    if (debeFallar) throw ErrorAutenticacion(mensajeError);
    final cuenta = _cuentas[correo];
    if (cuenta == null || cuenta.contrasena != contrasena) {
      throw const ErrorAutenticacion('Correo o contrasena incorrectos.');
    }
    _abrirSesion(cuenta.id);
    return cuenta.id;
  }

  @override
  Future<void> cerrarSesion() async {
    _idActual = null;
    _controlador.add(null);
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) async {
    if (debeFallar) throw ErrorAutenticacion(mensajeError);
    correosRecuperacion.add(correo);
  }

  void _abrirSesion(String id) {
    _idActual = id;
    _controlador.add(id);
  }

  /// Cierra el stream. Llamarlo en tearDown si el test lo escucha.
  Future<void> cerrar() => _controlador.close();
}
