/// Registro, inicio de sesión y recuperación de contraseña.
///
/// Solo maneja la cuenta (correo y contraseña). Los datos del perfil de cada
/// usuario los guarda [UsuarioRepository].
abstract class AuthRepository {
  /// Emite el id del usuario cada vez que inicia sesión, y null cuando la
  /// cierra. Los ViewModels lo escuchan para reaccionar sin recargar.
  Stream<String?> observarSesion();

  /// Id del usuario con sesión iniciada, o null si no hay sesión.
  String? get idUsuarioActual;

  /// Crea la cuenta y devuelve el id del nuevo usuario.
  Future<String> registrar({
    required String correo,
    required String contrasena,
  });

  /// Inicia sesión y devuelve el id del usuario.
  Future<String> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  Future<void> cerrarSesion();

  /// Envía al correo un enlace para crear una contraseña nueva (RF-SIS-10).
  Future<void> enviarCorreoRecuperacion(String correo);
}

/// Error de autenticación con un mensaje listo para mostrarle al usuario.
class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
