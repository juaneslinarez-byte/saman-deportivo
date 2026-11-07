import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/detalle_disciplina_viewmodel.dart';

/// Detalle de una disciplina (RF-EST-03): foto, descripción, lugar, horario
/// semanal y cupos en tiempo real. Se abre desde el catálogo, que le pasa el
/// id del deporte como argumento de la ruta.
///
/// No muestra el nombre del entrenador: el estudiante no puede leer los
/// perfiles de otros usuarios.
class DetalleDisciplinaView extends StatelessWidget {
  const DetalleDisciplinaView({super.key});

  @override
  Widget build(BuildContext context) {
    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is! String || argumento.isEmpty) {
      return const _Marco(
        child: _Mensaje('No se encontró la disciplina.', conVolver: true),
      );
    }

    return ChangeNotifierProvider<DetalleDisciplinaViewModel>(
      // Si cambia la disciplina, se empieza de nuevo con sus datos.
      key: ValueKey(argumento),
      create: (context) => DetalleDisciplinaViewModel(
        deporteRepository: context.read<DeporteRepository>(),
        idDeporte: argumento,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DetalleDisciplinaViewModel>();
    final deporte = viewModel.deporte;

    return _Marco(
      child: switch (viewModel.estado) {
        DetalleEstado.cargando => const Center(
          child: CircularProgressIndicator(color: ColoresSaman.naranja),
        ),
        DetalleEstado.error => _Mensaje(
          'No se pudo cargar la disciplina. Intenta de nuevo.',
          alReintentar: viewModel.cargar,
          conVolver: true,
        ),
        DetalleEstado.noExiste => const _Mensaje(
          'Esta disciplina ya no está disponible.',
          conVolver: true,
        ),
        DetalleEstado.listo => _Contenido(
          deporte: deporte!,
          sesiones: viewModel.sesiones,
          ocupacion: viewModel.ocupacion,
        ),
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
          'Detalle de la disciplina',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
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

/// Fotos que ya tiene la app; el resto de deportes usa un fondo de color.
const _fotos = [
  ('fútbol', 'assets/imagenes/futbol.jpg'),
  ('futbol', 'assets/imagenes/futbol.jpg'),
  ('baloncesto', 'assets/imagenes/baloncesto.jpg'),
  ('tenis', 'assets/imagenes/tenis.jpg'),
  ('voleibol', 'assets/imagenes/voleibol.jpg'),
];

String? _fotoDe(Deporte deporte) {
  final nombre = deporte.nombre.toLowerCase();
  for (final (clave, ruta) in _fotos) {
    if (nombre.contains(clave)) return ruta;
  }
  return null;
}

String _nombreDia(DiaSemana dia) => switch (dia) {
  DiaSemana.lunes => 'Lunes',
  DiaSemana.martes => 'Martes',
  DiaSemana.miercoles => 'Miércoles',
  DiaSemana.jueves => 'Jueves',
  DiaSemana.viernes => 'Viernes',
  DiaSemana.sabado => 'Sábado',
  DiaSemana.domingo => 'Domingo',
};

BoxDecoration _decoracionTarjeta() {
  return BoxDecoration(
    color: ColoresSaman.blanco,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.deporte,
    required this.sesiones,
    required this.ocupacion,
  });

  final Deporte deporte;
  final List<Sesion> sesiones;
  final double ocupacion;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Foto(deporte: deporte),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _decoracionTarjeta(),
          child: Column(
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
                const SizedBox(height: 8),
                _EtiquetaCodigo(deporte.codigo),
              ],
              if (deporte.descripcion.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  deporte.descripcion,
                  style: const TextStyle(
                    color: ColoresSaman.textoSecundario,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              if (deporte.lugar.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: ColoresSaman.textoSecundario,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deporte.lugar,
                        style: const TextStyle(
                          color: ColoresSaman.azulOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SeccionHorario(sesiones: sesiones),
        const SizedBox(height: 16),
        _SeccionCupos(deporte: deporte, ocupacion: ocupacion),
        const SizedBox(height: 24),
        _BotonInscribirse(deporte: deporte),
      ],
    );
  }
}

/// Foto del deporte o, si no hay, un fondo de color con un ícono.
class _Foto extends StatelessWidget {
  const _Foto({required this.deporte});

  final Deporte deporte;

  @override
  Widget build(BuildContext context) {
    final foto = _fotoDe(deporte);
    const respaldo = ColoredBox(
      color: ColoresSaman.naranjaSuave,
      child: Center(
        child: Icon(
          Icons.sports_soccer_outlined,
          size: 64,
          color: ColoresSaman.naranja,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: foto == null
            ? respaldo
            : Image.asset(
                foto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => respaldo,
              ),
      ),
    );
  }
}

class _EtiquetaCodigo extends StatelessWidget {
  const _EtiquetaCodigo(this.codigo);

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ColoresSaman.naranjaSuave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        codigo,
        style: const TextStyle(
          color: ColoresSaman.naranja,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Una fila por sesión: día, hora y lugar.
class _SeccionHorario extends StatelessWidget {
  const _SeccionHorario({required this.sesiones});

  final List<Sesion> sesiones;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('Horario'),
          const SizedBox(height: 12),
          if (sesiones.isEmpty)
            const Text(
              'Horario por confirmar',
              style: TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 13.5,
              ),
            )
          else
            for (final sesion in sesiones) _FilaSesion(sesion: sesion),
        ],
      ),
    );
  }
}

class _FilaSesion extends StatelessWidget {
  const _FilaSesion({required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ColoresSaman.gris,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: ColoresSaman.naranja),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreDia(sesion.dia),
                    style: const TextStyle(
                      color: ColoresSaman.azulOscuro,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Horarios.hora12(sesion.horaInicio)} - '
                    '${Horarios.hora12(sesion.horaFin)}',
                    style: const TextStyle(
                      color: ColoresSaman.textoSecundario,
                      fontSize: 12.5,
                    ),
                  ),
                  if (sesion.lugar.isNotEmpty)
                    Text(
                      sesion.lugar,
                      style: const TextStyle(
                        color: ColoresSaman.textoSecundario,
                        fontSize: 12.5,
                      ),
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

/// Cupos disponibles con una barra de ocupación.
class _SeccionCupos extends StatelessWidget {
  const _SeccionCupos({required this.deporte, required this.ocupacion});

  final Deporte deporte;
  final double ocupacion;

  @override
  Widget build(BuildContext context) {
    final color = deporte.hayCupo ? ColoresSaman.naranja : ColoresSaman.rojo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('Cupos'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ocupacion,
              minHeight: 10,
              backgroundColor: ColoresSaman.gris,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            deporte.hayCupo
                ? '${deporte.cuposDisponibles} de ${deporte.cupoMaximo} '
                      'cupos disponibles'
                : 'Sin cupos disponibles',
            style: TextStyle(
              color: deporte.hayCupo
                  ? ColoresSaman.azulOscuro
                  : ColoresSaman.rojo,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: ColoresSaman.azulOscuro,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Lleva a confirmar la inscripción, que es de otro módulo. Sin cupos queda
/// desactivado, y mientras se abre la pantalla no admite otro toque.
class _BotonInscribirse extends StatefulWidget {
  const _BotonInscribirse({required this.deporte});

  final Deporte deporte;

  @override
  State<_BotonInscribirse> createState() => _BotonInscribirseState();
}

class _BotonInscribirseState extends State<_BotonInscribirse> {
  bool _abriendo = false;

  Future<void> _inscribirse() async {
    if (_abriendo) return;
    setState(() => _abriendo = true);
    await Navigator.pushNamed(
      context,
      Rutas.confirmarInscripcion,
      arguments: widget.deporte,
    );
    if (mounted) setState(() => _abriendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final hayCupo = widget.deporte.hayCupo;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresSaman.naranja,
          foregroundColor: ColoresSaman.blanco,
          disabledBackgroundColor: ColoresSaman.gris,
          disabledForegroundColor: ColoresSaman.textoSecundario,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        onPressed: hayCupo && !_abriendo ? _inscribirse : null,
        child: Text(
          hayCupo ? 'Inscribirse' : 'Sin cupos',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Mensaje centrado con «Reintentar» (si se pasa [alReintentar]) y «Volver».
class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto, {this.alReintentar, this.conVolver = false});

  final String texto;
  final VoidCallback? alReintentar;
  final bool conVolver;

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
            if (conVolver) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text(
                  'Volver al catálogo',
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
