import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/eventos.dart';
import '../../core/solvencia.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/reserva_repository.dart';
import '../../viewmodels/reservas_evento_viewmodel.dart';
import '../comun/disenio.dart';

/// Reservas de un evento: el administrador valida cada pago y aprueba o
/// rechaza la reserva. Arriba ve las personas confirmadas y el monto
/// aprobado.
class ReservasEventoView extends StatelessWidget {
  const ReservasEventoView({
    super.key,
    required this.evento,
    required this.reservaRepository,
  });

  final Evento evento;
  final ReservaRepository reservaRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReservasEventoViewModel>(
      create: (_) => ReservasEventoViewModel(
        reservaRepository: reservaRepository,
        evento: evento,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservasEventoViewModel>();
    final evento = vm.evento;
    const filtros = <(EstadoReserva?, String)>[
      (EstadoReserva.enRevision, 'En revisión'),
      (EstadoReserva.aprobada, 'Aprobadas'),
      (EstadoReserva.rechazada, 'Rechazadas'),
      (EstadoReserva.cancelada, 'Canceladas'),
      (null, 'Todas'),
    ];

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Reservas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: switch (vm.estado) {
            ReservasEventoEstado.cargando => const Center(
              child: CircularProgressIndicator(color: ColoresSaman.naranja),
            ),
            ReservasEventoEstado.error => _Vacio(
              texto: 'No se pudieron cargar las reservas. Revisa tu conexión.',
              alReintentar: vm.cargar,
            ),
            ReservasEventoEstado.listo => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  evento.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${FormatoEvento.fechaHora(evento.inicio)} · ${evento.lugar}',
                  style: const TextStyle(color: ColoresSaman.textoSecundario),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Total(
                      'Personas confirmadas',
                      '${vm.personasConfirmadas} de ${evento.cupo}',
                    ),
                    _Total(
                      'Monto aprobado',
                      Solvencia.formatoMonto(vm.montoAprobado),
                    ),
                    _Total(
                      'En revisión',
                      '${vm.cuantas(EstadoReserva.enRevision)}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (estado, texto) in filtros)
                      ChoiceChip(
                        label: Text('$texto (${vm.cuantas(estado)})'),
                        selected: vm.filtro == estado,
                        onSelected: (_) => vm.filtrar(estado),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (vm.reservas.isEmpty)
                  _Vacio(
                    texto: vm.filtro == EstadoReserva.enRevision
                        ? 'No hay reservas por revisar en este evento.'
                        : 'No hay reservas con este filtro.',
                  )
                else
                  for (final reserva in vm.reservas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TarjetaReserva(reserva: reserva, vm: vm),
                    ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              color: ColoresSaman.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.reserva, required this.vm});

  final Reserva reserva;
  final ReservasEventoViewModel vm;

  Future<void> _revisar(BuildContext context, {required bool aprobar}) async {
    final pago = reserva.monto > 0
        ? 'el pago ${reserva.referencia} (${FormatoEvento.precio(reserva.monto)})'
        : 'la reserva gratuita';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprobar ? 'Aprobar reserva' : 'Rechazar reserva'),
        content: Text(
          aprobar
              ? '¿Aprobar $pago de ${reserva.nombreEstudiante} para '
                    '${FormatoEvento.personas(reserva.personas)}?'
              : '¿Rechazar $pago de ${reserva.nombreEstudiante}? Se '
                    'liberarán ${FormatoEvento.personas(reserva.personas)} '
                    'del cupo y podrá reservar de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: aprobar ? ColoresSaman.verde : ColoresSaman.rojo,
              foregroundColor: ColoresSaman.blanco,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(aprobar ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    final error = aprobar
        ? await vm.aprobar(reserva)
        : await vm.rechazar(reserva);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (aprobar ? 'Reserva aprobada.' : 'Reserva rechazada.'),
        ),
        backgroundColor: error == null ? ColoresSaman.verde : ColoresSaman.rojo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (reserva.estado) {
      EstadoReserva.enRevision => ('En revisión', ColoresSaman.naranja),
      EstadoReserva.aprobada => ('Aprobada', ColoresSaman.verde),
      EstadoReserva.rechazada => ('Rechazada', ColoresSaman.rojo),
      EstadoReserva.cancelada => ('Cancelada', ColoresSaman.textoSecundario),
    };
    final enRevision = reserva.estado == EstadoReserva.enRevision;
    return TarjetaInteractiva(
      relleno: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarIniciales(nombre: reserva.nombreEstudiante, tamano: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.nombreEstudiante,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColoresSaman.azulOscuro,
                      ),
                    ),
                    Text(
                      'Carnet ${reserva.carnetEstudiante}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColoresSaman.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Insignia(texto: texto, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${FormatoEvento.personas(reserva.personas)} · '
            '${FormatoEvento.precio(reserva.monto)}'
            '${reserva.referencia.isEmpty ? '' : ' · ${reserva.referencia}'}',
            style: const TextStyle(color: ColoresSaman.textoCampo),
          ),
          Text(
            'Reservó el ${Solvencia.formatoFechaHora(reserva.fecha)}',
            style: const TextStyle(
              fontSize: 12,
              color: ColoresSaman.textoSecundario,
            ),
          ),
          if (enRevision) ...[
            const SizedBox(height: 10),
            if (vm.enProceso(reserva))
              const Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresSaman.rojo,
                      side: const BorderSide(color: ColoresSaman.rojo),
                    ),
                    onPressed: () => _revisar(context, aprobar: false),
                    child: const Text('Rechazar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresSaman.verde,
                      foregroundColor: ColoresSaman.blanco,
                    ),
                    onPressed: () => _revisar(context, aprobar: true),
                    child: const Text('Aprobar'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto, this.alReintentar});

  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 44,
            color: ColoresSaman.textoTenue,
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresSaman.textoSecundario),
          ),
          if (alReintentar != null)
            TextButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
