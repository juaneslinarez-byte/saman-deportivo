import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colores.dart';

/// Tema visual de la aplicación, según el estilo «light» del prototipo en
/// Figma: fondo claro, esquinas redondeadas, botones en forma de pastilla,
/// sombras suaves y la tipografía Plus Jakarta Sans.
abstract final class TemaSaman {
  static ThemeData get claro {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColoresSaman.naranja,
        primary: ColoresSaman.naranja,
        error: ColoresSaman.rojo,
        surface: ColoresSaman.blanco,
      ),
      scaffoldBackgroundColor: ColoresSaman.fondo,
      // Plus Jakarta Sans se descarga de Google Fonts la primera vez.
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ColoresSaman.azulOscuro,
        displayColor: ColoresSaman.azulOscuro,
      ),
      // Barra superior azul noche en toda la app, con el título en blanco.
      appBarTheme: AppBarTheme(
        backgroundColor: ColoresSaman.azulNoche,
        foregroundColor: ColoresSaman.blanco,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ColoresSaman.blanco,
        ),
      ),
      // Transición suave entre pantallas en todas las plataformas.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColoresSaman.blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresSaman.naranja,
          foregroundColor: ColoresSaman.blanco,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ColoresSaman.naranja),
      ),
      // Solo el color de las ayudas: cada formulario define el estilo de sus
      // campos, y así la pantalla de recuperar contraseña conserva el suyo.
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: ColoresSaman.textoTenue),
      ),
      cardTheme: CardThemeData(
        color: ColoresSaman.blanco,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
