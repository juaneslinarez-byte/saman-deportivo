import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/deporte_repository.dart';
import '../../viewmodels/sesiones_cupos_viewmodel.dart';
import '../../core/mensajes.dart';
import '../../core/horarios.dart';

class SesionesCuposView extends StatelessWidget {
  final Deporte deporte;

  const SesionesCuposView({super.key, required this.deporte});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SesionesCuposViewModel(
        deporteRepository: context.read<DeporteRepository>(),
        deporte: deporte,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin - Cupos y sesiones: ${deporte.nombre}'),
        ),
        body: const _SesionesCuposBody(),
      ),
    );
  }
}

class _SesionesCuposBody extends StatelessWidget {
  const _SesionesCuposBody();

  String _formatearDia(dynamic dia) {
    if (dia == null) return '';
    if (dia is DiaSemana) {
      // «Miércoles» y «Sábado», con tilde.
      final nombre = Horarios.nombreDia(dia);
      return nombre[0].toUpperCase() + nombre.substring(1);
    }
    return dia.toString();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SesionesCuposViewModel>();

    if (vm.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión de Cupos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoChip(
                        'Inscritos',
                        '${vm.deporte.inscritos}',
                        ColoresSaman.azulNoche,
                      ),
                      _infoChip(
                        'Disponibles',
                        '${vm.deporte.cuposDisponibles}',
                        ColoresSaman.verde,
                      ),
                      _infoChip(
                        'Cupo Máximo',
                        '${vm.deporte.cupoMaximo}',
                        ColoresSaman.naranja,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modificar Cupo Máximo'),
                      onPressed: () => _mostrarDialogoCupo(context, vm),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Horarios / Sesiones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('+ Agregar sesión'),
                onPressed: () => _mostrarDialogoFormularioSesion(context, vm),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.sesiones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text('No hay sesiones configuradas para este deporte.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.sesiones.length,
              itemBuilder: (context, index) {
                final sesion = vm.sesiones[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      '${_formatearDia(sesion.dia)}: ${sesion.horaInicio} - ${sesion.horaFin}',
                    ),
                    subtitle: Text('Lugar: ${sesion.lugar}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: ColoresSaman.azulNoche,
                          ),
                          onPressed: () => _mostrarDialogoFormularioSesion(
                            context,
                            vm,
                            sesion: sesion,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: ColoresSaman.rojo,
                          ),
                          onPressed: () =>
                              _confirmarEliminarSesion(context, vm, sesion),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _infoChip(String titulo, String valor, Color color) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoCupo(BuildContext context, SesionesCuposViewModel vm) {
    final controller = TextEditingController(text: '${vm.deporte.cupoMaximo}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modificar Cupo Máximo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nuevo cupo máximo',
            helperText: 'Mínimo actual inscritos: ${vm.deporte.inscritos}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevo = int.tryParse(controller.text) ?? -1;
              try {
                await vm.actualizarCupoMaximo(nuevo);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoFormularioSesion(
    BuildContext context,
    SesionesCuposViewModel vm, {
    Sesion? sesion,
  }) {
    String diaSeleccionado = sesion != null
        ? _formatearDia(sesion.dia)
        : 'Lunes';
    final horaInicioCtrl = TextEditingController(
      text: sesion?.horaInicio ?? '08:00',
    );
    final horaFinCtrl = TextEditingController(text: sesion?.horaFin ?? '10:00');
    final lugarCtrl = TextEditingController(text: sesion?.lugar ?? '');
    final dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulWidgetBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(sesion == null ? 'Agregar Sesión' : 'Editar Sesión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: diaSeleccionado,
                  items: dias
                      .map(
                        (d) =>
                            DropdownMenuItem<String>(value: d, child: Text(d)),
                      )
                      .toList(),
                  onChanged: (String? val) {
                    if (val != null) {
                      setStateDialog(() => diaSeleccionado = val);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Día de la semana',
                  ),
                ),
                TextField(
                  controller: horaInicioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hora inicio (HH:MM)',
                    hintText: '08:00',
                  ),
                ),
                TextField(
                  controller: horaFinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hora fin (HH:MM)',
                    hintText: '10:00',
                  ),
                ),
                TextField(
                  controller: lugarCtrl,
                  decoration: const InputDecoration(labelText: 'Lugar'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final errorMsg = vm.validarSesion(
                  dia: diaSeleccionado,
                  horaInicio: horaInicioCtrl.text,
                  horaFin: horaFinCtrl.text,
                  lugar: lugarCtrl.text,
                  idSesionEditar: sesion?.id,
                );

                if (errorMsg != null) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text(errorMsg)));
                  return;
                }

                try {
                  await vm.guardarSesion(
                    id: sesion?.id,
                    dia: diaSeleccionado,
                    horaInicio: horaInicioCtrl.text,
                    horaFin: horaFinCtrl.text,
                    lugar: lugarCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(mensajeDeError(e)),
                        backgroundColor: ColoresSaman.rojo,
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarSesion(
    BuildContext context,
    SesionesCuposViewModel vm,
    Sesion sesion,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Sesión'),
        content: Text(
          '¿Seguro que deseas eliminar la sesión del ${_formatearDia(sesion.dia)} (${sesion.horaInicio})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColoresSaman.rojo),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final fueOcultado = await vm.eliminarSesion(sesion);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        fueOcultado
                            ? 'Era la última sesión. El deporte fue ocultado del catálogo.'
                            : 'Sesión eliminada.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mensajeDeError(e)),
                      backgroundColor: ColoresSaman.rojo,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: ColoresSaman.blanco),
            ),
          ),
        ],
      ),
    );
  }
}

class StatefulWidgetBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, StateSetter setState) builder;
  const StatefulWidgetBuilder({super.key, required this.builder});
  @override
  State<StatefulWidgetBuilder> createState() => _StatefulWidgetBuilderState();
}

class _StatefulWidgetBuilderState extends State<StatefulWidgetBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
}
