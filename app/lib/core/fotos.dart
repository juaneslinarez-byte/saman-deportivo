import 'package:flutter/material.dart';

/// Foto e ícono de cada disciplina según su nombre, para el catálogo y el
/// detalle. Las fotos están en assets/imagenes/.
abstract final class FotosDisciplinas {
  /// Se revisan en orden: «tenis de mesa» va antes que «tenis» y «fútbol
  /// sala» usa la foto de fútbol.
  static const _fotos = [
    ('tenis de mesa', 'assets/imagenes/tenis_de_mesa.jpg'),
    ('ping pong', 'assets/imagenes/tenis_de_mesa.jpg'),
    ('fútbol', 'assets/imagenes/futbol.jpg'),
    ('futbol', 'assets/imagenes/futbol.jpg'),
    ('baloncesto', 'assets/imagenes/baloncesto.jpg'),
    ('tenis', 'assets/imagenes/tenis.jpg'),
    ('voleibol', 'assets/imagenes/voleibol.jpg'),
    ('natación', 'assets/imagenes/natacion.jpg'),
    ('natacion', 'assets/imagenes/natacion.jpg'),
    ('karate', 'assets/imagenes/karate.jpg'),
    ('atletismo', 'assets/imagenes/portada_pista.jpg'),
  ];

  static const _iconos = [
    ('tenis de mesa', Icons.sports_tennis),
    ('fútbol', Icons.sports_soccer),
    ('futbol', Icons.sports_soccer),
    ('baloncesto', Icons.sports_basketball),
    ('tenis', Icons.sports_tennis),
    ('voleibol', Icons.sports_volleyball),
    ('natación', Icons.pool),
    ('natacion', Icons.pool),
    ('karate', Icons.sports_martial_arts),
    ('judo', Icons.sports_martial_arts),
    ('taekwondo', Icons.sports_martial_arts),
    ('atletismo', Icons.directions_run),
    ('ajedrez', Icons.extension),
    ('béisbol', Icons.sports_baseball),
    ('softbol', Icons.sports_baseball),
  ];

  /// Ruta de la foto, o null si la disciplina no tiene una.
  static String? de(String nombre) {
    final texto = nombre.toLowerCase();
    for (final (clave, ruta) in _fotos) {
      if (texto.contains(clave)) return ruta;
    }
    return null;
  }

  /// Ícono para cuando no hay foto.
  static IconData iconoDe(String nombre) {
    final texto = nombre.toLowerCase();
    for (final (clave, icono) in _iconos) {
      if (texto.contains(clave)) return icono;
    }
    return Icons.sports;
  }
}
