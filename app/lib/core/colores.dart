import 'package:flutter/material.dart';

/// Paleta de colores de Samán Deportivo, tomada del prototipo en Figma.
///
/// Las pantallas usan estas constantes en lugar de escribir los códigos
/// de color a mano, para que un cambio de estilo se haga en un solo lugar.
abstract final class ColoresSaman {
  /// Color principal: botones, enlaces y elementos activos.
  static const Color naranja = Color(0xFFF37021);

  /// Fondo suave para destacar elementos sobre el naranja.
  static const Color naranjaSuave = Color(0xFFFFF3EC);

  /// Títulos y textos principales.
  static const Color azulOscuro = Color(0xFF1E293B);

  /// Etiquetas de los campos de los formularios.
  static const Color textoCampo = Color(0xFF334155);

  /// Subtítulos y textos de apoyo.
  static const Color textoSecundario = Color(0xFF64748B);

  /// Textos de ayuda dentro de los campos.
  static const Color textoTenue = Color(0xFFA0AEC0);

  /// Textos poco importantes, como el pie de las tarjetas.
  static const Color textoDiscreto = Color(0xFF94A3B8);

  /// Fondo de las pantallas: un gris con un toque azul, para que las
  /// tarjetas blancas resalten.
  static const Color fondo = Color(0xFFF2F4FA);

  /// Relleno de los campos y bordes suaves.
  static const Color gris = Color(0xFFF1F2F4);

  /// Estados positivos, como un envío exitoso.
  static const Color verde = Color(0xFF16A34A);

  /// Errores y acciones que no se pueden deshacer, como cerrar sesión.
  static const Color rojo = Color(0xFFEF4444);

  /// Fondo de las tarjetas.
  static const Color blanco = Colors.white;

  // -------------------------------------------------------------------------
  // Rediseño: azul noche para barras y portadas, y acentos para distinguir
  // cada sección (el naranja sigue siendo el color de la marca).
  // -------------------------------------------------------------------------

  /// Barras superiores y portadas.
  static const Color azulNoche = Color(0xFF0B1530);

  /// Final del degradado de las portadas.
  static const Color azulProfundo = Color(0xFF1B2B6B);

  static const Color indigo = Color(0xFF6366F1);
  static const Color cielo = Color(0xFF0EA5E9);
  static const Color menta = Color(0xFF14B8A6);
  static const Color violeta = Color(0xFF8B5CF6);
  static const Color ambar = Color(0xFFF59E0B);
  static const Color rosa = Color(0xFFEC4899);

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
