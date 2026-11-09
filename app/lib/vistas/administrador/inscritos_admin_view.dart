import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/inscritos_admin_viewmodel.dart';

/// Inscritos de una disciplina para el administrador: ve quién está
/// inscrito, inscribe a un estudiante y saca a quien haga falta
/// (RF-ADM-04).
class InscritosAdminView extends StatelessWidget {
  const InscritosAdminView({super.key, required this.deporte});

  final Deporte deporte;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InscritosAdminViewModel>(
      create: (context) => InscritosAdminViewModel(
        inscripcionRepository: context.read<InscripcionRepository>(),
        usuarioRepository: context.read<UsuarioRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
        deporte: deporte,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InscritosAdminViewModel>();

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: Text(
          'Inscritos: ${vm.deporte.nombre}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: switch (vm.estado) {
        InscritosAdminEstado.cargando => const Center(
          child: CircularProgressIndicator(),
        ),
        InscritosAdminEstado.error => _Mensaje(
          icono: Icons.cloud_off_outlined,
          titulo: 'No se pudieron cargar los inscritos.',
          detalle: 'Revisa tu conexión e inténtalo de nuevo.',
          accion: TextButton.icon(
            onPressed: vm.cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
        InscritosAdminEstado.listo => const _Contenido(),
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InscritosAdminViewModel>();
    final inscritos = vm.inscritos;
    final deporte = vm.deporte;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresSaman.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColoresSaman.gris),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Dato(titulo: 'Inscritos', valor: '${deporte.inscritos}'),
                  _Dato(
                    titulo: 'Disponibles',
                    valor: '${deporte.cuposDisponibles}',
                  ),
                  _Dato(titulo: 'Cupo máximo', valor: '${deporte.cupoMaximo}'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresSaman.naranja,
                    foregroundColor: ColoresSaman.blanco,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(
                    deporte.hayCupo
                        ? 'Inscribir estudiante'
                        : 'Sin cupos disponibles',
                  ),
                  onPressed: deporte.hayCupo && !vm.procesando
                      ? () => _inscribir(context, vm)
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (inscritos.isEmpty)
          const _Mensaje(
            icono: Icons.group_off_outlined,
            titulo: 'Todavía no hay inscritos.',
            detalle:
                'Cuando un estudiante se inscriba aparecerá aquí. También '
                'puedes inscribirlo tú con el botón de arriba.',
          )
        else
          for (final inscripcion in inscritos)
            _FilaInscrito(inscripcion: inscripcion),
      ],
    );
  }
}

class _FilaInscrito extends StatelessWidget {
  const _FilaInscrito({required this.inscripcion});

  final Inscripcion inscripcion;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InscritosAdminViewModel>();
    final perfil = vm.perfilDe(inscripcion);
    final solvente = perfil?.solvente ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inscripcion.nombreEstudiante,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Carnet ${inscripcion.carnetEstudiante} · Desde '
                  '${Formatos.fecha(inscripcion.fecha)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColoresSaman.textoSecundario,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  solvente ? 'Solvente' : 'No solvente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: solvente ? ColoresSaman.verde : ColoresSaman.rojo,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: ColoresSaman.rojo),
            onPressed: vm.procesando ? null : () => _sacar(context, vm),
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text('Sacar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sacar(BuildContext context, InscritosAdminViewModel vm) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sacar de la disciplina'),
        content: Text(
          '¿Sacar a ${inscripcion.nombreEstudiante} de ${vm.deporte.nombre}? '
          'Se liberará su cupo. Su historial de asistencia se conserva y '
          'podrá volver a inscribirse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.rojo,
              foregroundColor: ColoresSaman.blanco,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sacar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final error = await vm.sacar(inscripcion);
    if (!context.mounted) return;
    _avisar(
      context,
      error ?? '${inscripcion.nombreEstudiante} salió de ${vm.deporte.nombre}.',
      exito: error == null,
    );
  }
}

/// Elige un estudiante y lo inscribe después de confirmar.
Future<void> _inscribir(
  BuildContext context,
  InscritosAdminViewModel vm,
) async {
  await vm.recargarEstudiantes();
  if (!context.mounted) return;

  final elegido = await showDialog<Estudiante>(
    context: context,
    builder: (ctx) => ChangeNotifierProvider.value(
      value: vm,
      child: const _DialogoElegirEstudiante(),
    ),
  );
  if (elegido == null || !context.mounted) return;

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar inscripción'),
      content: Text(
        '¿Inscribir a ${elegido.nombreCompleto} (carnet ${elegido.carnet}) '
        'en ${vm.deporte.nombre}? Se ocupará uno de los '
        '${vm.deporte.cuposDisponibles} cupos disponibles.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Inscribir'),
        ),
      ],
    ),
  );
  if (confirmado != true) return;
  final error = await vm.inscribir(elegido);
  if (!context.mounted) return;
  _avisar(
    context,
    error ??
        '${elegido.nombreCompleto} quedó inscrito en ${vm.deporte.nombre}.',
    exito: error == null,
  );
}

class _DialogoElegirEstudiante extends StatefulWidget {
  const _DialogoElegirEstudiante();

  @override
  State<_DialogoElegirEstudiante> createState() =>
      _DialogoElegirEstudianteState();
}

class _DialogoElegirEstudianteState extends State<_DialogoElegirEstudiante> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InscritosAdminViewModel>();
    final candidatos = vm.candidatos(_busqueda);

    return AlertDialog(
      title: const Text('Inscribir estudiante'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Nombre, carnet o correo',
              ),
              onChanged: (texto) => setState(() => _busqueda = texto),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: candidatos.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _busqueda.trim().isEmpty
                            ? 'No hay estudiantes disponibles: todos los '
                                  'habilitados ya están inscritos.'
                            : 'Ningún estudiante coincide con la búsqueda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ColoresSaman.textoSecundario,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final e in candidatos)
                          ListTile(
                            enabled: e.solvente,
                            title: Text(e.nombreCompleto),
                            subtitle: Text(
                              e.solvente
                                  ? 'Carnet ${e.carnet} · ${e.carrera}'
                                  : 'Carnet ${e.carnet} · No solvente: '
                                        'no puede inscribirse',
                            ),
                            trailing: e.solvente
                                ? const Icon(Icons.chevron_right)
                                : const Icon(
                                    Icons.block,
                                    color: ColoresSaman.textoTenue,
                                  ),
                            onTap: () => Navigator.pop(context, e),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: ColoresSaman.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 48, color: ColoresSaman.textoTenue),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresSaman.textoSecundario),
          ),
          if (accion != null) ...[const SizedBox(height: 12), accion!],
        ],
      ),
    );
  }
}

void _avisar(BuildContext context, String mensaje, {required bool exito}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: exito ? ColoresSaman.verde : ColoresSaman.rojo,
    ),
  );
}
