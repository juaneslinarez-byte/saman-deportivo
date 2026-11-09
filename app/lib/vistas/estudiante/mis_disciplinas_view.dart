import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/mis_inscripciones_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import 'formulario_resena_view.dart';

/// «Mis disciplinas» (CU-04): las inscripciones activas del estudiante, su
/// historial de canceladas y la cancelación con confirmación.
class MisDisciplinasView extends StatelessWidget {
  const MisDisciplinasView({super.key});

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final perfil = perfilViewModel.perfil;

    if (perfil is! Estudiante) {
      final cargando =
          perfilViewModel.estado == PerfilEstado.cargando ||
          perfilViewModel.estado == PerfilEstado.inicial;
      return _Marco(
        child: cargando
            ? const _Cargando()
            : const _Mensaje('No se encontró tu perfil de estudiante.'),
      );
    }

    return ChangeNotifierProvider<MisInscripcionesViewModel>(
      // Si cambia el estudiante, se empieza de nuevo con sus datos.
      key: ValueKey(perfil.id),
      create: (context) => MisInscripcionesViewModel(
        inscripcionRepository: context.read<InscripcionRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
        idEstudiante: perfil.id,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MisInscripcionesViewModel>();

    return _Marco(
      child: switch (viewModel.estado) {
        MisInscripcionesEstado.cargando => const _Cargando(),
        MisInscripcionesEstado.error => _Mensaje(
          'No se pudieron cargar tus disciplinas. Intenta de nuevo.',
          alReintentar: viewModel.cargar,
        ),
        MisInscripcionesEstado.listo => _Contenido(viewModel: viewModel),
      },
    );
  }
}

/// Fondo y barra superior; el contenido va centrado y con ancho máximo.
class _Marco extends StatelessWidget {
  const _Marco({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Mis disciplinas',
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

class _Contenido extends StatelessWidget {
  const _Contenido({required this.viewModel});

  final MisInscripcionesViewModel viewModel;

  /// Pide confirmación antes de cancelar: la cancelación no se deshace
  /// (se puede volver a inscribir, pero hay que tener cupo).
  Future<void> _cancelar(
    BuildContext context,
    InscripcionConDeporte item,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColoresSaman.blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar inscripción',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Liberarás tu cupo en ${item.nombre}. ¿Quieres continuar?',
          style: const TextStyle(
            color: ColoresSaman.textoSecundario,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'No, volver',
              style: TextStyle(color: ColoresSaman.textoSecundario),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(
                color: ColoresSaman.rojo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final exito = await viewModel.cancelar(item.inscripcion);
    if (!context.mounted) return;

    final texto = exito ? viewModel.mensaje : viewModel.error;
    if (texto != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activas = viewModel.activas;
    final historial = viewModel.historial;

    if (activas.isEmpty && historial.isEmpty) return const _Vacio();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _Encabezado(),
        const SizedBox(height: 20),

        if (activas.isEmpty)
          const Text(
            'No tienes inscripciones activas.',
            style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 14),
          )
        else
          for (final item in activas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TarjetaActiva(
                item: item,
                cancelando: viewModel.estaCancelando(item.inscripcion),
                bloqueada: viewModel.procesando,
                alCancelar: () => _cancelar(context, item),
              ),
            ),

        if (historial.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Historial',
            style: TextStyle(
              color: ColoresSaman.azulOscuro,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in historial)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TarjetaCancelada(item: item),
            ),
        ],
      ],
    );
  }
}

/// Título de la pantalla y botón para ir a buscar más disciplinas.
class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis inscripciones',
              style: TextStyle(
                color: ColoresSaman.azulOscuro,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tus inscripciones activas y tu historial.',
              style: TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 13,
              ),
            ),
          ],
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresSaman.naranja,
            foregroundColor: ColoresSaman.blanco,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          onPressed: () => _irAlCatalogo(context),
          child: const Text(
            '+ Explorar más disciplinas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

void _irAlCatalogo(BuildContext context) {
  Navigator.pushNamed(context, Rutas.catalogo);
}

BoxDecoration _decoracionTarjeta(Color color) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _TarjetaActiva extends StatelessWidget {
  const _TarjetaActiva({
    required this.item,
    required this.cancelando,
    required this.bloqueada,
    required this.alCancelar,
  });

  final InscripcionConDeporte item;

  /// Esta tarjeta es la que se está cancelando (muestra el indicador).
  final bool cancelando;

  /// Hay una cancelación en curso: no se puede iniciar otra.
  final bool bloqueada;
  final VoidCallback alCancelar;

  @override
  Widget build(BuildContext context) {
    final horario = Horarios.resumen(item.sesiones);
    final detalle = [...horario, if (item.lugar.isNotEmpty) item.lugar];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _decoracionTarjeta(ColoresSaman.blanco),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nombre,
                  style: const TextStyle(
                    color: ColoresSaman.azulOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.star_rate_rounded),
                label: const Text('Dejar / Editar reseña'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FormularioResenaView(
                        idEstudiante: item.inscripcion.id,
                        idDeporte: item.inscripcion.id,
                        nombreDeporte: item.nombre,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _Etiqueta(
                'Inscrito',
                fondo: ColoresSaman.verde.withValues(alpha: 0.12),
                color: ColoresSaman.verde,
              ),
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresSaman.naranja,
                  side: BorderSide(
                    color: ColoresSaman.naranja.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(),
                ),
                // Abre el historial filtrado por esta disciplina (RF-EST-06).
                onPressed: () => Navigator.pushNamed(
                  context,
                  Rutas.miAsistencia,
                  arguments: item.inscripcion.idDeporte,
                ),
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text(
                  'Ver mi asistencia',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresSaman.rojo,
                  side: BorderSide(
                    color: ColoresSaman.rojo.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: bloqueada ? null : alCancelar,
                child: cancelando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColoresSaman.rojo,
                        ),
                      )
                    : const Text(
                        'Cancelar inscripción',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inscripción cancelada, en gris, dentro del historial.
class _TarjetaCancelada extends StatelessWidget {
  const _TarjetaCancelada({required this.item});

  final InscripcionConDeporte item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.gris,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nombre,
                  style: const TextStyle(
                    color: ColoresSaman.textoSecundario,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Etiqueta(
                'Cancelada',
                fondo: ColoresSaman.textoSecundario.withValues(alpha: 0.15),
                color: ColoresSaman.textoSecundario,
              ),
            ],
          ),
          if (item.lugar.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.lugar,
              style: const TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _VolverAInscribirme(deporte: item.deporte),
        ],
      ),
    );
  }
}

/// Lleva a confirmar la inscripción otra vez; el repositorio reactiva la
/// misma inscripción. Solo se habilita si la disciplina sigue en el catálogo
/// y tiene cupo; si no, el botón dice por qué.
class _VolverAInscribirme extends StatelessWidget {
  const _VolverAInscribirme({required this.deporte});

  final Deporte? deporte;

  @override
  Widget build(BuildContext context) {
    final deporte = this.deporte;
    final String? motivo = deporte == null || !deporte.visible
        ? 'Disciplina no disponible'
        : !deporte.hayCupo
        ? 'Sin cupos'
        : null;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresSaman.naranja,
        disabledForegroundColor: ColoresSaman.textoDiscreto,
        side: BorderSide(
          color: motivo == null
              ? ColoresSaman.naranja.withValues(alpha: 0.5)
              : ColoresSaman.textoDiscreto.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const StadiumBorder(),
      ),
      onPressed: motivo != null
          ? null
          : () => Navigator.pushNamed(
              context,
              Rutas.confirmarInscripcion,
              arguments: deporte,
            ),
      icon: Icon(motivo == null ? Icons.replay : Icons.block, size: 16),
      label: Text(
        motivo ?? 'Volver a inscribirme',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {required this.fondo, required this.color});

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Todavía no hay ninguna inscripción, ni activa ni cancelada.
class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_soccer_outlined,
              size: 48,
              color: ColoresSaman.textoSecundario,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aún no te has inscrito en ninguna disciplina.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresSaman.naranja,
                foregroundColor: ColoresSaman.blanco,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: () => _irAlCatalogo(context),
              child: const Text(
                'Explorar disciplinas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: ColoresSaman.naranja),
    );
  }
}

/// Mensaje centrado y, si se pasa [alReintentar], el botón «Reintentar».
class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto, {this.alReintentar});

  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 14,
              ),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: alReintentar,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: ColoresSaman.naranja),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
