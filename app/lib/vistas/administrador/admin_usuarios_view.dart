import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../modelos/modelos.dart';
import '../../repositorios/usuario_repository.dart';
import '../../viewmodels/admin_usuarios_viewmodel.dart';
import '../../core/mensajes.dart';
import '../../core/catalogos.dart';
import '../../core/formatos.dart';
import '../../core/validadores.dart';
import '../../core/colores.dart';
import '../comun/campos_formulario.dart';

class AdminUsuariosView extends StatelessWidget {
  final String idAdminActual;

  const AdminUsuariosView({super.key, required this.idAdminActual});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUsuariosViewModel(context.read<UsuarioRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin - Usuarios')),
        body: _AdminUsuariosBody(idAdminActual: idAdminActual),
      ),
    );
  }
}

class _AdminUsuariosBody extends StatelessWidget {
  final String idAdminActual;
  const _AdminUsuariosBody({required this.idAdminActual});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminUsuariosViewModel>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre, cédula, carnet o correo',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: vm.buscar,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: vm.filtroActor == null,
                      onSelected: (_) => vm.filtrarPorActor(null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Estudiantes'),
                      selected: vm.filtroActor == Actor.estudiante,
                      onSelected: (_) => vm.filtrarPorActor(Actor.estudiante),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Entrenadores'),
                      selected: vm.filtroActor == Actor.entrenador,
                      onSelected: (_) => vm.filtrarPorActor(Actor.entrenador),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Admins'),
                      selected: vm.filtroActor == Actor.administrador,
                      onSelected: (_) =>
                          vm.filtrarPorActor(Actor.administrador),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: vm.cargando
              ? const Center(child: CircularProgressIndicator())
              : vm.usuarios.isEmpty
              ? const Center(child: Text('No se encontraron usuarios.'))
              : ListView.builder(
                  itemCount: vm.usuarios.length,
                  itemBuilder: (context, index) {
                    final u = vm.usuarios[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text('${u.nombre} ${u.apellido}'),
                        subtitle: Text('${u.correo}\nCédula: ${u.cedula}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) =>
                              _ejecutarAccion(context, vm, u, val),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'habilitado',
                              child: Text(
                                u.habilitado ? 'Deshabilitar' : 'Habilitar',
                              ),
                            ),
                            if (u is Estudiante) ...[
                              PopupMenuItem(
                                value: 'solvente',
                                child: Text(
                                  u.solvente
                                      ? 'Marcar No Solvente'
                                      : 'Marcar Solvente',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'convertir',
                                child: Text('Convertir en Entrenador'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _ejecutarAccion(
    BuildContext context,
    AdminUsuariosViewModel vm,
    Persona usuario,
    String accion,
  ) async {
    try {
      if (accion == 'habilitado') {
        final confirm = await _confirmar(
          context,
          '¿Deseas cambiar el estado de habilitación de ${usuario.nombre}?',
        );
        if (confirm) await vm.alternarHabilitado(usuario, idAdminActual);
      } else if (accion == 'solvente') {
        final confirm = await _confirmar(
          context,
          '¿Deseas cambiar la solvencia de ${usuario.nombre}?',
        );
        if (confirm) await vm.alternarSolvente(usuario);
      } else if (accion == 'convertir') {
        _mostrarDialogoConvertir(context, vm, usuario);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      }
    }
  }

  Future<bool> _confirmar(BuildContext context, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar Acción'),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _mostrarDialogoConvertir(
    BuildContext context,
    AdminUsuariosViewModel vm,
    Persona usuario,
  ) {
    String? especialidad;
    final expCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setEstado) => AlertDialog(
          title: Text('Convertir a entrenador: ${usuario.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // La especialidad se elige de la lista, como en el perfil.
              CampoSeleccion(
                etiqueta: 'Especialidad',
                opciones: Catalogos.especialidades,
                valor: especialidad,
                pista: 'Selecciona la especialidad',
                alCambiar: (valor) => setEstado(() => especialidad = valor),
              ),
              const SizedBox(height: 14),
              CampoTexto(
                etiqueta: 'Años de experiencia',
                controller: expCtrl,
                teclado: TextInputType.number,
                formateadores: Entradas.digitos(2),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mensaje =
                    Validadores.opcion(
                      especialidad,
                      Catalogos.especialidades,
                      campo: 'la especialidad',
                    ) ??
                    Validadores.aniosExperiencia(expCtrl.text);
                if (mensaje != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(mensaje),
                      backgroundColor: ColoresSaman.rojo,
                    ),
                  );
                  return;
                }
                try {
                  await vm.convertirEnEntrenador(
                    usuario: usuario,
                    especialidad: especialidad!,
                    aniosExperiencia: int.parse(expCtrl.text.trim()),
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
              child: const Text('Convertir'),
            ),
          ],
        ),
      ),
    );
  }
}
