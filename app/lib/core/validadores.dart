/// Validadores de los formularios.
///
/// Cada función recibe el texto del campo y devuelve el mensaje de error, o
/// null si el valor es válido, como lo espera `TextFormField.validator`.
abstract final class Validadores {
  /// Dominio del correo institucional de la UNIMET.
  static const String dominioInstitucional = '@correo.unimet.edu.ve';

  /// Firebase Authentication exige al menos 6 caracteres.
  static const int largoMinimoContrasena = 6;

  static String? requerido(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  /// Solo se aceptan correos institucionales: el sistema es para la
  /// comunidad UNIMET.
  static String? correoInstitucional(String? valor) {
    final correo = valor?.trim().toLowerCase() ?? '';
    if (correo.isEmpty) return 'Ingresa tu correo';
    final usuario = correo.endsWith(dominioInstitucional)
        ? correo.substring(0, correo.length - dominioInstitucional.length)
        : null;
    if (usuario == null) return 'Debe terminar en $dominioInstitucional';
    if (usuario.isEmpty || usuario.contains('@') || usuario.contains(' ')) {
      return 'El correo no es válido';
    }
    return null;
  }

  static String? contrasena(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
    if (valor.length < largoMinimoContrasena) {
      return 'Debe tener al menos $largoMinimoContrasena caracteres';
    }
    return null;
  }

  /// Comprueba que la confirmación coincida con la contraseña escrita.
  static String? confirmacion(String? valor, String contrasena) {
    if (valor == null || valor.isEmpty) return 'Repite tu contraseña';
    if (valor != contrasena) return 'Las contraseñas no coinciden';
    return null;
  }
}
