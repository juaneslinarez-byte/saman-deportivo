import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/eventos.dart';
import '../../core/formatos.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/admin_eventos_viewmodel.dart';
import '../comun/campos_formulario.dart';
import '../comun/disenio.dart';
import 'evento_form_view.dart';
import 'reservas_evento_view.dart';

/// «Eventos» del administrador: publica, edita, cancela o elimina los
/// eventos del club que los estudiantes reservan.
class AdminEventosView extends StatelessWidget {
  const AdminEventosView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminEventosViewModel>(
      create: (context) => AdminEventosViewModel(
        eventoRepository: context.read<EventoRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
        reservaRepository: context.read<ReservaRepository>(),
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

/// Abre el formulario para crear (sin [evento]) o editar un evento.
void abrirFormularioEvento(BuildContext context, [Evento? evento]) {
  final vm = context.read<AdminEventosViewModel>();
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: EventoFormView(evento: evento),
      ),
    ),
  );
}

/// Abre las reservas del evento para aprobarlas o rechazarlas.
void abrirReservasEvento(BuildContext context, Evento evento) {
  final vm = context.read<AdminEventosViewModel>();
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ReservasEventoView(
        evento: evento,
        reservaRepository: vm.reservaRepository,
      ),
    ),
  );
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminEventosViewModel>();
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Eventos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ColoresSaman.naranja,
        foregroundColor: ColoresSaman.blanco,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
        onPressed: () => abrirFormularioEvento(context),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: switch (vm.estado) {
            AdminEventosEstado.cargando => const Center(
              child: CircularProgressIndicator(color: ColoresSaman.naranja),
            ),
            AdminEventosEstado.error => _Vacio(
              icono: Icons.cloud_off_outlined,
              texto: 'No se pudieron cargar los eventos. Revisa tu conexión.',
              alReintentar: vm.cargar,
            ),
            AdminEventosEstado.listo => _Lista(vm: vm),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.vm});

  final AdminEventosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final eventos = vm.eventos;
    const filtros = [
      (FiltroEventos.todos, 'Todos'),
      (FiltroEventos.proximos, 'Próximos'),
      (FiltroEventos.pasados, 'Pasados'),
      (FiltroEventos.cancelados, 'Cancelados'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
          runSpacing: 8,
          children: [
            for (final (filtro, texto) in filtros)
              ChoiceChip(
                label: Text(texto),
                selected: vm.filtro == filtro,
                onSelected: (_) => vm.filtrar(filtro),
              ),
          ],
        ),
        if (vm.totalEnRevision > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColoresSaman.naranjaSuave,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_outlined,
                  color: ColoresSaman.naranja,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vm.totalEnRevision == 1
                        ? '1 reserva espera la revisión del pago.'
                        : '${vm.totalEnRevision} reservas esperan la '
                              'revisión del pago.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ColoresSaman.azulOscuro,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (eventos.isEmpty)
          _Vacio(
            icono: Icons.event_busy_outlined,
            texto: vm.filtro == FiltroEventos.todos
                ? 'Todavía no hay eventos. Publica el primero con «Nuevo '
                      'evento».'
                : 'No hay eventos con este filtro.',
          )
        else
          for (var i = 0; i < eventos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Aparecer(
                retraso: Aparecer.escalonado(i, pasoMs: 40),
                child: _TarjetaEvento(evento: eventos[i], vm: vm),
              ),
            ),
      ],
    );
  }
}

class _TarjetaEvento extends StatelessWidget {
  const _TarjetaEvento({required this.evento, required this.vm});

  final Evento evento;
  final AdminEventosViewModel vm;

