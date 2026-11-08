import 'package:flutter/material.dart';

/// Paleta de colores de Samán Deportivo: el verde del samán y el naranja de
/// la UNIMET sobre un fondo crema (dirección «C» elegida el 08/11/2026).
///
/// Las pantallas usan estas constantes en lugar de escribir los códigos
/// de color a mano, para que un cambio de estilo se haga en un solo lugar.
abstract final class ColoresSaman {
  /// Color principal: botones, enlaces y elementos activos.
  static const Color naranja = Color(0xFFF37021);

  /// Fondo suave para destacar elementos sobre el naranja.
  static const Color naranjaSuave = Color(0xFFFDE7D8);

  /// Títulos y textos principales.
  static const Color azulOscuro = Color(0xFF0F241C);

  /// Etiquetas de los campos de los formularios.
  static const Color textoCampo = Color(0xFF23372E);

  /// Subtítulos y textos de apoyo.
  static const Color textoSecundario = Color(0xFF5B6B63);

  /// Textos de ayuda dentro de los campos.
  static const Color textoTenue = Color(0xFF98A69F);

  /// Textos poco importantes, como el pie de las tarjetas.
  static const Color textoDiscreto = Color(0xFF8A978F);

  /// Fondo de las pantallas: un gris con un toque azul, para que las
  /// tarjetas blancas resalten.
  static const Color fondo = Color(0xFFF6F4EE);

  /// Relleno de los campos y bordes suaves.
  static const Color gris = Color(0xFFEFEBE2);

  /// Estados positivos, como un envío exitoso.
  static const Color verde = Color(0xFF15803D);

  /// Errores y acciones que no se pueden deshacer, como cerrar sesión.
  static const Color rojo = Color(0xFFEF4444);

  /// Fondo de las tarjetas.
  static const Color blanco = Colors.white;

  /// Bordes suaves de tarjetas y campos sobre el fondo crema.
  static const Color borde = Color(0xFFE7E2D6);

  /// Fondo suave para íconos y etiquetas verdes.
  static const Color verdeSuave = Color(0xFFDDF0E6);

  // -------------------------------------------------------------------------
  // Verde Samán para barras y portadas, y acentos de la misma familia para
  // distinguir cada sección. Algunos nombres son de la paleta anterior: se
  // mantienen para no tocar todas las pantallas.
  // -------------------------------------------------------------------------

  /// Verde Samán: barras superiores, portadas y bloques destacados.
  static const Color azulNoche = Color(0xFF0F3D2E);

  /// Verde más oscuro, final del degradado de las portadas.
  static const Color azulProfundo = Color(0xFF0A2A1F);

  /// Verde medio.
  static const Color indigo = Color(0xFF0F7A55);
  static const Color cielo = Color(0xFF0E7490);
  static const Color menta = Color(0xFF14B8A6);

  /// Tierra (antes violeta).
  static const Color violeta = Color(0xFF8B5E34);
  static const Color ambar = Color(0xFFD97706);

  /// Coral (antes rosa).
  static const Color rosa = Color(0xFFDB5C3A);

  /// Degradado de las portadas de cada pantalla.
  static const LinearGradient degradadoNoche = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulNoche, azulProfundo],
  );

  /// Degradado de los botones y elementos destacados.
  static const LinearGradient degradadoNaranja = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [naranja, Color(0xFFFF9F43)],
  );

  /// Acentos en orden, para dar un color distinto a cada tarjeta.
  static const List<Color> acentos = [
    naranja,
    indigo,
    menta,
    violeta,
    cielo,
    rosa,
    ambar,
  ];
}
