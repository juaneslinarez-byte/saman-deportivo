import '../modelos/modelos.dart';
import 'formatos.dart';
import 'horarios.dart';

/// Validadores de los formularios.
///
/// Cada función recibe el texto del campo y devuelve el mensaje de error, o
/// null si el valor es válido, como lo espera `TextFormField.validator`. Las
/// reglas buscan que solo se guarden datos que podrían ser reales: un nombre
/// no puede ser «12345», ni una cédula «11111111».
abstract final class Validadores {
  /// Dominio del correo institucional de la UNIMET.
  static const String dominioInstitucional = '@correo.unimet.edu.ve';

  static const int largoMinimoContrasena = 8;

  /// El carnet de la UNIMET tiene 11 dígitos y empieza por el año de
  /// ingreso, por ejemplo 20231110245.
  static const int largoCarnet = 11;
  static const int primerAnioCarnet = 1990;

  static final RegExp _palabra = RegExp('^[${Formatos.letras}]+\$');
  static final RegExp _vocal = RegExp('[aeiouyáéíóúüAEIOUYÁÉÍÓÚÜ]');
  static final RegExp _tresIguales = RegExp(r'(.)\1\1', caseSensitive: false);

  static String? requerido(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Cuenta
  // ---------------------------------------------------------------------

  /// Solo correos institucionales: el sistema es para la comunidad UNIMET.
  static String? correoInstitucional(String? valor) {
    final correo = Formatos.correo(valor ?? '');
    if (correo.isEmpty) return 'Escribe tu correo institucional';
    if (!correo.endsWith(dominioInstitucional)) {
      return 'Usa tu correo institucional ($dominioInstitucional)';
    }
    final usuario = correo.substring(
      0,
      correo.length - dominioInstitucional.length,
    );
    if (usuario.length < 3) return 'El correo no es válido';
    // Letras y números, separados por un punto, guion o guion bajo:
    // «juan.perez», «jperez_2».
    if (!RegExp(r'^[a-z0-9]+([._-][a-z0-9]+)*$').hasMatch(usuario) ||
        !RegExp('[a-z]').hasMatch(usuario)) {
      return 'El correo no es válido';
    }
    return null;
  }

  /// Al iniciar sesión solo se pide la contraseña: las reglas de creación
  /// no se aplican a cuentas que ya existen.
  static String? contrasenaIngreso(String? valor) {
    if (valor == null || valor.isEmpty) return 'Escribe tu contraseña';
    return null;
  }

  /// Contraseñas tan comunes que se adivinan en segundos.
  static const Set<String> _contrasenasComunes = {
    '12345678',
    '123456789',
    'password1',
    'contraseña1',
    'contrasena1',
    'qwerty123',
    'abc12345',
    'unimet123',
    'unimet2026',
    'samandeportivo1',
  };

  /// Requisitos que se muestran mientras se escribe la contraseña nueva.
  static List<(String, bool)> requisitosContrasena(String contrasena) => [
    (
      'Al menos $largoMinimoContrasena caracteres',
      contrasena.length >= largoMinimoContrasena,
    ),
    ('Una letra', RegExp('[${Formatos.letras}]').hasMatch(contrasena)),
    ('Un número', RegExp(r'\d').hasMatch(contrasena)),
  ];

  static String? contrasenaNueva(String? valor, {String correo = ''}) {
    final contrasena = valor ?? '';
    if (contrasena.isEmpty) return 'Crea una contraseña';
    if (contrasena.contains(RegExp(r'\s'))) {
      return 'La contraseña no puede tener espacios';
    }
    if (contrasena.length < largoMinimoContrasena) {
      return 'Debe tener al menos $largoMinimoContrasena caracteres';
    }
    if (requisitosContrasena(contrasena).any((r) => !r.$2)) {
      return 'Combina letras y números';
    }
    final usuario = Formatos.correo(correo).split('@').first;
    if (usuario.length >= 3 && contrasena.toLowerCase().contains(usuario)) {
      return 'No uses tu correo dentro de la contraseña';
    }
    if (_contrasenasComunes.contains(contrasena.toLowerCase()) ||
        RegExp(r'(.)\1{3}').hasMatch(contrasena)) {
      return 'Es muy fácil de adivinar: elige otra';
    }
    return null;
  }

  static String? confirmacion(String? valor, String contrasena) {
    if (valor == null || valor.isEmpty) return 'Repite tu contraseña';
    if (valor != contrasena) return 'Las contraseñas no coinciden';
    return null;
  }

  // ---------------------------------------------------------------------
  // Datos personales
  // ---------------------------------------------------------------------

  /// Nombre o apellido: de 2 a 30 letras, hasta 4 palabras («María de los
  /// Ángeles»), con guion o apóstrofo entre letras («Pérez-Rojas»).
  static String? nombrePropio(String? valor, {String campo = 'nombre'}) {
    final texto = Formatos.espacios(valor ?? '');
    if (texto.isEmpty) return 'Escribe tu $campo';
    if (texto.length < 2) return 'El $campo es muy corto';
    if (texto.length > 30) return 'Máximo 30 caracteres';
    final palabras = texto.split(' ');
    if (palabras.length > 4) return 'Máximo 4 palabras';
    for (final palabra in palabras) {
      final partes = palabra.split(RegExp(r"[-']"));
      if (partes.any((p) => !_palabra.hasMatch(p))) {
        return 'Usa solo letras';
      }
      final esParticula = {'y', 'e'}.contains(palabra.toLowerCase());
      if (palabra.length < 2 && !esParticula) {
        return 'Escribe el $campo completo, sin iniciales';
      }
      if (!_vocal.hasMatch(palabra)) return 'Escribe un $campo real';
    }
    if (_tresIguales.hasMatch(texto)) return 'Revisa las letras repetidas';
    return null;
  }

  /// Número de la cédula, sin prefijo ni puntos. Venezolana (V): 7 u 8
  /// dígitos; extranjera (E): de 7 a 9. No acepta números de relleno como
  /// 11111111 o 12345678.
  static String? cedula(String? valor, {String prefijo = 'V'}) {
    final numero = valor?.trim() ?? '';
    if (numero.isEmpty) return 'Escribe tu número de cédula';
    if (!RegExp(r'^\d+$').hasMatch(numero)) return 'Usa solo números';
    // Las cédulas venezolanas tienen 7 dígitos (las más antiguas) u 8 (las
    // de quienes nacieron desde los años 90, como los estudiantes de hoy).
    // Las de extranjeros pueden llegar a 9.
    final maximo = prefijo == 'E' ? 9 : 8;
    if (numero.length < 7 || numero.length > maximo) {
      return prefijo == 'E'
          ? 'Debe tener entre 7 y 9 dígitos'
          : 'Debe tener 7 u 8 dígitos';
    }
    if (numero.startsWith('0')) return 'No puede empezar por 0';
    if (_esRelleno(numero)) return 'Escribe tu cédula real';
    if (prefijo == 'V' && int.parse(numero) > 40000000) {
      return 'Revisa el número: es mayor que el de cualquier cédula V';
    }
    return null;
  }

  /// Carnet de la UNIMET: 11 dígitos que empiezan por un año de ingreso
  /// posible (entre $primerAnioCarnet y el año actual).
  static String? carnet(String? valor, {DateTime? hoy}) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu carnet';
    if (!RegExp(r'^\d+$').hasMatch(texto)) return 'Usa solo números';
    if (texto.length != largoCarnet) {
      return 'Debe tener $largoCarnet dígitos, por ejemplo 20231110245';
    }
    final anio = int.parse(texto.substring(0, 4));
    final anioActual = (hoy ?? DateTime.now()).year;
    if (anio < primerAnioCarnet || anio > anioActual) {
      return 'Debe empezar por tu año de ingreso, por ejemplo $anioActual';
    }
    if (_esRelleno(texto)) return 'Escribe tu carnet real';
    return null;
  }