  Future<void> _cancelar(BuildContext context) async {
    final reservados = evento.reservados;
    final confirmado = await _confirmar(
      context,
      titulo: 'Cancelar evento',
      texto:
          '¿Cancelar «${evento.titulo}»? '
          '${reservados == 0 ? 'No tiene reservas.' : 'Se cancelarán las reservas de ${FormatoEvento.personas(reservados)}.'}'
          '\n\nUn evento cancelado ya no se puede editar ni reservar.',
      accion: 'Cancelar evento',
    );
    if (confirmado != true || !context.mounted) return;
    final error = await vm.cancelar(evento);
    if (!context.mounted) return;
    _avisar(context, error, 'Evento cancelado.');
  }

  Future<void> _eliminar(BuildContext context) async {
    final confirmado = await _confirmar(
      context,
      titulo: 'Eliminar evento',
      texto: '¿Eliminar «${evento.titulo}»? Esta acción no se puede deshacer.',
      accion: 'Eliminar',
    );
    if (confirmado != true || !context.mounted) return;
    final error = await vm.eliminar(evento);
    if (!context.mounted) return;
    _avisar(context, error, 'Evento eliminado.');
  }

  @override
  Widget build(BuildContext context) {
    final ahora = vm.ahora;
    final pasado = evento.yaPaso(ahora);
    final atenuado = evento.estaCancelado || pasado;
    final deporte = vm.nombreDeporte(evento.idDeporte);
    final (estado, color) = evento.estaCancelado
        ? ('Cancelado', ColoresSaman.rojo)
        : pasado
        ? ('Finalizado', ColoresSaman.textoSecundario)
        : evento.yaEmpezo(ahora)
        ? ('En curso', ColoresSaman.naranja)
        : ('Publicado', ColoresSaman.verde);

    return Opacity(
      opacity: atenuado ? 0.6 : 1,
      child: TarjetaInteractiva(
        relleno: const EdgeInsets.all(18),
        alTocar: () => abrirReservasEvento(context, evento),
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
                if (vm.enProceso(evento))
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Acciones',
                    icon: const Icon(
                      Icons.more_vert,
                      color: ColoresSaman.textoSecundario,
                    ),
                    onSelected: (accion) => switch (accion) {
                      'reservas' => abrirReservasEvento(context, evento),
                      'editar' => abrirFormularioEvento(context, evento),
                      'cancelar' => _cancelar(context),
                      'eliminar' => _eliminar(context),
                      _ => null,
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'reservas',
                        child: Text('Ver reservas'),
                      ),
                      if (!atenuado)
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
                      if (!evento.estaCancelado && !pasado)
                        const PopupMenuItem(
                          value: 'cancelar',
                          child: Text('Cancelar evento'),
                        ),
                      if (evento.reservados == 0)
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                    ],
                  ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Insignia(texto: estado, color: color),
                if (vm.enRevisionDe(evento) > 0)
                  Insignia(
                    texto: '${vm.enRevisionDe(evento)} por revisar',
                    color: ColoresSaman.naranja,
                    icono: Icons.pending_actions_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Dato(
                  Icons.event_outlined,
                  FormatoEvento.fechaHora(evento.inicio),
                ),
                _Dato(
                  Icons.schedule_outlined,
                  FormatoEvento.duracion(evento.duracionMinutos),
                ),
                _Dato(Icons.place_outlined, evento.lugar),
                _Dato(Icons.sell_outlined, FormatoEvento.precio(evento.monto)),
                _Dato(
                  Icons.groups_outlined,
                  '${evento.reservados} de ${evento.cupo} reservados',
                ),
                if (deporte != null) _Dato(Icons.sports_outlined, deporte),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: ColoresSaman.textoSecundario),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 13,
            color: ColoresSaman.textoSecundario,
          ),
        ),
      ],
    );
  }
}

Future<bool?> _confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String accion,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
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
          child: Text(accion),
        ),
      ],
    ),
  );
}

void _avisar(BuildContext context, String? error, String exito) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error ?? exito),
      backgroundColor: error == null ? ColoresSaman.verde : ColoresSaman.rojo,
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto, this.alReintentar});

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
