import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/horarios.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/tomar_asistencia_viewmodel.dart';
import '../comun/campos_formulario.dart';
import 'componentes_entrenador.dart';

/// Lo que recibe la pantalla al abrirse desde el historial: la clase que se
/// quiere corregir. Desde «Mis disciplinas» basta con el [Deporte].
class ArgumentosAsistencia {
  const ArgumentosAsistencia({
    required this.deporte,
    required this.idSesion,
    required this.fecha,
  });

  final Deporte deporte;
  final String idSesion;
  final DateTime fecha;
}

/// Tomar la asistencia de una clase (RF-ENT-03, CU-07).
class TomarAsistenciaView extends StatelessWidget {
  const TomarAsistenciaView({super.key});

  static const String _titulo = 'Tomar asistencia';

  @override
  Widget build(BuildContext context) {
    final argumento = ModalRoute.of(context)!.settings.arguments;
    final deporte = switch (argumento) {
      ArgumentosAsistencia(:final deporte) => deporte,
      final Deporte elegido => elegido,
      _ => null,
    };
    final clase = argumento is ArgumentosAsistencia ? argumento : null;

    // Si se entra escribiendo la dirección, no hay disciplina elegida.
    if (deporte == null) {
      return const MarcoEntrenador(
        titulo: _titulo,
        child: MensajeEntrenador(
          titulo: 'No se indicó la disciplina.',
          detalle: 'Vuelve a «Mis disciplinas» y elige una.',
          icono: Icons.sports_outlined,
        ),
      );
    }

    return ChangeNotifierProvider<TomarAsistenciaViewModel>(
      key: ValueKey('${deporte.id}-${clase?.idSesion}-${clase?.fecha}'),
      create: (context) => TomarAsistenciaViewModel(
        deporteRepository: context.read<DeporteRepository>(),
        inscripcionRepository: context.read<InscripcionRepository>(),
        asistenciaRepository: context.read<AsistenciaRepository>(),
        deporte: deporte,
        idSesionInicial: clase?.idSesion,
        fechaInicial: clase?.fecha,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  /// Pregunta antes de salir si hay marcas sin guardar.
  Future<void> _confirmarSalida(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColoresSaman.blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Salir sin guardar?',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'La asistencia que marcaste no se guardará.',
          style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Seguir marcando',
              style: TextStyle(color: ColoresSaman.textoSecundario),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Salir sin guardar',
              style: TextStyle(color: ColoresSaman.rojo),
            ),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TomarAsistenciaViewModel>();

    return PopScope(
      canPop: !viewModel.hayMarcasSinGuardar,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _confirmarSalida(context);
      },
      child: MarcoEntrenador(
        titulo: TomarAsistenciaView._titulo,
        child: switch (viewModel.estado) {
          TomarAsistenciaEstado.cargando => const CargandoEntrenador(),
          TomarAsistenciaEstado.error => MensajeEntrenador(
            titulo: 'No se pudo cargar la clase.',
            detalle: 'Revisa tu conexión e intenta de nuevo.',
            icono: Icons.cloud_off_outlined,
            alReintentar: viewModel.cargar,
          ),
          TomarAsistenciaEstado.listo =>
            viewModel.sesiones.isEmpty
                ? const MensajeEntrenador(
                    titulo: 'Esta disciplina aún no tiene horario.',
                    detalle:
                        'El administrador debe agregar las sesiones para '
                        'poder tomar la asistencia.',
                    icono: Icons.event_busy_outlined,
                  )
                : _Contenido(viewModel: viewModel),
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.viewModel});

  final TomarAsistenciaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final listaVisible =
        viewModel.sesion != null &&
        viewModel.errorFecha == null &&
        !viewModel.cargandoRegistro &&
        viewModel.inscritos.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                viewModel.deporte.nombre,
                style: const TextStyle(
                  color: ColoresSaman.azulOscuro,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _SelectorClase(viewModel: viewModel),
              const SizedBox(height: 20),
              ..._estadoDeLaLista(),
            ],
          ),
        ),
        if (listaVisible) _BarraGuardar(viewModel: viewModel),
      ],
    );
  }

  /// Lo que va debajo de los selectores según la clase elegida.
  List<Widget> _estadoDeLaLista() {
    if (viewModel.sesion == null) {
      return const [
        MensajeEntrenador(
          titulo: 'Elige la clase',
          detalle: 'Selecciona la sesión y la fecha para ver la lista.',
          icono: Icons.touch_app_outlined,
        ),
      ];
    }
    if (viewModel.errorFecha != null) return const [];
    if (viewModel.cargandoRegistro) {
      return const [
        Padding(padding: EdgeInsets.all(24), child: CargandoEntrenador()),
      ];
    }
    if (viewModel.inscritos.isEmpty) {
      return const [
        MensajeEntrenador(
          titulo: 'Aún no hay inscritos',
          detalle:
              'Cuando un estudiante se inscriba en esta disciplina, podrás '
              'tomarle la asistencia.',
          icono: Icons.group_off_outlined,
        ),
      ];
    }

    return [
      if (viewModel.error != null) ...[
        _Aviso(texto: viewModel.error!, color: ColoresSaman.rojo),
        const SizedBox(height: 12),
      ],
      if (viewModel.yaRegistrada)
        const _Aviso(
          texto:
              'Ya tomaste la asistencia de esta clase. Puedes corregirla y '
              'guardar de nuevo.',
          color: ColoresSaman.naranja,
        )
      else
        const _Aviso(
          texto:
              'Todos empiezan como ausentes: marca a los que vinieron a la '
              'clase.',
          color: ColoresSaman.textoSecundario,
        ),
      const SizedBox(height: 16),
      _Resumen(viewModel: viewModel),
      const SizedBox(height: 12),
      Container(
        decoration: decoracionTarjeta(),
        child: Column(
          children: [
            for (var i = 0; i < viewModel.inscritos.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: ColoresSaman.gris,
                ),
              _FilaAsistencia(
                inscripcion: viewModel.inscritos[i],
                viewModel: viewModel,
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

/// Selectores de la sesión y de la fecha. Ambos son listas cerradas: solo se
/// ofrecen fechas que caen el día de la sesión y que no están en el futuro.
class _SelectorClase extends StatelessWidget {
  const _SelectorClase({required this.viewModel});

  final TomarAsistenciaViewModel viewModel;

  static String _mayuscula(String texto) =>
      texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';

  static String _textoSesion(Sesion sesion) {
    final dia = _mayuscula(Horarios.nombreDia(sesion.dia));
    final horas =
        '${Horarios.hora12(sesion.horaInicio)} - '
        '${Horarios.hora12(sesion.horaFin)}';
    final lugar = sesion.lugar.isEmpty ? '' : ' · ${sesion.lugar}';
    return '$dia · $horas$lugar';
  }

  String _textoFecha(DateTime fecha) {
    final dia = _mayuscula(Horarios.nombreDia(Horarios.diaDe(fecha)));
    final esHoy = Formatos.fecha(fecha) == Formatos.fecha(DateTime.now());
    return '$dia ${Formatos.fecha(fecha)}${esHoy ? ' (hoy)' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    // Cada opción necesita un texto distinto; si dos sesiones coinciden, se
    // numeran.
    final sesionesPorTexto = <String, Sesion>{};
    for (final sesion in viewModel.sesiones) {
      var texto = _textoSesion(sesion);
      var repetida = 2;
      while (sesionesPorTexto.containsKey(texto)) {
        texto = '${_textoSesion(sesion)} ($repetida)';
        repetida++;
      }
      sesionesPorTexto[texto] = sesion;
    }
    final sesion = viewModel.sesion;
    final textoSesion = sesion == null
        ? null
        : sesionesPorTexto.entries
              .where((entrada) => entrada.value.id == sesion.id)
              .map((entrada) => entrada.key)
              .firstOrNull;

    final fechasPorTexto = {
      for (final fecha in viewModel.fechasDisponibles)
        _textoFecha(fecha): fecha,
    };
    final fecha = viewModel.fecha;
    final textoFecha = fecha == null ? null : _textoFecha(fecha);
    final errorFecha = viewModel.errorFecha;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampoSeleccion(
            // Se reconstruye si la sesión cambia desde fuera.
            key: ValueKey('sesion-${sesion?.id}'),
            etiqueta: 'Sesión',
            pista: 'Elige la sesión',
            opciones: sesionesPorTexto.keys.toList(),
            valor: textoSesion,
            alCambiar: viewModel.guardando
                ? (_) {}
                : (texto) {
                    final elegida = sesionesPorTexto[texto];
                    if (elegida != null) viewModel.elegirSesion(elegida);
                  },
          ),
          if (sesion != null) ...[
            const SizedBox(height: 16),
            CampoSeleccion(
              key: ValueKey('fecha-${sesion.id}-$fecha'),
              etiqueta: 'Fecha de la clase',
              pista: 'Elige la fecha',
              opciones: fechasPorTexto.keys.toList(),
              valor: fechasPorTexto.containsKey(textoFecha) ? textoFecha : null,
              alCambiar: viewModel.guardando
                  ? (_) {}
                  : (texto) {
                      final elegida = fechasPorTexto[texto];
                      if (elegida != null) viewModel.elegirFecha(elegida);
                    },
            ),
            if (errorFecha != null) ...[
              const SizedBox(height: 8),
              Text(
                errorFecha,
                style: const TextStyle(color: ColoresSaman.rojo, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Mensaje con un borde de color a la izquierda.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color == ColoresSaman.textoSecundario
              ? ColoresSaman.textoCampo
              : color,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// «12 de 15 presentes» y los botones para marcar a todos.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.viewModel});

  final TomarAsistenciaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final habilitado = !viewModel.guardando;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          viewModel.resumen,
          style: const TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: habilitado ? () => viewModel.marcarTodos(true) : null,
              child: const Text(
                'Todos presentes',
                style: TextStyle(color: ColoresSaman.naranja, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: habilitado ? () => viewModel.marcarTodos(false) : null,
              child: const Text(
                'Todos ausentes',
                style: TextStyle(
                  color: ColoresSaman.textoSecundario,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilaAsistencia extends StatelessWidget {
  const _FilaAsistencia({required this.inscripcion, required this.viewModel});

  final Inscripcion inscripcion;
  final TomarAsistenciaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final presente = viewModel.presente(inscripcion.id);
    final habilitado = !viewModel.guardando;
    final nombre = inscripcion.nombreEstudiante.trim().isEmpty
        ? 'Estudiante sin nombre'
        : inscripcion.nombreEstudiante;

    return InkWell(
      onTap: habilitado ? () => viewModel.alternar(inscripcion.id) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: ColoresSaman.azulOscuro,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inscripcion.carnetEstudiante.isEmpty
                        ? 'Sin carnet registrado'
                        : 'Carnet ${inscripcion.carnetEstudiante}',
                    style: const TextStyle(
                      color: ColoresSaman.textoSecundario,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              presente ? 'Presente' : 'Ausente',
              style: TextStyle(
                color: presente
                    ? ColoresSaman.verde
                    : ColoresSaman.textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: presente,
              activeTrackColor: ColoresSaman.naranja,
              onChanged: habilitado
                  ? (_) => viewModel.alternar(inscripcion.id)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón fijo abajo. Se deshabilita mientras guarda (nada de doble clic) y
/// cuando no hay nada nuevo que guardar.
class _BarraGuardar extends StatelessWidget {
  const _BarraGuardar({required this.viewModel});

  final TomarAsistenciaViewModel viewModel;

  Future<void> _guardar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final guardado = await viewModel.guardar();
    mensajero
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: guardado ? ColoresSaman.verde : ColoresSaman.rojo,
          content: Text(
            guardado
                ? 'Asistencia guardada: ${viewModel.resumen}.'
                : viewModel.error ?? 'No se pudo guardar la asistencia.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final texto = viewModel.yaRegistrada
        ? 'Guardar corrección'
        : 'Guardar asistencia';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: ColoresSaman.blanco,
        border: Border(top: BorderSide(color: ColoresSaman.gris)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.naranja,
              foregroundColor: ColoresSaman.blanco,
              disabledBackgroundColor: ColoresSaman.naranja.withValues(
                alpha: 0.4,
              ),
              disabledForegroundColor: ColoresSaman.blanco,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: viewModel.puedeGuardar ? () => _guardar(context) : null,
            child: viewModel.guardando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ColoresSaman.blanco,
                    ),
                  )
                : Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
