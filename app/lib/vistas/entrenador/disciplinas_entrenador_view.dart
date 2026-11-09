import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/disciplinas_entrenador_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import 'componentes_entrenador.dart';

/// «Mis disciplinas» del entrenador (RF-ENT-01): sus deportes asignados y
/// la entrada a la nómina, la asistencia y el historial de cada uno.
class DisciplinasEntrenadorView extends StatelessWidget {
  const DisciplinasEntrenadorView({super.key});

  static const String _titulo = 'Mis disciplinas';

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

    return ChangeNotifierProvider<DisciplinasEntrenadorViewModel>(
      // Si cambia el entrenador, se empieza de nuevo con sus datos.
      key: ValueKey(perfil.id),
      create: (context) => DisciplinasEntrenadorViewModel(
        deporteRepository: context.read<DeporteRepository>(),
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
    final viewModel = context.watch<DisciplinasEntrenadorViewModel>();

    return MarcoEntrenador(
      titulo: DisciplinasEntrenadorView._titulo,
      child: switch (viewModel.estado) {
        DisciplinasEntrenadorEstado.cargando => const CargandoEntrenador(),
        DisciplinasEntrenadorEstado.error => MensajeEntrenador(
          titulo: 'No se pudieron cargar tus disciplinas.',
          detalle: 'Revisa tu conexión e intenta de nuevo.',
          icono: Icons.cloud_off_outlined,
          alReintentar: viewModel.cargar,
        ),
        DisciplinasEntrenadorEstado.listo =>
          viewModel.deportes.isEmpty
              ? const MensajeEntrenador(
                  titulo: 'Aún no tienes disciplinas asignadas.',
                  detalle:
                      'Cuando el administrador te asigne una disciplina, '
                      'aparecerá aquí.',
                  icono: Icons.sports_outlined,
                )
              : _Lista(viewModel: viewModel),
      },
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.viewModel});

  final DisciplinasEntrenadorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final deportes = viewModel.deportes;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Tus disciplinas',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          deportes.length == 1
              ? 'Tienes 1 disciplina asignada.'
              : 'Tienes ${deportes.length} disciplinas asignadas.',
          style: const TextStyle(
            color: ColoresSaman.textoSecundario,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        for (final deporte in deportes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TarjetaDisciplina(
              deporte: deporte,
              sesiones: viewModel.sesionesDe(deporte.id),
            ),
          ),
      ],
    );
  }
}

class _TarjetaDisciplina extends StatelessWidget {
  const _TarjetaDisciplina({required this.deporte, required this.sesiones});

  final Deporte deporte;
  final List<Sesion> sesiones;

  /// Las tres pantallas de la disciplina reciben el deporte como argumento.
  void _abrir(BuildContext context, String ruta) {
    Navigator.pushNamed(context, ruta, arguments: deporte);
  }

  @override
  Widget build(BuildContext context) {
    final horario = Horarios.resumen(sesiones);
    final detalle = [...horario, if (deporte.lugar.isNotEmpty) deporte.lugar];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deporte.nombre,
                  style: const TextStyle(
                    color: ColoresSaman.azulOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (deporte.codigo.isNotEmpty) ...[
                const SizedBox(width: 10),
                EtiquetaEntrenador(
                  deporte.codigo,
                  color: ColoresSaman.naranja,
                  fondo: ColoresSaman.naranjaSuave,
                ),
              ],
              // Un deporte oculto no sale en el catálogo del estudiante.
              if (!deporte.visible) ...[
                const SizedBox(width: 6),
                const EtiquetaEntrenador(
                  'Oculta',
                  color: ColoresSaman.textoSecundario,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detalle.isEmpty ? 'Horario por confirmar' : detalle.join(' · '),
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          _Cupos(deporte: deporte),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresSaman.naranja,
                  foregroundColor: ColoresSaman.blanco,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _abrir(context, Rutas.nominaEntrenador),
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: const Text(
                  'Nómina',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              _BotonSecundario(
                texto: 'Tomar asistencia',
                icono: Icons.fact_check_outlined,
                alPresionar: () => _abrir(context, Rutas.asistenciaEntrenador),
              ),
              _BotonSecundario(
                texto: 'Historial',
                icono: Icons.history,
                alPresionar: () => _abrir(context, Rutas.historialEntrenador),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cupos disponibles sobre el total, con una barra de ocupación.
class _Cupos extends StatelessWidget {
  const _Cupos({required this.deporte});

  final Deporte deporte;

  @override
  Widget build(BuildContext context) {
    final total = deporte.cupoMaximo;
    final double ocupacion = total <= 0
        ? 0.0
        : (deporte.inscritos / total).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cupos disponibles: ${deporte.cuposDisponibles}/$total',
          style: TextStyle(
            color: deporte.hayCupo
                ? ColoresSaman.textoCampo
                : ColoresSaman.rojo,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ocupacion,
            minHeight: 6,
            backgroundColor: ColoresSaman.gris,
            color: ColoresSaman.naranja,
          ),
        ),
      ],
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  const _BotonSecundario({
    required this.texto,
    required this.icono,
    required this.alPresionar,
  });

  final String texto;
  final IconData icono;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresSaman.naranja,
        side: BorderSide(color: ColoresSaman.naranja.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const StadiumBorder(),
      ),
      onPressed: alPresionar,
      icon: Icon(icono, size: 18),
      label: Text(
        texto,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
