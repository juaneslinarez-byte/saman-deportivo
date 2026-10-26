import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

/// Implementación de [AuthRepository] con Firebase Authentication
/// (correo y contraseña).
///
/// Los errores de Firebase se convierten en [ErrorAutenticacion] con un
/// mensaje en español, listo para mostrarle al usuario.
class AuthRepositoryFirebase implements AuthRepository {
  AuthRepositoryFirebase({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<String?> observarSesion() =>
      _auth.authStateChanges().map((usuario) => usuario?.uid);

  @override
  String? get idUsuarioActual => _auth.currentUser?.uid;

  @override
  Future<String> registrar({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
      return credencial.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<String> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
      return credencial.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Future<void> enviarCorreoRecuperacion(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } on FirebaseAuthException catch (e) {
      throw _traducir(e);
    }
  }

  /// Convierte el código de error de Firebase en un mensaje en español.
  ErrorAutenticacion _traducir(FirebaseAuthException e) {
    final mensaje = switch (e.code) {
      'invalid-email' => 'El correo no es válido.',
      'missing-email' => 'Escribe tu correo.',
      'missing-password' => 'Escribe tu contraseña.',
      'user-disabled' => 'Esta cuenta está deshabilitada.',
      // Firebase ya no distingue entre correo inexistente y contraseña
      // incorrecta, para no revelar qué correos están registrados.
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'weak-password' =>
        'La contraseña es muy débil. Usa al menos 6 caracteres.',
      'operation-not-allowed' =>
        'El inicio de sesión con correo no está habilitado.',
      'too-many-requests' =>
        'Demasiados intentos. Espera un momento y vuelve a intentarlo.',
      'network-request-failed' =>
        'No hay conexión a internet. Revisa tu conexión.',
      _ => 'Ocurrió un error de autenticación. Inténtalo de nuevo.',
    };
    return ErrorAutenticacion(mensaje);
  }
}
