import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/panel_entrenador_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../comun/panel_componentes.dart';
import 'componentes_entrenador.dart';

/// Panel resumen del entrenador: sus cifras en tiempo real, la próxima
/// clase y los estudiantes que requieren atención.
class PanelEntrenadorView extends StatelessWidget {
  const PanelEntrenadorView({super.key});

  static const String _titulo = 'Mi resumen';

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
                titulo: 'No se encontró tu perfil de entrenador.',
                detalle: 'Vuelve a iniciar sesión.',
                icono: Icons.person_off_outlined,
              ),
      );
    }

    return ChangeNotifierProvider<PanelEntrenadorViewModel>(
      key: ValueKey(perfil.id),
      create: (context) => PanelEntrenadorViewModel(
        deporteRepository: context.read<DeporteRepository>(),
        inscripcionRepository: context.read<InscripcionRepository>(),
        asistenciaRepository: context.read<AsistenciaRepository>(),
        usuarioRepository: context.read<UsuarioRepository>(),
        idEntrenador: perfil.id,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelEntrenadorViewModel>();

    return MarcoEntrenador(
      titulo: PanelEntrenadorView._titulo,
      child: switch (vm.estado) {
        PanelEntrenadorEstado.cargando => const CargandoEntrenador(),
        PanelEntrenadorEstado.error => MensajeEntrenador(
          titulo: 'No se pudo cargar tu resumen.',
          detalle: 'Revisa tu conexión e intenta de nuevo.',
          icono: Icons.cloud_off_outlined,
          alReintentar: vm.cargar,
        ),
        PanelEntrenadorEstado.listo =>
          vm.totalDisciplinas == 0
              ? const MensajeEntrenador(
                  titulo: 'Todavía no tienes disciplinas asignadas.',
                  detalle:
                      'Cuando el administrador te asigne una, verás aquí '
                      'tus inscritos y su asistencia.',
                  icono: Icons.sports_outlined,
                )
              : _Contenido(vm: vm),
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.vm});

  final PanelEntrenadorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final asistencia = vm.asistenciaGlobal;
    final proxima = vm.proximaClase;
    final avisos = vm.avisos;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (proxima != null) ...[
          _ProximaClase(
            disciplina: proxima.deporte.nombre,
            cuando: vm.cuando(proxima.inicio),
            lugar: proxima.sesion.lugar,
            hasta: Horarios.hora12(proxima.sesion.horaFin),
            alTomar: () => Navigator.pushNamed(
              context,
              Rutas.asistenciaEntrenador,
              arguments: proxima.deporte,
            ),
          ),
          const SizedBox(height: 16),
        ],
        RejillaIndicadores(
          children: [
            TarjetaIndicador(
              icono: Icons.sports_outlined,
              titulo: 'Disciplinas',
              valor: '${vm.totalDisciplinas}',
              detalle: 'Asignadas a ti',
              ruta: Rutas.disciplinasEntrenador,
            ),
            TarjetaIndicador(
              icono: Icons.groups_outlined,
              titulo: 'Inscritos',
              valor: '${vm.totalInscritos}',
              detalle: vm.totalNoSolventes == 0
                  ? 'Todos solventes'
                  : '${vm.totalNoSolventes} sin solvencia',
              resaltado: vm.totalNoSolventes > 0,
            ),
            TarjetaIndicador(
              icono: Icons.fact_check_outlined,
              titulo: 'Asistencia',
              valor: asistencia == null ? '—' : porcentajePanel(asistencia),
              detalle: vm.clasesTomadas == 0
                  ? 'Aún no has tomado asistencia'
                  : 'En ${vm.clasesTomadas} '
                        '${vm.clasesTomadas == 1 ? 'clase' : 'clases'}',
            ),
          ],
        ),
        const SizedBox(height: 20),
        SeccionPanel(
          titulo: 'Requiere atención',
          child: avisos.isEmpty
              ? const Text(
                  'Todo en orden: asistencia al día y sin estudiantes con '
                  'muchas faltas.',
                  style: TextStyle(color: ColoresSaman.verde),
                )
              : Column(
                  children: [
                    for (final aviso in avisos)
                      FilaAvisoPanel(
                        texto: aviso.texto,
                        ruta: aviso.ruta,
                        argumentos: aviso.deporte,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SeccionPanel(
          titulo: 'Mis disciplinas',
          child: Column(
            children: [
              for (final r in vm.disciplinas) _FilaDisciplina(resumen: r),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProximaClase extends StatelessWidget {
  const _ProximaClase({
    required this.disciplina,
    required this.cuando,
    required this.lugar,
    required this.hasta,
    required this.alTomar,
  });

  final String disciplina;
  final String cuando;
  final String lugar;
  final String hasta;
  final VoidCallback alTomar;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  'Próxima clase',
                  style: TextStyle(color: ColoresSaman.blanco, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  disciplina,
                  style: const TextStyle(
                    color: ColoresSaman.blanco,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$cuando a $hasta${lugar.isEmpty ? '' : ' · $lugar'}',
                  style: const TextStyle(
                    color: ColoresSaman.blanco,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ColoresSaman.naranja),
            onPressed: alTomar,
            child: const Text('Tomar asistencia'),
          ),
        ],
      ),
    );
  }
}

class _FilaDisciplina extends StatelessWidget {
  const _FilaDisciplina({required this.resumen});

  final ResumenClase resumen;

  @override
  Widget build(BuildContext context) {
    final d = resumen.deporte;
    final asistencia = resumen.asistencia;
    final ultima = resumen.ultimaClase;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () =>
          Navigator.pushNamed(context, Rutas.nominaEntrenador, arguments: d),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarraPanel(
              etiqueta: d.nombre,
              detalle: '${resumen.inscritos} / ${d.cupoMaximo} inscritos',
              valor: d.cupoMaximo == 0 ? 0 : resumen.inscritos / d.cupoMaximo,
              color: ColoresSaman.azulOscuro,
            ),
            Text(
              [
                asistencia == null
                    ? 'Sin asistencia tomada'
                    : 'Asistencia ${porcentajePanel(asistencia)}',
                if (ultima != null) 'última clase ${Formatos.fecha(ultima)}',
                if (resumen.noSolventes > 0)
                  '${resumen.noSolventes} sin solvencia',
              ].join(' · '),
              style: TextStyle(
                fontSize: 12,
                color: asistencia != null && asistencia < 0.6
                    ? ColoresSaman.rojo
                    : ColoresSaman.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
