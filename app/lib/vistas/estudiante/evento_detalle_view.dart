import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/eventos.dart';
import '../../core/mensajes.dart';
import '../../core/pasarela.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/eventos_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import 'eventos_view.dart';

/// Detalle de un evento y su reserva: el estudiante elige cuántas personas
/// van, ve el resumen y paga. La reserva queda en revisión hasta que el
/// administrador valida el pago. El evento se observa en tiempo real, así
/// que los cupos que ve siempre son los actuales.
class EventoDetalleView extends StatefulWidget {
  const EventoDetalleView({super.key, required this.idEvento});

  final String idEvento;

  @override
  State<EventoDetalleView> createState() => _EventoDetalleViewState();
}

class _EventoDetalleViewState extends State<EventoDetalleView> {
  int _personas = 1;
  bool _pagando = false;

  Future<void> _reservar(Evento evento, Estudiante perfil) async {
    final vm = context.read<EventosViewModel>();
    final total = evento.monto * _personas;
    final gratis = evento.esGratis;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          gratis ? '¿Confirmar la reserva?' : '¿Estás seguro de pagar?',
        ),
        content: Text(
          gratis
              ? 'Reservarás ${FormatoEvento.personas(_personas)} en '
                    '«${evento.titulo}». Es gratis.\n\nLa reserva quedará en '
                    'revisión hasta que el administrador la confirme.'
              : 'Se cobrarán ${FormatoEvento.precio(total)} por '
                    '${FormatoEvento.personas(_personas)} en «${evento.titulo}», '
                    'a nombre de ${perfil.nombreCompleto}.\n\nLa reserva '
                    'quedará en revisión hasta que el administrador confirme '
                    'el pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.naranja,
              foregroundColor: ColoresSaman.blanco,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              gratis
                  ? 'Sí, reservar'
                  : 'Sí, pagar ${FormatoEvento.precio(total)}',
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _pagando = true);
    String referencia = '';
    try {
      if (!gratis) referencia = await PasarelaSimulada.cobrar(total);
    } catch (e) {
      if (mounted) {
        setState(() => _pagando = false);
        _aviso(mensajeDeError(e, porDefecto: 'No se pudo procesar el pago.'));
      }
      return;
    }
    final reserva = await vm.reservar(
      evento: evento,
      perfil: perfil,
      personas: _personas,
      referencia: referencia,
    );
    if (!mounted) return;
    setState(() => _pagando = false);
    if (reserva == null) {
      _aviso(vm.error ?? 'No se pudo registrar la reserva.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: ColoresSaman.verde,
          size: 48,
        ),
        title: const Text('Reserva en revisión'),
        content: Text(
          '${reserva.tituloEvento}\n'
          '${FormatoEvento.personas(reserva.personas)} · '
          '${FormatoEvento.precio(reserva.monto)}'
          '${reserva.referencia.isEmpty ? '' : '\nReferencia: ${reserva.referencia}'}'
          '\n\nTe avisaremos en «Mis reservas» cuando el administrador la '
          'confirme.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: ColoresSaman.rojo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventosViewModel>();
    final perfil = context.watch<PerfilViewModel>().perfil;
    final evento = vm.evento(widget.idEvento);

    if (evento == null) {
      return const MarcoEventos(
        titulo: 'Evento',
        child: MensajeEventos(
          icono: Icons.event_busy_outlined,
          texto: 'Este evento ya no está disponible: terminó o fue cancelado.',
        ),
      );
    }

    final reserva = vm.reservaEn(evento);
    final motivo = vm.motivoParaNoReservar(evento, perfil);
    final maximo = vm.maxPersonas(evento);
    if (_personas > maximo && maximo >= 1) _personas = maximo;
    final total = evento.monto * _personas;
    final ocupado = _pagando || vm.reservando;

    return MarcoEventos(
      titulo: 'Evento',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            evento.titulo,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
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
              DatoEvento(
                Icons.sell_outlined,
                evento.esGratis
                    ? 'Gratis'
                    : '${FormatoEvento.precio(evento.monto)} por persona',
              ),
              DatoEvento(
                Icons.groups_outlined,
                '${evento.cuposDisponibles} de ${evento.cupo} cupos '
                'disponibles',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            evento.descripcion,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: ColoresSaman.textoCampo,
            ),
          ),
          const SizedBox(height: 24),
          if (reserva != null)
            _ConReserva(reserva: reserva)
          else if (motivo != null)
            _Aviso(texto: motivo)
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ColoresSaman.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColoresSaman.gris),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu reserva',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColoresSaman.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Personas',
                          style: TextStyle(color: ColoresSaman.textoCampo),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar una persona',
                        onPressed: ocupado || _personas <= 1
                            ? null
                            : () => setState(() => _personas--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_personas',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Agregar una persona',
                        onPressed: ocupado || _personas >= maximo
                            ? null
                            : () => setState(() => _personas++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Text(
                    'Máximo ${FormatoEvento.personas(maximo)} por reserva.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColoresSaman.textoSecundario,
                    ),
                  ),
                  const Divider(height: 28),
                  _Fila('Reserva a nombre de', perfil?.nombreCompleto ?? ''),
                  _Fila('Fecha', FormatoEvento.fechaHora(evento.inicio)),
                  _Fila(
                    'Duración',
                    FormatoEvento.duracion(evento.duracionMinutos),
                  ),
                  _Fila('Total', FormatoEvento.precio(total), destacado: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresSaman.naranja,
                        foregroundColor: ColoresSaman.blanco,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: ocupado || perfil is! Estudiante
                          ? null
                          : () => _reservar(evento, perfil),
                      icon: ocupado
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: ColoresSaman.blanco,
                              ),
                            )
                          : Icon(
                              evento.esGratis
                                  ? Icons.check_circle_outline
                                  : Icons.payment,
                            ),
                      label: Text(
                        ocupado
                            ? 'Procesando…'
                            : evento.esGratis
                            ? 'Confirmar reserva'
                            : 'Pagar con PayPal',
                      ),
                    ),
                  ),
                  if (!evento.esGratis) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Modo de prueba: no se hace ningún cobro real.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColoresSaman.textoSecundario,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor, {this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(color: ColoresSaman.textoSecundario),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
                fontSize: destacado ? 18 : 14,
                color: ColoresSaman.azulOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConReserva extends StatelessWidget {
  const _ConReserva({required this.reserva});

  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    final aprobada = reserva.estado == EstadoReserva.aprobada;
    final color = aprobada ? ColoresSaman.verde : ColoresSaman.naranja;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            aprobada ? Icons.verified_outlined : Icons.hourglass_top_outlined,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              aprobada
                  ? 'Tu reserva para ${FormatoEvento.personas(reserva.personas)} '
                        'está aprobada. ¡Te esperamos!'
                  : 'Tu reserva para ${FormatoEvento.personas(reserva.personas)} '
                        'está en revisión. Puedes seguirla o cancelarla en '
                        '«Mis reservas».',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresSaman.gris,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: ColoresSaman.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: ColoresSaman.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }
}
