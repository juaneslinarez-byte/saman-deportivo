import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/solvencia.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/pagos_admin_viewmodel.dart';

/// Pagos de solvencia en revisión (CU-16, RF-ADM-05): el administrador
/// aprueba o rechaza cada uno. Al aprobarlo, el estudiante queda solvente.
class PagosAdminView extends StatelessWidget {
  const PagosAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PagosAdminViewModel>(
      create: (context) => PagosAdminViewModel(
        pagoRepository: context.read<PagoRepository>(),
        usuarioRepository: context.read<UsuarioRepository>(),
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagosAdminViewModel>();

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Pagos de solvencia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: switch (vm.estado) {
            PagosAdminEstado.cargando => const Center(
              child: CircularProgressIndicator(),
            ),
            PagosAdminEstado.error => _Vacio(
              icono: Icons.cloud_off_outlined,
              texto: 'No se pudieron cargar los pagos. Revisa tu conexión.',
              alReintentar: vm.cargar,
            ),
            PagosAdminEstado.listo => _Lista(vm: vm),
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.vm});

  final PagosAdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    final pendientes = vm.pendientes;
    if (pendientes.isEmpty) {
      return const _Vacio(
        icono: Icons.task_alt,
        texto:
            'No hay pagos por revisar. Cuando un estudiante pague su '
            'solvencia aparecerá aquí.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${pendientes.length} '
          '${pendientes.length == 1 ? 'pago' : 'pagos'} en revisión · '
          '${Solvencia.formatoMonto(vm.totalPendiente)} en total',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ColoresSaman.azulOscuro,
          ),
        ),
        const SizedBox(height: 12),
        for (final pago in pendientes) _TarjetaPago(pago: pago, vm: vm),
      ],
    );
  }
}

class _TarjetaPago extends StatelessWidget {
  const _TarjetaPago({required this.pago, required this.vm});

  final Pago pago;
  final PagosAdminViewModel vm;

  Future<void> _revisar(BuildContext context, {required bool aprobar}) async {
    final estudiante = vm.estudianteDe(pago);
    final nombre = estudiante?.nombreCompleto ?? 'el estudiante';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprobar ? 'Aprobar pago' : 'Rechazar pago'),
        content: Text(
          aprobar
              ? '¿Aprobar el pago ${pago.referencia} de $nombre? Quedará '
                    'solvente y podrá inscribirse en las disciplinas.'
              : '¿Rechazar el pago ${pago.referencia} de $nombre? Seguirá '
                    'sin solvencia y podrá pagar de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
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
    if (confirmado != true) return;
    final error = aprobar ? await vm.aprobar(pago) : await vm.rechazar(pago);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (aprobar
                  ? 'Pago aprobado. $nombre ya está solvente.'
                  : 'Pago rechazado.'),
        ),
        backgroundColor: error == null
            ? (aprobar ? ColoresSaman.verde : ColoresSaman.azulOscuro)
            : ColoresSaman.rojo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estudiante = vm.estudianteDe(pago);
    final ocupado = vm.enProceso(pago);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  estudiante?.nombreCompleto ?? 'Estudiante no encontrado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
              Text(
                Solvencia.formatoMonto(pago.monto),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (estudiante != null)
            Text(
              'Carnet ${estudiante.carnet} · ${estudiante.carrera}',
              style: const TextStyle(
                fontSize: 12,
                color: ColoresSaman.textoSecundario,
              ),
            ),
          Text(
            'Referencia ${pago.referencia} · '
            '${Solvencia.formatoFechaHora(pago.fecha)}',
            style: const TextStyle(
              fontSize: 12,
              color: ColoresSaman.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: ColoresSaman.rojo),
                onPressed: ocupado
                    ? null
                    : () => _revisar(context, aprobar: false),
                child: const Text('Rechazar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresSaman.verde,
                  foregroundColor: ColoresSaman.blanco,
                ),
                onPressed: ocupado
                    ? null
                    : () => _revisar(context, aprobar: true),
                icon: ocupado
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColoresSaman.blanco,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Aprobar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto, this.alReintentar});

  final IconData icono;
  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
      ),
    );
  }
}
