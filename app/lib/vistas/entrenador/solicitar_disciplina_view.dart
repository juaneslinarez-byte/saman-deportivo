import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../../viewmodels/solicitudes_entrenador_viewmodel.dart';
import '../comun/disenio.dart';
import 'componentes_entrenador.dart';

/// «Solicitar disciplina» (CU-15, RF-ENT-06): el entrenador pide dirigir una
/// disciplina que todavía no tiene asignada y ve el estado de sus pedidos.
class SolicitarDisciplinaView extends StatelessWidget {
  const SolicitarDisciplinaView({super.key});

  static const String _titulo = 'Solicitar disciplina';

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final perfil = perfilViewModel.perfil;

    if (perfil is! Entrenador) {
      final cargando =
          perfilViewModel.estado == PerfilEstado.cargando ||
          perfilViewModel.estado == PerfilEstado.inicial;
      return MarcoEntrenador(
        titulo: _titulo,
        child: cargando
            ? const CargandoEntrenador()
            : const MensajeEntrenador(
                titulo: 'Esta sección es solo para entrenadores.',
                icono: Icons.lock_outline,
              ),
      );
    }

    return ChangeNotifierProvider<SolicitudesEntrenadorViewModel>(
      key: ValueKey(perfil.id),
      create: (context) => SolicitudesEntrenadorViewModel(
        deporteRepository: context.read<DeporteRepository>(),
        solicitudRepository: context.read<SolicitudRepository>(),
        entrenador: perfil,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolicitudesEntrenadorViewModel>();

    return MarcoEntrenador(
      titulo: SolicitarDisciplinaView._titulo,
      child: switch (vm.estado) {
        SolicitudesEntrenadorEstado.cargando => const CargandoEntrenador(),
        SolicitudesEntrenadorEstado.error => MensajeEntrenador(
          titulo: 'No se pudieron cargar las disciplinas.',
          detalle: 'Revisa tu conexión e intenta de nuevo.',
          icono: Icons.cloud_off_outlined,
          alReintentar: vm.cargar,
        ),
        SolicitudesEntrenadorEstado.listo => _Lista(vm: vm),
      },
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.vm});

  final SolicitudesEntrenadorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final opciones = vm.opciones;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pide dirigir otra disciplina. El administrador revisa tu '
          'solicitud y, si la aprueba, la disciplina aparece en «Mis '
          'disciplinas».',
          style: TextStyle(fontSize: 13, color: ColoresSaman.textoSecundario),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre o código',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (texto) => vm.busqueda = texto,
        ),
        const SizedBox(height: 16),
        if (opciones.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: MensajeEntrenador(
              titulo: 'No hay otras disciplinas para solicitar.',
              icono: Icons.sports_outlined,
            ),
          )
        else
          for (final opcion in opciones) _TarjetaOpcion(opcion: opcion, vm: vm),
      ],
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  const _TarjetaOpcion({required this.opcion, required this.vm});

  final OpcionSolicitud opcion;
  final SolicitudesEntrenadorViewModel vm;

  Future<void> _solicitar(BuildContext context) async {
    final deporte = opcion.deporte;
    final mensaje = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Solicitar ${deporte.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El administrador recibirá tu solicitud para dirigir esta '
              'disciplina.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mensaje,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Por ejemplo, tu experiencia en este deporte',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final error = await vm.solicitar(deporte, mensaje: mensaje.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Solicitud enviada. Te avisaremos aquí.'),
        backgroundColor: error == null ? ColoresSaman.verde : ColoresSaman.rojo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deporte = opcion.deporte;
    final estado = opcion.solicitud?.estado;
    final ocupado = vm.enviando(deporte);
    final (String? etiqueta, Color color) = switch (estado) {
      EstadoSolicitud.pendiente => ('Pendiente', ColoresSaman.ambar),
      // Aprobada pero ya no la dirige: se puede pedir otra vez.
      EstadoSolicitud.aprobada => (null, ColoresSaman.naranja),
      EstadoSolicitud.rechazada => ('Rechazada', ColoresSaman.rojo),
      null => (null, ColoresSaman.naranja),
    };
    final puedePedir = estado != EstadoSolicitud.pendiente;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: decoracionTarjeta(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deporte.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (deporte.codigo.isNotEmpty) deporte.codigo,
                    if (deporte.lugar.isNotEmpty) deporte.lugar,
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColoresSaman.textoSecundario,
                  ),
                ),
                if (etiqueta != null) ...[
                  const SizedBox(height: 8),
                  Insignia(texto: etiqueta, color: color),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (puedePedir)
            ElevatedButton(
              onPressed: ocupado ? null : () => _solicitar(context),
              child: ocupado
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      estado == EstadoSolicitud.rechazada
                          ? 'Solicitar de nuevo'
                          : 'Solicitar',
                    ),
            ),
        ],
      ),
    );
  }
}
