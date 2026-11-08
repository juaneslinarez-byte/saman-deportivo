import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../core/solvencia.dart';
import '../comun/panel_componentes.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/panel_admin_viewmodel.dart';

/// Panel resumen del administrador (CU-17): las cifras del club en tiempo
/// real y lo que conviene atender.
class PanelAdminView extends StatelessWidget {
  const PanelAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PanelAdminViewModel>(
      create: (context) => PanelAdminViewModel(
        deporteRepository: context.read<DeporteRepository>(),
        usuarioRepository: context.read<UsuarioRepository>(),
        pagoRepository: context.read<PagoRepository>(),
        asistenciaRepository: context.read<AsistenciaRepository>(),
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelAdminViewModel>();

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Panel resumen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
        actions: [
          if (vm.estado == PanelAdminEstado.listo)
            IconButton(
              tooltip: 'Actualizar usuarios',
              icon: const Icon(Icons.refresh),
              onPressed: vm.actualizar,
            ),
        ],
      ),
      body: switch (vm.estado) {
        PanelAdminEstado.cargando => const Center(
          child: CircularProgressIndicator(color: ColoresSaman.naranja),
        ),
        PanelAdminEstado.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: ColoresSaman.textoTenue,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el panel. Revisa tu conexión.',
                style: TextStyle(color: ColoresSaman.textoSecundario),
              ),
              TextButton(onPressed: vm.cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
        PanelAdminEstado.listo => _Contenido(vm: vm),
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.vm});

  final PanelAdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    final asistencia = vm.asistenciaGlobal;
    final actualizado = vm.actualizado;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (actualizado != null)
              Text(
                'En tiempo real · última actualización ${horaPanel(actualizado)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            const SizedBox(height: 12),
            RejillaIndicadores(
              children: [
                TarjetaIndicador(
                  icono: Icons.school_outlined,
                  titulo: 'Estudiantes',
                  valor: '${vm.totalEstudiantes}',
                  detalle:
                      '${vm.estudiantesSolventes} solventes · '
                      '${vm.estudiantesNoSolventes} sin solvencia',
                  ruta: Rutas.adminUsuarios,
                ),
                TarjetaIndicador(
                  icono: Icons.sports_outlined,
                  titulo: 'Disciplinas',
                  valor: '${vm.totalDisciplinas}',
                  detalle:
                      '${vm.disciplinasPublicadas} publicadas · '
                      '${vm.totalEntrenadores} entrenadores',
                  ruta: Rutas.adminDeportes,
                ),
                TarjetaIndicador(
                  icono: Icons.how_to_reg_outlined,
                  titulo: 'Inscripciones activas',
                  valor: '${vm.inscripcionesActivas}',
                  detalle:
                      'Ocupación ${porcentajePanel(vm.ocupacionGlobal)} de '
                      '${vm.cupoTotal} cupos',
                ),
                TarjetaIndicador(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Asistencia',
                  valor: asistencia == null ? '—' : porcentajePanel(asistencia),
                  detalle: asistencia == null
                      ? 'Aún no se ha tomado asistencia'
                      : 'Promedio de ${vm.registrosAsistencia} registros',
                ),
                TarjetaIndicador(
                  icono: Icons.request_quote_outlined,
                  titulo: 'Pagos en revisión',
                  valor: '${vm.pagosEnRevision}',
                  detalle: vm.pagosEnRevision == 0
                      ? 'Nada pendiente'
                      : '${Solvencia.formatoMonto(vm.montoEnRevision)} '
                            'por aprobar',
                  ruta: Rutas.adminPagos,
                  resaltado: vm.pagosEnRevision > 0,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SeccionPanel(
              titulo: 'Requiere atención',
              child: vm.alertas.isEmpty
                  ? const Text(
                      'Todo en orden: no hay pagos por revisar ni '
                      'disciplinas incompletas.',
                      style: TextStyle(color: ColoresSaman.verde),
                    )
                  : Column(
                      children: [
                        for (final alerta in vm.alertas)
                          FilaAvisoPanel(
                            texto: alerta.texto,
                            ruta: alerta.ruta,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            SeccionPanel(
              titulo: 'Solvencia de los estudiantes',
              child: vm.totalEstudiantes == 0
                  ? const TextoSinDatos(
                      'Todavía no hay estudiantes registrados.',
                    )
                  : _BarraSolvencia(vm: vm),
            ),
            const SizedBox(height: 16),
            SeccionPanel(
              titulo: 'Ocupación por disciplina',
              child: vm.disciplinas.isEmpty
                  ? const TextoSinDatos('Todavía no hay disciplinas creadas.')
                  : Column(
                      children: [
                        for (final r in vm.disciplinas)
                          BarraPanel(
                            etiqueta: r.deporte.nombre,
                            detalle:
                                '${r.deporte.inscritos} / '
                                '${r.deporte.cupoMaximo}'
                                '${r.deporte.visible ? '' : ' · oculta'}',
                            valor: r.ocupacion,
                            color: r.ocupacion >= 0.9
                                ? ColoresSaman.naranja
                                : ColoresSaman.azulOscuro,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            SeccionPanel(
              titulo: 'Asistencia por disciplina',
              child: vm.disciplinasConAsistencia.isEmpty
                  ? const TextoSinDatos(
                      'Cuando los entrenadores tomen la asistencia, aquí verás '
                      'el porcentaje de cada disciplina.',
                    )
                  : Column(
                      children: [
                        for (final r in vm.disciplinasConAsistencia)
                          BarraPanel(
                            etiqueta: r.deporte.nombre,
                            detalle:
                                '${porcentajePanel(r.asistencia!)} · '
                                '${r.clases} '
                                '${r.clases == 1 ? 'clase' : 'clases'}',
                            valor: r.asistencia!,
                            color: r.asistencia! < 0.6
                                ? ColoresSaman.rojo
                                : ColoresSaman.verde,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraSolvencia extends StatelessWidget {
  const _BarraSolvencia({required this.vm});

  final PanelAdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    final total = vm.totalEstudiantes;
    final solventes = vm.estudiantesSolventes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : solventes / total,
            minHeight: 14,
            backgroundColor: ColoresSaman.rojo.withValues(alpha: 0.35),
            color: ColoresSaman.verde,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 6,
          children: [
            LeyendaPanel(
              color: ColoresSaman.verde,
              texto:
                  'Solventes: $solventes '
                  '(${porcentajePanel(solventes / total)})',
            ),
            LeyendaPanel(
              color: ColoresSaman.rojo.withValues(alpha: 0.35),
              texto: 'Sin solvencia: ${vm.estudiantesNoSolventes}',
            ),
          ],
        ),
      ],
    );
  }
}
