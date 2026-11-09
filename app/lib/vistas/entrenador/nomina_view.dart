import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/nomina_viewmodel.dart';
import 'componentes_entrenador.dart';

/// Nómina de una disciplina (RF-ENT-02, RF-ENT-05): los inscritos activos
/// con su carnet y si están solventes. Recibe el [Deporte] como argumento
/// de la ruta.
class NominaView extends StatelessWidget {
  const NominaView({super.key});

  static const String _titulo = 'Nómina';

  @override
  Widget build(BuildContext context) {
    final argumento = ModalRoute.of(context)!.settings.arguments;

    // Si se entra escribiendo la dirección, no hay disciplina elegida.
    if (argumento is! Deporte) {
      return const MarcoEntrenador(
        titulo: _titulo,
        child: MensajeEntrenador(
          titulo: 'No se indicó la disciplina.',
          detalle: 'Vuelve a «Mis disciplinas» y elige una.',
          icono: Icons.sports_outlined,
        ),
      );
    }

    return ChangeNotifierProvider<NominaViewModel>(
      key: ValueKey(argumento.id),
      create: (context) => NominaViewModel(
        inscripcionRepository: context.read<InscripcionRepository>(),
        usuarioRepository: context.read<UsuarioRepository>(),
        idDeporte: argumento.id,
      )..cargar(),
      child: _Pantalla(deporte: argumento),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla({required this.deporte});

  final Deporte deporte;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NominaViewModel>();

    return MarcoEntrenador(
      titulo: NominaView._titulo,
      child: switch (viewModel.estado) {
        NominaEstado.cargando => const CargandoEntrenador(),
        NominaEstado.error => MensajeEntrenador(
          titulo: 'No se pudo cargar la nómina.',
          detalle: 'Revisa tu conexión e intenta de nuevo.',
          icono: Icons.cloud_off_outlined,
          alReintentar: viewModel.cargar,
        ),
        NominaEstado.listo => _Contenido(
          deporte: deporte,
          viewModel: viewModel,
        ),
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.deporte, required this.viewModel});

  final Deporte deporte;
  final NominaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final filas = viewModel.filas;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Resumen(deporte: deporte, viewModel: viewModel),
        const SizedBox(height: 20),
        if (filas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: MensajeEntrenador(
              titulo: 'Aún no hay inscritos',
              detalle:
                  'Cuando un estudiante se inscriba en esta disciplina, '
                  'aparecerá en la nómina.',
              icono: Icons.group_off_outlined,
            ),
          )
        else
          Container(
            decoration: decoracionTarjeta(),
            child: Column(
              children: [
                for (var i = 0; i < filas.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 18,
                      endIndent: 18,
                      color: ColoresSaman.gris,
                    ),
                  _FilaInscrito(fila: filas[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Nombre de la disciplina y el conteo de inscritos y de no solventes.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.deporte, required this.viewModel});

  final Deporte deporte;
  final NominaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final inscritos = viewModel.totalInscritos;
    final noSolventes = viewModel.totalNoSolventes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          deporte.nombre,
          style: const TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (deporte.codigo.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            deporte.codigo,
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Contador(
              valor: inscritos,
              texto: inscritos == 1 ? 'inscrito' : 'inscritos',
              color: ColoresSaman.naranja,
            ),
            _Contador(
              valor: noSolventes,
              texto: noSolventes == 1 ? 'no solvente' : 'no solventes',
              color: noSolventes == 0 ? ColoresSaman.verde : ColoresSaman.rojo,
            ),
          ],
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.texto,
    required this.color,
  });

  final int valor;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: decoracionTarjeta(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaInscrito extends StatelessWidget {
  const _FilaInscrito({required this.fila});

  final FilaNomina fila;

  @override
  Widget build(BuildContext context) {
    final inicial = fila.nombre.isEmpty ? '?' : fila.nombre[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ColoresSaman.naranjaSuave,
            child: Text(
              inicial,
              style: const TextStyle(
                color: ColoresSaman.naranja,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.nombre,
                  style: const TextStyle(
                    color: ColoresSaman.azulOscuro,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fila.carnet.isEmpty
                      ? 'Sin carnet registrado'
                      : 'Carnet ${fila.carnet}',
                  style: const TextStyle(
                    color: ColoresSaman.textoSecundario,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _EtiquetaSolvencia(fila.solvencia),
        ],
      ),
    );
  }
}

class _EtiquetaSolvencia extends StatelessWidget {
  const _EtiquetaSolvencia(this.solvencia);

  final Solvencia solvencia;

  @override
  Widget build(BuildContext context) {
    return switch (solvencia) {
      Solvencia.solvente => const EtiquetaEntrenador(
        'Solvente',
        color: ColoresSaman.verde,
      ),
      Solvencia.noSolvente => const EtiquetaEntrenador(
        'No solvente',
        color: ColoresSaman.rojo,
      ),
      Solvencia.verificando => const EtiquetaEntrenador(
        'Verificando…',
        color: ColoresSaman.textoDiscreto,
      ),
      Solvencia.desconocida => const EtiquetaEntrenador(
        'Sin datos',
        color: ColoresSaman.textoSecundario,
      ),
    };
  }
}
