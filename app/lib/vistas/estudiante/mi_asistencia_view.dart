import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/asistencia_estudiante_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';

/// «Mi asistencia» (RF-EST-06): el historial de asistencia del estudiante,
/// agrupado por disciplina. Si recibe como argumento el id de un deporte,
/// muestra solo esa disciplina.
class MiAsistenciaView extends StatelessWidget {
  const MiAsistenciaView({super.key});

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

    final argumento = ModalRoute.of(context)?.settings.arguments;
    final idDeporte = argumento is String ? argumento : null;

    return ChangeNotifierProvider<AsistenciaEstudianteViewModel>(
      key: ValueKey('${perfil.id}-$idDeporte'),
      create: (context) => AsistenciaEstudianteViewModel(
        asistenciaRepository: context.read<AsistenciaRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
        idEstudiante: perfil.id,
        idDeporte: idDeporte,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AsistenciaEstudianteViewModel>();

    return _Marco(
      child: switch (viewModel.estado) {
        AsistenciaEstudianteEstado.cargando => const _Cargando(),
        AsistenciaEstudianteEstado.error => _Mensaje(
          'No se pudo cargar tu historial. Intenta de nuevo.',
          alReintentar: viewModel.cargar,
        ),
        AsistenciaEstudianteEstado.listo => _Contenido(viewModel: viewModel),
      },
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
          'Mi asistencia',
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

class _Contenido extends StatelessWidget {
  const _Contenido({required this.viewModel});

  final AsistenciaEstudianteViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final grupos = viewModel.grupos;

    final filtro = viewModel.nombreFiltro;

    if (grupos.isEmpty) {
      return _Mensaje(
        filtro == null
            ? 'Todavía no hay asistencia registrada. Aparecerá cuando tu '
                  'entrenador tome la asistencia de una clase.'
            : 'Todavía no hay asistencia registrada en $filtro. Aparecerá '
                  'cuando tu entrenador tome la asistencia de una clase.',
        icono: Icons.event_busy_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Mi asistencia',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          filtro == null
              ? 'Tu historial por disciplina, de más a menos asistencia.'
              : 'Tu historial en $filtro, de la clase más reciente a la más '
                    'antigua.',
          style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 13),
        ),
        const SizedBox(height: 20),
        for (final grupo in grupos)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _TarjetaDeporte(grupo: grupo),
          ),
      ],
    );
  }
}

class _TarjetaDeporte extends StatelessWidget {
  const _TarjetaDeporte({required this.grupo});

  final AsistenciaPorDeporte grupo;

  @override
  Widget build(BuildContext context) {
    final porcentaje = grupo.porcentaje;
    final color = porcentaje >= 75
        ? ColoresSaman.verde
        : porcentaje >= 50
        ? ColoresSaman.naranja
        : ColoresSaman.rojo;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  grupo.nombreDeporte,
                  style: const TextStyle(
                    color: ColoresSaman.azulOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${grupo.presentes} de ${grupo.total}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: grupo.total == 0 ? 0 : grupo.presentes / grupo.total,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${porcentaje.toStringAsFixed(0)} % de asistencia · '
            '${grupo.ausentes} '
            'ausencia${grupo.ausentes == 1 ? '' : 's'}',
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 12,
            ),
          ),
          if (grupo.registros.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'Clases',
              style: TextStyle(
                color: ColoresSaman.azulOscuro,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final registro in grupo.registros)
              _FilaClase(registro: registro),
          ],
        ],
      ),
    );
  }
}

class _FilaClase extends StatelessWidget {
  const _FilaClase({required this.registro});

  final Asistencia registro;

  @override
  Widget build(BuildContext context) {
    final presente = registro.presente;
    final color = presente ? ColoresSaman.verde : ColoresSaman.rojo;
    final etiqueta = presente ? 'Presente' : 'Ausente';
    final fecha = registro.fecha;
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final fechaTexto =
        '${dias[fecha.weekday - 1]} '
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            presente ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            fechaTexto,
            style: const TextStyle(
              color: ColoresSaman.azulOscuro,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              etiqueta,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto, {this.alReintentar, this.icono});

  final String texto;
  final VoidCallback? alReintentar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 48, color: ColoresSaman.textoSecundario),
              const SizedBox(height: 12),
            ],
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
