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

  /// Letras del español, con tildes y ñ.
  static final RegExp _letra = RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]");

  /// Nombres y apellidos: solo letras, espacios, apóstrofo y guion, de 2 a
  /// 40 caracteres. Así no se aceptan nombres como «12345678».
  static String? nombrePropio(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Este campo es obligatorio';
    if (texto.length < 2) return 'Debe tener al menos 2 letras';
    if (texto.length > 40) return 'Debe tener como máximo 40 caracteres';
    if (!RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]+$").hasMatch(texto)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  /// Cédula venezolana: de 6 a 9 dígitos. Acepta el prefijo V o E y los
  /// puntos o guiones de separación (V-28.123.456).
  static String? cedula(String? valor) {
    final texto = valor?.trim().toUpperCase() ?? '';
    if (texto.isEmpty) return 'Ingresa tu cédula';
    final numero = texto
        .replaceFirst(RegExp(r'^[VE]-?'), '')
        .replaceAll(RegExp(r'[.\-\s]'), '');
    if (!RegExp(r'^\d{6,9}$').hasMatch(numero)) {
      return 'Ingresa entre 6 y 9 dígitos, por ejemplo 28123456';
    }
    return null;
  }

  /// Carnet de la UNIMET: solo números, de 8 a 12 dígitos.
  static String? carnet(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu carnet';
    if (!RegExp(r'^\d{8,12}$').hasMatch(texto)) {
      return 'Solo números, entre 8 y 12 dígitos';
    }
    return null;
  }

  /// Textos descriptivos como la carrera, la especialidad o el cargo: de 3 a
  /// 60 caracteres, con letras y sin números (por ejemplo «Ing. de Sistemas»).
  static String? textoDescriptivo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Este campo es obligatorio';
    if (texto.length < 3) return 'Debe tener al menos 3 caracteres';
    if (texto.length > 60) return 'Debe tener como máximo 60 caracteres';
    if (!RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .,()\-]+$").hasMatch(texto) ||
        !_letra.hasMatch(texto)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  /// Años de experiencia del entrenador: un número entero entre 0 y 60.
  static String? aniosExperiencia(String? valor) {
    final anios = int.tryParse(valor?.trim() ?? '');
    if (anios == null) return 'Ingresa un número entero';
    if (anios < 0 || anios > 60) return 'Debe estar entre 0 y 60';
    return null;
  }

  /// Comprueba que la confirmación coincida con la contraseña escrita.
  static String? confirmacion(String? valor, String contrasena) {
    if (valor == null || valor.isEmpty) return 'Repite tu contraseña';
    if (valor != contrasena) return 'Las contraseñas no coinciden';
    return null;
  }
}
