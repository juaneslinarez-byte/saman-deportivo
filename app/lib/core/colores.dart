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

  /// Fondo de las pantallas.
  static const Color fondo = Color(0xFFF8F9FA);

  /// Relleno de los campos y bordes suaves.
  static const Color gris = Color(0xFFF1F2F4);

  /// Estados positivos, como un envío exitoso.
  static const Color verde = Color(0xFF16A34A);

  /// Errores y acciones que no se pueden deshacer, como cerrar sesión.
  static const Color rojo = Color(0xFFEF4444);

  /// Fondo de las tarjetas.
  static const Color blanco = Colors.white;
}
