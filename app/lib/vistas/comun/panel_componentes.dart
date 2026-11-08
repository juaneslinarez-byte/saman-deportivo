/// Piezas visuales de los paneles resumen (administrador, entrenador y
/// estudiante): indicadores, secciones, barras y avisos, con el mismo
/// estilo en los tres.
library;

import 'package:flutter/material.dart';

import '../../core/colores.dart';

String porcentajePanel(double valor) => '${(valor * 100).round()} %';

String horaPanel(DateTime fecha) =>
    '${fecha.hour.toString().padLeft(2, '0')}:'
    '${fecha.minute.toString().padLeft(2, '0')}';

/// Indicadores en rejilla: cinco por fila en pantalla ancha, tres en
/// tableta y dos en teléfono.
class RejillaIndicadores extends StatelessWidget {
  const RejillaIndicadores({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        const espacio = 12.0;
        final maximo = restricciones.maxWidth >= 900
            ? 5
            : restricciones.maxWidth >= 560
            ? 3
            : restricciones.maxWidth >= 330
            ? 2
            : 1;
        // Con pocos indicadores, cada uno ocupa más ancho.
        final columnas = children.length < maximo ? children.length : maximo;
        final ancho =
            (restricciones.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final hijo in children) SizedBox(width: ancho, child: hijo),
          ],
        );
      },
    );
  }
}

class TarjetaIndicador extends StatelessWidget {
  const TarjetaIndicador({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    this.ruta,
    this.resaltado = false,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;
  final String? ruta;
  final bool resaltado;

  @override
  Widget build(BuildContext context) {
    final ruta = this.ruta;
    return Material(
      color: ColoresSaman.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: ruta == null ? null : () => Navigator.pushNamed(context, ruta),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: resaltado ? ColoresSaman.naranja : ColoresSaman.gris,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 20, color: ColoresSaman.naranja),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColoresSaman.textoSecundario,
                      ),
                    ),
                  ),
                  if (ruta != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: ColoresSaman.textoTenue,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detalle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeccionPanel extends StatelessWidget {
  const SeccionPanel({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class FilaAvisoPanel extends StatelessWidget {
  const FilaAvisoPanel({
    super.key,
    required this.texto,
    this.ruta,
    this.argumentos,
  });

  final String texto;

  /// Pantalla donde se resuelve el aviso; sin ella la fila no se toca.
  final String? ruta;

  /// Lo que recibe esa pantalla, por ejemplo la disciplina.
  final Object? argumentos;

  @override
  Widget build(BuildContext context) {
    final ruta = this.ruta;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: ruta == null
          ? null
          : () => Navigator.pushNamed(context, ruta, arguments: argumentos),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: ColoresSaman.naranja,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 13,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
            ),
            if (ruta != null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: ColoresSaman.textoTenue,
              ),
          ],
        ),
      ),
    );
  }
}

/// Fila con una etiqueta, un detalle y una barra horizontal de 0 a 100 %.
class BarraPanel extends StatelessWidget {
  const BarraPanel({
    super.key,
    required this.etiqueta,
    required this.detalle,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String detalle;
  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                detalle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: valor.clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: ColoresSaman.gris,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class LeyendaPanel extends StatelessWidget {
  const LeyendaPanel({super.key, required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, color: ColoresSaman.azulOscuro),
        ),
      ],
    );
  }
}

class TextoSinDatos extends StatelessWidget {
  const TextoSinDatos(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 13, color: ColoresSaman.textoSecundario),
    );
  }
}
