/// Piezas visuales que comparten las pantallas del módulo del entrenador,
/// con el mismo estilo del resto de la app: fondo claro, tarjetas blancas
/// redondeadas y botones naranjas en forma de pastilla.
library;

import 'package:flutter/material.dart';

import '../../core/colores.dart';

/// Fondo y barra superior; el contenido va arriba, centrado y con un ancho
/// máximo para que se lea bien en el computador y en el teléfono.
class MarcoEntrenador extends StatelessWidget {
  const MarcoEntrenador({
    super.key,
    required this.titulo,
    required this.child,
    this.abajo,
  });

  final String titulo;
  final Widget child;

  /// Lo que va debajo del título, por ejemplo las pestañas del historial.
  final PreferredSizeWidget? abajo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: abajo,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: child,
        ),
      ),
    );
  }
}

/// Fondo blanco, bordes redondeados y una sombra suave.
BoxDecoration decoracionTarjeta() {
  return BoxDecoration(
    color: ColoresSaman.blanco,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class CargandoEntrenador extends StatelessWidget {
  const CargandoEntrenador({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: ColoresSaman.naranja),
    );
  }
}

/// Mensaje centrado para los estados vacío y de error. Si se pasa
/// [alReintentar], muestra el botón «Reintentar».
class MensajeEntrenador extends StatelessWidget {
  const MensajeEntrenador({
    super.key,
    required this.titulo,
    this.detalle,
    this.icono = Icons.info_outline,
    this.alReintentar,
  });

  final String titulo;
  final String? detalle;
  final IconData icono;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: ColoresSaman.textoSecundario),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColoresSaman.azulOscuro,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColoresSaman.textoSecundario,
                  fontSize: 14,
                ),
              ),
            ],
            if (alReintentar != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: alReintentar,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: ColoresSaman.naranja),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Etiqueta pequeña de color, por ejemplo «Solvente» o «Oculta».
class EtiquetaEntrenador extends StatelessWidget {
  const EtiquetaEntrenador(
    this.texto, {
    super.key,
    required this.color,
    this.fondo,
  });

  final String texto;
  final Color color;

  /// Si no se indica, se usa el mismo [color] muy suave.
  final Color? fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fondo ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
