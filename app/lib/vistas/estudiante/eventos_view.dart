import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/eventos.dart';
import '../../core/formatos.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../comun/campos_formulario.dart';
import '../comun/disenio.dart';
import 'evento_detalle_view.dart';
import 'mis_reservas_view.dart';

/// «Eventos» del estudiante: próximos eventos del club con búsqueda y
/// filtros. Desde aquí reserva y entra a «Mis reservas».
class EventosView extends StatelessWidget {
  const EventosView({super.key});

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final perfil = perfilViewModel.perfil;
    if (perfil is! Estudiante) {
      final cargando =
          perfilViewModel.estado == PerfilEstado.cargando ||
          perfilViewModel.estado == PerfilEstado.inicial;
      return MarcoEventos(
        titulo: 'Eventos',
        child: cargando
            ? const Center(
                child: CircularProgressIndicator(color: ColoresSaman.naranja),
              )
            : const MensajeEventos(
                icono: Icons.person_off_outlined,
                texto: 'No se encontró tu perfil de estudiante.',
              ),
      );
    }
    return ChangeNotifierProvider<EventosViewModel>(
      key: ValueKey(perfil.id),
      create: (context) => EventosViewModel(
        eventoRepository: context.read<EventoRepository>(),
        reservaRepository: context.read<ReservaRepository>(),
        idEstudiante: perfil.id,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  void _abrir(BuildContext context, Widget pantalla) {
    final vm = context.read<EventosViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider.value(value: vm, child: pantalla),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventosViewModel>();
    final vigentes = vm.reservasVigentes;
    return MarcoEventos(
      titulo: 'Eventos',
      acciones: [
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: ColoresSaman.blanco),
          onPressed: () => _abrir(context, const MisReservasView()),
          icon: const Icon(Icons.confirmation_number_outlined),
          label: Text(
            vigentes > 0 ? 'Mis reservas ($vigentes)' : 'Mis reservas',
          ),
        ),
      ],
      child: switch (vm.estado) {
        EventosEstado.cargando => const Center(
          child: CircularProgressIndicator(color: ColoresSaman.naranja),
        ),
        EventosEstado.error => MensajeEventos(
          icono: Icons.cloud_off_outlined,
          texto: 'No se pudieron cargar los eventos. Revisa tu conexión.',
          alReintentar: vm.cargar,
        ),
        EventosEstado.listo => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CampoTexto(
              etiqueta: 'Buscar evento',
              pista: 'Por título o lugar',
              formateadores: Entradas.busqueda,
              alCambiar: vm.buscar,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Con cupo'),
                  selected: vm.soloConCupo,
                  onSelected: (_) => vm.alternarConCupo(),
                ),
                FilterChip(
                  label: const Text('Gratis'),
                  selected: vm.soloGratis,
                  onSelected: (_) => vm.alternarGratis(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vm.eventos.isEmpty)
              MensajeEventos(
                icono: Icons.event_busy_outlined,
                texto: vm.hayEventos
                    ? 'Ningún evento coincide con la búsqueda o los filtros.'
                    : 'No hay eventos próximos por ahora. Vuelve pronto: '
                          'aquí aparecerán los torneos y actividades del club.',
              )
            else
              for (var i = 0; i < vm.eventos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Aparecer(
                    retraso: Aparecer.escalonado(i, pasoMs: 40),
                    child: TarjetaEventoEstudiante(
                      evento: vm.eventos[i],
                      reserva: vm.reservaEn(vm.eventos[i]),
                      alTocar: () => _abrir(
                        context,
                        EventoDetalleView(idEvento: vm.eventos[i].id),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      },
    );
  }
}

/// Tarjeta de un evento en la lista del estudiante.
class TarjetaEventoEstudiante extends StatelessWidget {
  const TarjetaEventoEstudiante({
    super.key,
    required this.evento,
    required this.alTocar,
    this.reserva,
  });

  final Evento evento;
  final Reserva? reserva;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final cupos = evento.cuposDisponibles;
    return TarjetaInteractiva(
      relleno: const EdgeInsets.all(18),
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  evento.titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Insignia(
                texto: FormatoEvento.precio(evento.monto),
                color: evento.esGratis
                    ? ColoresSaman.verde
                    : ColoresSaman.naranja,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              DatoEvento(
                Icons.event_outlined,
                FormatoEvento.fechaHora(evento.inicio),
              ),
              DatoEvento(
                Icons.schedule_outlined,
                FormatoEvento.duracion(evento.duracionMinutos),
              ),
              DatoEvento(Icons.place_outlined, evento.lugar),
            ],
          ),
          const SizedBox(height: 10),
          if (reserva != null)
            Insignia(
              texto: reserva!.estado == EstadoReserva.aprobada
                  ? 'Reserva aprobada'
                  : 'Reserva en revisión',
              color: reserva!.estado == EstadoReserva.aprobada
                  ? ColoresSaman.verde
                  : ColoresSaman.naranja,
              icono: Icons.confirmation_number_outlined,
            )
          else
            Insignia(
              texto: cupos == 0
                  ? 'Sin cupos'
                  : cupos == 1
                  ? 'Queda 1 cupo'
                  : '$cupos cupos disponibles',
              color: cupos == 0 ? ColoresSaman.rojo : ColoresSaman.verde,
            ),
        ],
      ),
    );
  }
}

/// Ícono y texto pequeños con un dato del evento.
class DatoEvento extends StatelessWidget {
  const DatoEvento(this.icono, this.texto, {super.key});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: ColoresSaman.textoSecundario),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: ColoresSaman.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }
}

/// Marco común de las pantallas de eventos del estudiante.
class MarcoEventos extends StatelessWidget {
  const MarcoEventos({
    super.key,
    required this.titulo,
    required this.child,
    this.acciones,
  });

  final String titulo;
  final Widget child;
  final List<Widget>? acciones;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: acciones,
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

/// Mensaje centrado con ícono y, si se pasa, «Reintentar».
class MensajeEventos extends StatelessWidget {
  const MensajeEventos({
    super.key,
    required this.icono,
    required this.texto,
    this.alReintentar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 48, color: ColoresSaman.textoTenue),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresSaman.textoSecundario),
          ),
          if (alReintentar != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
