import 'package:flutter/material.dart';

import '../../core/colores.dart';
import '../../modelos/modelos.dart';

/// Utilidades para mostrar reseñas: promedio, estrellas, distribución y
/// tarjeta de cada reseña. Las usan el detalle de la disciplina y la
/// moderación del administrador.
abstract final class Resenas {
  static double? promedio(List<Resena> lista) {
    if (lista.isEmpty) return null;
    final suma = lista.fold<int>(0, (s, r) => s + r.calificacion);
    return suma / lista.length;
  }

  /// «4,3»: una cifra decimal con coma.
  static String formatoPromedio(double valor) =>
      valor.toStringAsFixed(1).replaceAll('.', ',');

  static String fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year}';

  static String cantidad(int n) => n == 1 ? '1 reseña' : '$n reseñas';
}

class Estrellas extends StatelessWidget {
  const Estrellas(this.valor, {super.key, this.tamano = 16});

  /// De 0 a 5; admite medias estrellas para el promedio.
  final double valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            valor >= i
                ? Icons.star_rounded
                : (valor >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: tamano,
            color: ColoresSaman.ambar,
          ),
      ],
    );
  }
}

/// Promedio grande, estrellas y barras de la distribución de 5 a 1.
class ResumenResenas extends StatelessWidget {
  const ResumenResenas({super.key, required this.resenas});

  final List<Resena> resenas;

  @override
  Widget build(BuildContext context) {
    final promedio = Resenas.promedio(resenas) ?? 0;
    final total = resenas.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              Resenas.formatoPromedio(promedio),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: ColoresSaman.azulOscuro,
              ),
            ),
            Estrellas(promedio, tamano: 18),
            const SizedBox(height: 4),
            Text(
              Resenas.cantidad(total),
              style: const TextStyle(
                fontSize: 12,
                color: ColoresSaman.textoSecundario,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (var e = 5; e >= 1; e--)
                _BarraEstrellas(
                  estrellas: e,
                  cuantas: resenas.where((r) => r.calificacion == e).length,
                  total: total,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarraEstrellas extends StatelessWidget {
  const _BarraEstrellas({
    required this.estrellas,
    required this.cuantas,
    required this.total,
  });

  final int estrellas;
  final int cuantas;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$estrellas',
              style: const TextStyle(
                fontSize: 12,
                color: ColoresSaman.textoSecundario,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 12, color: ColoresSaman.ambar),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : cuantas / total,
                minHeight: 7,
                backgroundColor: ColoresSaman.gris,
                color: ColoresSaman.ambar,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            child: Text(
              '$cuantas',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                color: ColoresSaman.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una reseña: nombre, estrellas, fecha («editada» si aplica) y comentario.
/// Con [alEliminar] muestra el botón para moderarla.
class TarjetaResena extends StatelessWidget {
  const TarjetaResena({super.key, required this.resena, this.alEliminar});

  final Resena resena;
  final VoidCallback? alEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresSaman.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  resena.nombreEstudiante.isEmpty
                      ? 'Estudiante'
                      : resena.nombreEstudiante,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
              if (alEliminar != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: ColoresSaman.rojo,
                  ),
                  onPressed: alEliminar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Estrellas(resena.calificacion.toDouble(), tamano: 15),
              Text(
                '${Resenas.fecha(resena.fecha)}'
                '${resena.editada ? ' · editada' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resena.comentario,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: ColoresSaman.azulOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
