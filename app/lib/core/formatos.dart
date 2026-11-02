import 'dart:math';

import 'package:flutter/services.dart';

/// Normaliza los datos antes de guardarlos, para que se vean igual sin
/// importar cómo los escribió el usuario («  juan   PÉREZ » → «Juan Pérez»).
abstract final class Formatos {
  /// Letras del español, con tildes, diéresis y ñ.
  static const String letras = 'A-Za-zÁÉÍÓÚÜÑáéíóúüñ';

  /// Palabras que van en minúscula dentro de un nombre: «María de los Ángeles».
  static const Set<String> _particulas = {
    'de',
    'del',
    'la',
    'las',
    'los',
    'y',
    'e',
  };

  /// Quita los espacios de los extremos y deja uno solo entre palabras.
  static String espacios(String texto) =>
      texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Nombre o apellido con mayúscula inicial en cada palabra.
  static String nombrePropio(String texto) {
    final palabras = espacios(texto).toLowerCase().split(' ');
    return [
      for (var i = 0; i < palabras.length; i++)
        i > 0 && _particulas.contains(palabras[i])
            ? palabras[i]
            : _capitalizar(palabras[i]),
    ].join(' ');
  }

  /// Mayúscula también después de un guion o un apóstrofo: «O'Brien»,
  /// «Pérez-Rojas».
  static String _capitalizar(String palabra) => palabra.splitMapJoin(
    RegExp(r"[-']"),
    onMatch: (m) => m[0]!,
    onNonMatch: (parte) =>
        parte.isEmpty ? parte : parte[0].toUpperCase() + parte.substring(1),
  );

  /// Textos como el cargo: espacios ordenados y la primera letra en mayúscula.
  static String textoDescriptivo(String texto) {
    final limpio = espacios(texto);
    return limpio.isEmpty
        ? limpio
        : limpio[0].toUpperCase() + limpio.substring(1);
  }

  static String correo(String texto) => texto.trim().toLowerCase();

  /// Cédula guardada siempre igual: «V-28123456».
  static String cedula(String prefijo, String numero) =>
      '$prefijo-${numero.trim()}';

  /// Separa una cédula guardada en su prefijo y su número. Acepta también
  /// las guardadas antes con puntos o sin prefijo («28.123.456»).
  static (String, String) partirCedula(String cedula) {
    final texto = cedula.trim().toUpperCase();
    final prefijo = texto.startsWith('E') ? 'E' : 'V';
    return (prefijo, texto.replaceAll(RegExp(r'\D'), ''));
  }
}

/// Lo que se puede escribir en cada tipo de campo. Bloquea los caracteres
/// que no corresponden mientras el usuario escribe, por ejemplo números en
/// un nombre o letras en la cédula.
abstract final class Entradas {
  static final List<TextInputFormatter> nombre = [
    FilteringTextInputFormatter.allow(RegExp("[${Formatos.letras}' -]")),
    const _EspaciosSimples(),
    LengthLimitingTextInputFormatter(30),
  ];

  static final List<TextInputFormatter> textoDescriptivo = [
    FilteringTextInputFormatter.allow(RegExp("[${Formatos.letras}' .,()-]")),
    const _EspaciosSimples(),
    LengthLimitingTextInputFormatter(50),
  ];

  static final List<TextInputFormatter> correo = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    const _Minusculas(),
    LengthLimitingTextInputFormatter(60),
  ];

  static final List<TextInputFormatter> contrasena = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(64),
  ];

  static List<TextInputFormatter> digitos(int maximo) => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(maximo),
  ];
}

/// No deja empezar con espacio ni escribir dos espacios seguidos.
class _EspaciosSimples extends TextInputFormatter {
  const _EspaciosSimples();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final texto = nuevo.text
        .replaceFirst(RegExp(r'^ +'), '')
        .replaceAll(RegExp(r' {2,}'), ' ');
    if (texto == nuevo.text) return nuevo;
    final quitados = nuevo.text.length - texto.length;
    final cursor = max(0, min(texto.length, nuevo.selection.end - quitados));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class _Minusculas extends TextInputFormatter {
  const _Minusculas();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) => nuevo.copyWith(text: nuevo.text.toLowerCase());
}
