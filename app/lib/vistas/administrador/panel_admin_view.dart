import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../core/solvencia.dart';
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

String _porcentaje(double valor) => '${(valor * 100).round()} %';

String _hora(DateTime fecha) =>
    '${fecha.hour.toString().padLeft(2, '0')}:'
    '${fecha.minute.toString().padLeft(2, '0')}';

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
                'En tiempo real · última actualización ${_hora(actualizado)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, restricciones) {
                const espacio = 12.0;
                // Cinco en pantalla ancha, tres en tableta y dos en teléfono.
                final columnas = restricciones.maxWidth >= 900
                    ? 5
                    : restricciones.maxWidth >= 560
                    ? 3
                    : restricciones.maxWidth >= 330
                    ? 2
                    : 1;
                final ancho =
                    (restricciones.maxWidth - espacio * (columnas - 1)) /
                    columnas;
                final tarjetas = [
                  _Indicador(
                    icono: Icons.school_outlined,
                    titulo: 'Estudiantes',
                    valor: '${vm.totalEstudiantes}',
                    detalle:
                        '${vm.estudiantesSolventes} solventes · '
                        '${vm.estudiantesNoSolventes} sin solvencia',
                    ruta: Rutas.adminUsuarios,
                  ),
                  _Indicador(
                    icono: Icons.sports_outlined,
                    titulo: 'Disciplinas',
                    valor: '${vm.totalDisciplinas}',
                    detalle:
                        '${vm.disciplinasPublicadas} publicadas · '
                        '${vm.totalEntrenadores} entrenadores',
                    ruta: Rutas.adminDeportes,
                  ),
                  _Indicador(
                    icono: Icons.how_to_reg_outlined,
                    titulo: 'Inscripciones activas',
                    valor: '${vm.inscripcionesActivas}',
                    detalle:
                        'Ocupación ${_porcentaje(vm.ocupacionGlobal)} de '
                        '${vm.cupoTotal} cupos',
                  ),
                  _Indicador(
                    icono: Icons.fact_check_outlined,
                    titulo: 'Asistencia',
                    valor: asistencia == null ? '—' : _porcentaje(asistencia),
                    detalle: asistencia == null
                        ? 'Aún no se ha tomado asistencia'
                        : 'Promedio de ${vm.registrosAsistencia} registros',
                  ),
                  _Indicador(
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
                ];
                return Wrap(
                  spacing: espacio,
                  runSpacing: espacio,
                  children: [
                    for (final t in tarjetas) SizedBox(width: ancho, child: t),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _Seccion(
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
                          _FilaAlerta(alerta: alerta),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _Seccion(
              titulo: 'Solvencia de los estudiantes',
              child: vm.totalEstudiantes == 0
                  ? const _SinDatos('Todavía no hay estudiantes registrados.')
                  : _BarraSolvencia(vm: vm),
            ),
            const SizedBox(height: 16),
            _Seccion(
              titulo: 'Ocupación por disciplina',
              child: vm.disciplinas.isEmpty
                  ? const _SinDatos('Todavía no hay disciplinas creadas.')
                  : Column(
                      children: [
                        for (final r in vm.disciplinas)
                          _Barra(
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
            _Seccion(
              titulo: 'Asistencia por disciplina',
              child: vm.disciplinasConAsistencia.isEmpty
                  ? const _SinDatos(
                      'Cuando los entrenadores tomen la asistencia, aquí verás '
                      'el porcentaje de cada disciplina.',
                    )
                  : Column(
                      children: [
                        for (final r in vm.disciplinasConAsistencia)
                          _Barra(
                            etiqueta: r.deporte.nombre,
                            detalle:
                                '${_porcentaje(r.asistencia!)} · '
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

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    this.ruta,
    this.resaltado = false,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;
  final String? ruta;
  final bool resaltado;

  @override
  Widget build(BuildContext context) {
    final ruta = this.ruta;
    return Material(
      color: ColoresSaman.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: ruta == null ? null : () => Navigator.pushNamed(context, ruta),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: resaltado ? ColoresSaman.naranja : ColoresSaman.gris,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 20, color: ColoresSaman.naranja),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColoresSaman.textoSecundario,
                      ),
                    ),
                  ),
                  if (ruta != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: ColoresSaman.textoTenue,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detalle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FilaAlerta extends StatelessWidget {
  const _FilaAlerta({required this.alerta});

  final AlertaPanel alerta;

  @override
  Widget build(BuildContext context) {
    final ruta = alerta.ruta;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: ruta == null ? null : () => Navigator.pushNamed(context, ruta),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: ColoresSaman.naranja,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alerta.texto,
                style: const TextStyle(
                  fontSize: 13,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
            ),
            if (ruta != null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: ColoresSaman.textoTenue,
              ),
          ],
        ),
      ),
    );
  }
}

/// Fila con una barra horizontal de 0 a 100 %.
class _Barra extends StatelessWidget {
  const _Barra({
    required this.etiqueta,
    required this.detalle,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String detalle;
  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                detalle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: valor.clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: ColoresSaman.gris,
              color: color,
            ),
          ),
        ],
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
            _Leyenda(
              color: ColoresSaman.verde,
              texto:
                  'Solventes: $solventes '
                  '(${_porcentaje(solventes / total)})',
            ),
            _Leyenda(
              color: ColoresSaman.rojo.withValues(alpha: 0.35),
              texto: 'Sin solvencia: ${vm.estudiantesNoSolventes}',
            ),
          ],
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, color: ColoresSaman.azulOscuro),
        ),
      ],
    );
  }
}

class _SinDatos extends StatelessWidget {
  const _SinDatos(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 13, color: ColoresSaman.textoSecundario),
    );
  }
}
