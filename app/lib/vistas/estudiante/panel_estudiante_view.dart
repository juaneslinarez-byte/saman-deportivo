import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/panel_estudiante_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../comun/panel_componentes.dart';

/// Panel resumen del estudiante: su próxima clase, su asistencia en cada
/// disciplina, su solvencia y lo que debería atender.
class PanelEstudianteView extends StatelessWidget {
  const PanelEstudianteView({super.key});

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final perfil = perfilViewModel.perfil;

    if (perfil is! Estudiante) {
      final cargando =
          perfilViewModel.estado == PerfilEstado.cargando ||
          perfilViewModel.estado == PerfilEstado.inicial;
      return _Marco(
        child: Center(
          child: cargando
              ? const CircularProgressIndicator(color: ColoresSaman.naranja)
              : const Text(
                  'No se encontró tu perfil de estudiante.',
                  style: TextStyle(color: ColoresSaman.textoSecundario),
                ),
        ),
      );
    }

    return ChangeNotifierProvider<PanelEstudianteViewModel>(
      key: ValueKey(perfil.id),
      create: (context) => PanelEstudianteViewModel(
        inscripcionRepository: context.read<InscripcionRepository>(),
        asistenciaRepository: context.read<AsistenciaRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
        idEstudiante: perfil.id,
      )..cargar(),
      child: _Pantalla(perfil: perfil),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla({required this.perfil});

  final Estudiante perfil;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelEstudianteViewModel>();

    return _Marco(
      child: switch (vm.estado) {
        PanelEstudianteEstado.cargando => const Center(
          child: CircularProgressIndicator(color: ColoresSaman.naranja),
        ),
        PanelEstudianteEstado.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No se pudo cargar tu resumen. Revisa tu conexión.',
                style: TextStyle(color: ColoresSaman.textoSecundario),
              ),
              TextButton(onPressed: vm.cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
        PanelEstudianteEstado.listo => _Contenido(vm: vm, perfil: perfil),
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.vm, required this.perfil});

  final PanelEstudianteViewModel vm;
  final Estudiante perfil;

  @override
  Widget build(BuildContext context) {
    final asistencia = vm.asistenciaGlobal;
    final proxima = vm.proximaClase;
    final disciplinas = vm.disciplinas;

    final avisos = <FilaAvisoPanel>[
      if (!perfil.solvente)
        const FilaAvisoPanel(
          texto:
              'No estás solvente: paga la cuota del trimestre para poder '
              'inscribirte.',
          ruta: Rutas.solvencia,
        ),
      if (disciplinas.isEmpty)
        const FilaAvisoPanel(
          texto: 'No estás inscrito en ninguna disciplina. Mira el catálogo.',
          ruta: Rutas.catalogo,
        ),
      for (final d in vm.conPocaAsistencia)
        FilaAvisoPanel(
          texto:
              'Has asistido al ${porcentajePanel(d.asistencia!)} de las clases '
              'de ${d.nombre} (${d.faltas} '
              '${d.faltas == 1 ? 'falta' : 'faltas'}).',
          ruta: Rutas.miAsistencia,
          argumentos: d.inscripcion.idDeporte,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (proxima != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ColoresSaman.azulOscuro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  color: ColoresSaman.naranja,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu próxima clase',
                        style: TextStyle(
                          color: ColoresSaman.blanco,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        proxima.disciplina,
                        style: const TextStyle(
                          color: ColoresSaman.blanco,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vm.cuando(proxima.inicio)} a '
                        '${Horarios.hora12(proxima.sesion.horaFin)}'
                        '${proxima.sesion.lugar.isEmpty ? '' : ' · ${proxima.sesion.lugar}'}',
                        style: const TextStyle(
                          color: ColoresSaman.blanco,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        RejillaIndicadores(
          children: [
            TarjetaIndicador(
              icono: Icons.event_available_outlined,
              titulo: 'Mis disciplinas',
              valor: '${vm.totalActivas}',
              detalle: vm.totalActivas == 0
                  ? 'Aún no te has inscrito'
                  : 'Inscripciones activas',
              ruta: Rutas.misDisciplinas,
            ),
            TarjetaIndicador(
              icono: Icons.fact_check_outlined,
              titulo: 'Mi asistencia',
              valor: asistencia == null ? '—' : porcentajePanel(asistencia),
              detalle: asistencia == null
                  ? 'Aún no hay clases registradas'
                  : '${vm.clasesRegistradas} clases · ${vm.faltas} '
                        '${vm.faltas == 1 ? 'falta' : 'faltas'}',
              ruta: Rutas.miAsistencia,
            ),
            TarjetaIndicador(
              icono: Icons.payments_outlined,
              titulo: 'Solvencia',
              valor: perfil.solvente ? 'Al día' : 'Pendiente',
              detalle: perfil.solvente
                  ? 'Puedes inscribirte'
                  : 'Paga para inscribirte',
              ruta: Rutas.solvencia,
              resaltado: !perfil.solvente,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SeccionPanel(
          titulo: 'Requiere atención',
          child: avisos.isEmpty
              ? const Text(
                  'Todo en orden: estás solvente y vas bien con tu asistencia.',
                  style: TextStyle(color: ColoresSaman.verde),
                )
              : Column(children: avisos),
        ),
        if (disciplinas.isNotEmpty) ...[
          const SizedBox(height: 16),
          SeccionPanel(
            titulo: 'Mi asistencia por disciplina',
            child: Column(
              children: [
                for (final d in disciplinas)
                  d.asistencia == null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.nombre,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: ColoresSaman.azulOscuro,
                                  ),
                                ),
                              ),
                              const Text(
                                'Sin clases registradas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColoresSaman.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        )
                      : BarraPanel(
                          etiqueta: d.nombre,
                          detalle:
                              '${porcentajePanel(d.asistencia!)} · '
                              '${d.presentes} de ${d.registros} '
                              '${d.registros == 1 ? 'clase' : 'clases'}',
                          valor: d.asistencia!,
                          color: d.asistencia! < 0.6
                              ? ColoresSaman.rojo
                              : ColoresSaman.verde,
                        ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Mi resumen',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
