import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/solvencia.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/solicitudes_admin_viewmodel.dart';

/// Solicitudes de los entrenadores (CU-16, RF-ADM-07): el administrador
/// aprueba o rechaza cada una. Al aprobarla, el entrenador queda asignado a
/// la disciplina.
class SolicitudesAdminView extends StatelessWidget {
  const SolicitudesAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SolicitudesAdminViewModel>(
      create: (context) => SolicitudesAdminViewModel(
        solicitudRepository: context.read<SolicitudRepository>(),
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolicitudesAdminViewModel>();

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Solicitudes de entrenadores',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: switch (vm.estado) {
            SolicitudesAdminEstado.cargando => const Center(
              child: CircularProgressIndicator(),
            ),
            SolicitudesAdminEstado.error => _Vacio(
              icono: Icons.cloud_off_outlined,
              texto:
                  'No se pudieron cargar las solicitudes. Revisa tu conexión.',
              alReintentar: vm.cargar,
            ),
            SolicitudesAdminEstado.listo =>
              vm.pendientes.isEmpty
                  ? const _Vacio(
                      icono: Icons.task_alt,
                      texto:
                          'No hay solicitudes por revisar. Cuando un '
                          'entrenador pida dirigir otra disciplina aparecerá '
                          'aquí.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          '${vm.pendientes.length} '
                          '${vm.pendientes.length == 1 ? 'solicitud' : 'solicitudes'}'
                          ' por revisar',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColoresSaman.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final s in vm.pendientes)
                          _TarjetaSolicitud(solicitud: s, vm: vm),
                      ],
                    ),
          },
        ),
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({required this.solicitud, required this.vm});

  final Solicitud solicitud;
  final SolicitudesAdminViewModel vm;

  Future<void> _revisar(BuildContext context, {required bool aprobar}) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprobar ? 'Aprobar solicitud' : 'Rechazar solicitud'),
        content: Text(
          aprobar
              ? '¿Asignar a ${solicitud.nombreEntrenador} a '
                    '${solicitud.nombreDeporte}? Podrá ver la nómina y tomar '
                    'la asistencia.'
              : '¿Rechazar la solicitud de ${solicitud.nombreEntrenador} '
                    'para ${solicitud.nombreDeporte}?',
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
    final error = aprobar
        ? await vm.aprobar(solicitud)
        : await vm.rechazar(solicitud);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (aprobar
                  ? '${solicitud.nombreEntrenador} ya dirige '
                        '${solicitud.nombreDeporte}.'
                  : 'Solicitud rechazada.'),
        ),
        backgroundColor: error == null
            ? (aprobar ? ColoresSaman.verde : ColoresSaman.azulOscuro)
            : ColoresSaman.rojo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = vm.enProceso(solicitud);
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
          Text(
            solicitud.nombreEntrenador,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quiere dirigir ${solicitud.nombreDeporte} · '
            '${Solvencia.formatoFechaHora(solicitud.fecha)}',
            style: const TextStyle(
              fontSize: 12,
              color: ColoresSaman.textoSecundario,
            ),
          ),
          if (solicitud.mensaje.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '«${solicitud.mensaje}»',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: ColoresSaman.textoCampo,
              ),
            ),
          ],
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
                icon: const Icon(Icons.check),
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
