import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/historial_asistencia_viewmodel.dart';
import 'componentes_entrenador.dart';
import 'tomar_asistencia_view.dart';

/// Historial de asistencia de una disciplina (RF-ENT-04), en dos pestañas:
/// «Por clase» y «Por estudiante». Recibe el [Deporte] como argumento de la
/// ruta.
class HistorialAsistenciaView extends StatelessWidget {
  const HistorialAsistenciaView({super.key});

  static const String _titulo = 'Historial de asistencia';

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

    return ChangeNotifierProvider<HistorialAsistenciaViewModel>(
      key: ValueKey(argumento.id),
      create: (context) => HistorialAsistenciaViewModel(
        asistenciaRepository: context.read<AsistenciaRepository>(),
        inscripcionRepository: context.read<InscripcionRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
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
    final viewModel = context.watch<HistorialAsistenciaViewModel>();
    final conDatos =
        viewModel.estado == HistorialEstado.listo &&
        viewModel.clases.isNotEmpty;

    return DefaultTabController(
      length: 2,
      child: MarcoEntrenador(
        titulo: HistorialAsistenciaView._titulo,
        // Las pestañas solo aparecen cuando hay algo que mostrar.
        abajo: conDatos
            ? const TabBar(
                labelColor: ColoresSaman.naranja,
                unselectedLabelColor: ColoresSaman.textoSecundario,
                indicatorColor: ColoresSaman.naranja,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Por clase'),
                  Tab(text: 'Por estudiante'),
                ],
              )
            : null,
        child: switch (viewModel.estado) {
          HistorialEstado.cargando => const CargandoEntrenador(),
          HistorialEstado.error => MensajeEntrenador(
            titulo: 'No se pudo cargar el historial.',
            detalle: 'Revisa tu conexión e intenta de nuevo.',
            icono: Icons.cloud_off_outlined,
            alReintentar: viewModel.cargar,
          ),
          HistorialEstado.listo =>
            viewModel.clases.isEmpty
                ? const MensajeEntrenador(
                    titulo: 'Aún no hay asistencias registradas',
                    detalle:
                        'Cuando tomes la asistencia de una clase, aparecerá '
                        'aquí.',
                    icono: Icons.history,
                  )
                : TabBarView(
                    children: [
                      _PorClase(deporte: deporte, viewModel: viewModel),
                      _PorEstudiante(deporte: deporte, viewModel: viewModel),
                    ],
                  ),
        },
      ),
    );
  }
}

/// Nombre de la disciplina y la asistencia general, arriba de cada pestaña.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.deporte, required this.detalle});

  final Deporte deporte;
  final String detalle;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 4),
        Text(
          detalle,
          style: const TextStyle(
            color: ColoresSaman.textoSecundario,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Verde desde 75 %, naranja desde 50 % y rojo por debajo.
Color _colorPorcentaje(int porcentaje) {
  if (porcentaje >= 75) return ColoresSaman.verde;
  if (porcentaje >= 50) return ColoresSaman.naranja;
  return ColoresSaman.rojo;
}

String _mayuscula(String texto) =>
    texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';

class _PorClase extends StatelessWidget {
  const _PorClase({required this.deporte, required this.viewModel});

  final Deporte deporte;
  final HistorialAsistenciaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final clases = viewModel.clases;
    final cantidad = clases.length == 1 ? '1 clase' : '${clases.length} clases';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Encabezado(
          deporte: deporte,
          detalle:
              '$cantidad registradas · ${viewModel.porcentajeGeneral} % de '
              'asistencia',
        ),
        for (final clase in clases)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TarjetaClase(deporte: deporte, clase: clase),
          ),
      ],
    );
  }
}

class _TarjetaClase extends StatelessWidget {
  const _TarjetaClase({required this.deporte, required this.clase});

  final Deporte deporte;
  final ClaseHistorial clase;

  /// Abre la clase en «Tomar asistencia» para revisarla o corregirla.
  void _abrir(BuildContext context) {
    Navigator.pushNamed(
      context,
      Rutas.asistenciaEntrenador,
      arguments: ArgumentosAsistencia(
        deporte: deporte,
        idSesion: clase.idSesion,
        fecha: clase.fecha,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = clase.sesion;
    final dia = _mayuscula(Horarios.nombreDia(Horarios.diaDe(clase.fecha)));
    final horario = sesion == null
        ? 'Sesión eliminada del horario'
        : '${Horarios.hora12(sesion.horaInicio)} - '
              '${Horarios.hora12(sesion.horaFin)}'
              '${sesion.lugar.isEmpty ? '' : ' · ${sesion.lugar}'}';
    final porcentaje = clase.total == 0
        ? 0
        : (clase.presentes * 100 / clase.total).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Una clase de una sesión eliminada ya no se puede corregir.
        onTap: sesion == null ? null : () => _abrir(context),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: decoracionTarjeta(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dia ${Formatos.fecha(clase.fecha)}',
                      style: const TextStyle(
                        color: ColoresSaman.azulOscuro,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      horario,
                      style: const TextStyle(
                        color: ColoresSaman.textoSecundario,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${clase.presentes} de ${clase.total} presentes',
                      style: TextStyle(
                        color: _colorPorcentaje(porcentaje),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (sesion != null)
                const Icon(
                  Icons.chevron_right,
                  color: ColoresSaman.textoDiscreto,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PorEstudiante extends StatelessWidget {
  const _PorEstudiante({required this.deporte, required this.viewModel});

  final Deporte deporte;
  final HistorialAsistenciaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final estudiantes = viewModel.estudiantes;
    final cantidad = estudiantes.length == 1
        ? '1 estudiante'
        : '${estudiantes.length} estudiantes';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Encabezado(
          deporte: deporte,
          detalle: '$cantidad con asistencia registrada',
        ),
        Container(
          decoration: decoracionTarjeta(),
          child: Column(
            children: [
              for (var i = 0; i < estudiantes.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 18,
                    endIndent: 18,
                    color: ColoresSaman.gris,
                  ),
                _FilaEstudiante(estudiante: estudiantes[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaEstudiante extends StatelessWidget {
  const _FilaEstudiante({required this.estudiante});

  final AsistenciaDeEstudiante estudiante;

  @override
  Widget build(BuildContext context) {
    final color = _colorPorcentaje(estudiante.porcentaje);
    final clases = estudiante.total == 1
        ? '${estudiante.presentes} de 1 clase'
        : '${estudiante.presentes} de ${estudiante.total} clases';
    final carnet = estudiante.carnet.isEmpty
        ? ''
        : 'Carnet ${estudiante.carnet} · ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      estudiante.nombre,
                      style: const TextStyle(
                        color: ColoresSaman.azulOscuro,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!estudiante.activo)
                      const EtiquetaEntrenador(
                        'Canceló',
                        color: ColoresSaman.textoSecundario,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$carnet$clases',
                  style: const TextStyle(
                    color: ColoresSaman.textoSecundario,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: estudiante.porcentaje / 100,
                    minHeight: 6,
                    backgroundColor: ColoresSaman.gris,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${estudiante.porcentaje} %',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