  /// Una opción elegida de una lista cerrada, como la carrera.
  static String? opcion(
    String? valor,
    List<String> opciones, {
    String campo = 'una opción',
  }) {
    if (valor == null || !opciones.contains(valor)) return 'Selecciona $campo';
    return null;
  }

  /// Fecha de una clase al tomar la asistencia (RF-ENT-03): tiene que caer
  /// el mismo día de la semana de la sesión y no puede estar en el futuro.
  static String? fechaDeClase(DateTime? fecha, DiaSemana dia, {DateTime? hoy}) {
    if (fecha == null) return 'Selecciona la fecha de la clase';
    final ahora = hoy ?? DateTime.now();
    final hoySinHora = DateTime(ahora.year, ahora.month, ahora.day);
    if (DateTime(fecha.year, fecha.month, fecha.day).isAfter(hoySinHora)) {
      return 'No puedes tomar la asistencia de una fecha futura';
    }
    if (Horarios.diaDe(fecha) != dia) {
      final nombre = Horarios.nombreDia(dia);
      // «los lunes», pero «los sábados» y «los domingos».
      final plural = nombre.endsWith('o') ? '${nombre}s' : nombre;
      return 'Esta clase es los $plural: elige una fecha que caiga $nombre';
    }
    return null;
  }

  /// Textos como el cargo: de 3 a 50 caracteres, con letras y sin números.
  static String? textoDescriptivo(String? valor, {String campo = 'este dato'}) {
    final texto = Formatos.espacios(valor ?? '');
    if (texto.isEmpty) return 'Escribe $campo';
    if (texto.length < 3) return 'Es muy corto';
    if (texto.length > 50) return 'Máximo 50 caracteres';
    if (!RegExp("^[${Formatos.letras}' .,()-]+\$").hasMatch(texto)) {
      return 'Usa solo letras';
    }
    if (!_vocal.hasMatch(texto) || _tresIguales.hasMatch(texto)) {
      return 'Escribe $campo real';
    }
    return null;
  }

  /// Años de experiencia del entrenador: un número entero entre 0 y 50.
  static String? aniosExperiencia(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tus años de experiencia';
    final anios = int.tryParse(texto);
    if (anios == null) return 'Usa solo números';
    if (anios > 50) return 'Debe estar entre 0 y 50';
    return null;
  }

  /// Todos los dígitos iguales (11111111) o seguidos (12345678, 87654321).
  static bool _esRelleno(String digitos) {
    if (RegExp(r'^(\d)\1+$').hasMatch(digitos)) return true;
    final d = digitos.codeUnits;
    bool seguidos(int paso) {
      for (var i = 1; i < d.length; i++) {
        if (d[i] - d[i - 1] != paso) return false;
      }
      return true;
    }

    return seguidos(1) || seguidos(-1);
  }
}
