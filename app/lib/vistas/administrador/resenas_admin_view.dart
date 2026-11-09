import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../comun/resenas_componentes.dart';

/// Reseñas de una disciplina para el administrador: promedio, filtro por
/// estrellas y eliminación con confirmación de las inapropiadas.
class ResenasAdminView extends StatefulWidget {
  const ResenasAdminView({super.key, required this.deporte});

  final Deporte deporte;

  @override
  State<ResenasAdminView> createState() => _ResenasAdminViewState();
}

class _ResenasAdminViewState extends State<ResenasAdminView> {
  late final Stream<List<Resena>> _resenas;

  /// Estrellas que se muestran; vacío = todas.
  final Set<int> _filtro = {};

  @override
  void initState() {
    super.initState();
    _resenas = context.read<ResenaRepository>().observarPorDeporte(
      widget.deporte.id,
    );
  }

  Future<void> _eliminar(Resena resena) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reseña'),
        content: Text(
          '¿Eliminar la reseña de ${resena.nombreEstudiante}? '
          'Desaparecerá para todos y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.rojo,
              foregroundColor: ColoresSaman.blanco,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await context.read<ResenaRepository>().eliminar(resena);
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Reseña eliminada.'),
          backgroundColor: ColoresSaman.verde,
        ),
      );
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la reseña. Inténtalo de nuevo.'),
          backgroundColor: ColoresSaman.rojo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: Text(
          'Reseñas: ${widget.deporte.nombre}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: StreamBuilder<List<Resena>>(
            stream: _resenas,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'No se pudieron cargar las reseñas. Revisa tu conexión.',
                    style: TextStyle(color: ColoresSaman.textoSecundario),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: ColoresSaman.naranja),
                );
              }
              final todas = snapshot.data!;
              if (todas.isEmpty) {
                return const Center(
                  child: Text(
                    'Esta disciplina todavía no tiene reseñas.',
                    style: TextStyle(color: ColoresSaman.textoSecundario),
                  ),
                );
              }
              final visibles = _filtro.isEmpty
                  ? todas
                  : todas
                        .where((r) => _filtro.contains(r.calificacion))
                        .toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ColoresSaman.blanco,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColoresSaman.borde),
                    ),
                    child: ResumenResenas(resenas: todas),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var e = 5; e >= 1; e--)
                        FilterChip(
                          label: Text('$e ★'),
                          selected: _filtro.contains(e),
                          onSelected: (si) => setState(
                            () => si ? _filtro.add(e) : _filtro.remove(e),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (visibles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay reseñas con esas estrellas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ColoresSaman.textoSecundario),
                      ),
                    ),
                  for (final r in visibles)
                    TarjetaResena(resena: r, alEliminar: () => _eliminar(r)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
