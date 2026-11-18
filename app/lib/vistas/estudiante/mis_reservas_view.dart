import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/eventos.dart';
import '../../core/solvencia.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import '../comun/disenio.dart';
import 'eventos_view.dart';

/// «Mis reservas»: el estado de cada reserva del estudiante y la opción de
/// cancelarla antes de que empiece el evento.
class MisReservasView extends StatelessWidget {
  const MisReservasView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventosViewModel>();
    final reservas = vm.reservas;
    return MarcoEventos(
      titulo: 'Mis reservas',
      child: reservas.isEmpty
          ? const MensajeEventos(
              icono: Icons.confirmation_number_outlined,
              texto:
                  'Todavía no has reservado ningún evento. Elige uno en '
                  '«Eventos».',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final reserva in reservas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TarjetaReserva(reserva: reserva, vm: vm),
                  ),
              ],
            ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.reserva, required this.vm});

  final Reserva reserva;
  final EventosViewModel vm;

  Future<void> _cancelar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
          '¿Cancelar tu reserva en «${reserva.tituloEvento}»? Los cupos '
          'quedarán libres para otros estudiantes.'
          '${reserva.monto > 0 ? '\n\nEl reembolso de ${FormatoEvento.precio(reserva.monto)} lo gestiona la coordinación de deportes.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.rojo,
              foregroundColor: ColoresSaman.blanco,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    final error = await vm.cancelar(reserva);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Reserva cancelada.'),
        backgroundColor: error == null ? ColoresSaman.verde : ColoresSaman.rojo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (texto, color) = textoEstadoReserva(reserva.estado);
    final puedeCancelar =
        reserva.vigente && reserva.inicioEvento.isAfter(vm.ahora);
    return Opacity(
      opacity: reserva.vigente ? 1 : 0.65,
      child: TarjetaInteractiva(
        relleno: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reserva.tituloEvento,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColoresSaman.azulOscuro,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Insignia(texto: texto, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                DatoEvento(
                  Icons.event_outlined,
                  FormatoEvento.fechaHora(reserva.inicioEvento),
                ),
                DatoEvento(
                  Icons.groups_outlined,
                  FormatoEvento.personas(reserva.personas),
                ),
                DatoEvento(
                  Icons.sell_outlined,
                  FormatoEvento.precio(reserva.monto),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Reservada el ${Solvencia.formatoFechaHora(reserva.fecha)}'
              '${reserva.referencia.isEmpty ? '' : ' · ${reserva.referencia}'}',
              style: const TextStyle(
                fontSize: 12,
                color: ColoresSaman.textoSecundario,
              ),
            ),
            if (puedeCancelar) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: vm.cancelando(reserva)
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: ColoresSaman.rojo,
                        ),
                        onPressed: () => _cancelar(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar reserva'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Texto y color de cada estado de una reserva.
(String, Color) textoEstadoReserva(EstadoReserva estado) => switch (estado) {
  EstadoReserva.enRevision => ('En revisión', ColoresSaman.naranja),
  EstadoReserva.aprobada => ('Aprobada', ColoresSaman.verde),
  EstadoReserva.rechazada => ('Rechazada', ColoresSaman.rojo),
  EstadoReserva.cancelada => ('Cancelada', ColoresSaman.textoSecundario),
};
