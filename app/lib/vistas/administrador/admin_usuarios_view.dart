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
import '../comun/disenio.dart';

class AdminUsuariosView extends StatelessWidget {
  final String idAdminActual;

  const AdminUsuariosView({super.key, required this.idAdminActual});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUsuariosViewModel(context.read<UsuarioRepository>()),
      child: Scaffold(
        backgroundColor: ColoresSaman.fondo,
        appBar: AppBar(title: const Text('Usuarios')),
        body: _AdminUsuariosBody(idAdminActual: idAdminActual),
      ),
    );
  }
}

class _AdminUsuariosBody extends StatelessWidget {
  final String idAdminActual;
  const _AdminUsuariosBody({required this.idAdminActual});

  static (String, Color, IconData) _actor(Persona u) => switch (u.actor) {
    Actor.estudiante => ('Estudiante', ColoresSaman.naranja, Icons.school),
    Actor.entrenador => ('Entrenador', ColoresSaman.menta, Icons.sports),
    Actor.administrador => (
      'Administrador',
      ColoresSaman.violeta,
      Icons.admin_panel_settings,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminUsuariosViewModel>();

    final filtros = <(String, Actor?)>[
      ('Todos', null),
      ('Estudiantes', Actor.estudiante),
      ('Entrenadores', Actor.entrenador),
      ('Administradores', Actor.administrador),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PortadaDegradado(
            anchoMaximo: 1000,
            titulo: 'Comunidad Samán',
            subtitulo:
                'Habilita cuentas, marca la solvencia y convierte '
                'estudiantes en entrenadores.',
            debajo: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PildoraClara(
                  texto: '${vm.cuantos(null)} usuarios',
                  icono: Icons.people_alt_outlined,
                ),
                PildoraClara(
                  texto: '${vm.cuantos(Actor.estudiante)} estudiantes',
                  icono: Icons.school_outlined,
                ),
                PildoraClara(
                  texto: '${vm.cuantos(Actor.entrenador)} entrenadores',
                  icono: Icons.sports_outlined,
                ),
                if (vm.deshabilitados > 0)
                  PildoraClara(
                    texto: '${vm.deshabilitados} deshabilitados',
                    icono: Icons.block,
                    color: ColoresSaman.rojo.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, cédula, carnet o correo',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: ColoresSaman.blanco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE6E9F2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE6E9F2),
                          ),
                        ),
                      ),
                      onChanged: vm.buscar,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (texto, actor) in filtros)
                          ChoiceChip(
                            label: Text('$texto (${vm.cuantos(actor)})'),
                            selected: vm.filtroActor == actor,
                            showCheckmark: false,
                            selectedColor: ColoresSaman.azulNoche,
                            backgroundColor: ColoresSaman.blanco,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: vm.filtroActor == actor
                                  ? ColoresSaman.blanco
                                  : ColoresSaman.azulOscuro,
                            ),
                            onSelected: (_) => vm.filtrarPorActor(actor),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (vm.cargando)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (vm.error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vm.error!),
                  TextButton(
                    onPressed: vm.cargarUsuarios,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (vm.usuarios.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No se encontraron usuarios.')),
          )
        else
          SliverList.builder(
            itemCount: vm.usuarios.length,
            itemBuilder: (context, index) {
              final u = vm.usuarios[index];
              final (nombreActor, colorActor, iconoActor) = _actor(u);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Aparecer(
                      retraso: Aparecer.escalonado(index, pasoMs: 40),
                      child: TarjetaInteractiva(
                        relleno: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: u.habilitado ? 1 : 0.45,
                              child: AvatarIniciales(nombre: u.nombreCompleto),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.nombreCompleto,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: ColoresSaman.azulOscuro,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${u.correo} · Cédula ${u.cedula}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ColoresSaman.textoSecundario,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      Insignia(
                                        texto: nombreActor,
                                        color: colorActor,
                                        icono: iconoActor,
                                      ),
                                      if (!u.habilitado)
                                        const Insignia(
                                          texto: 'Deshabilitado',
                                          color: ColoresSaman.rojo,
                                          icono: Icons.block,
                                        ),
                                      if (u is Estudiante)
                                        Insignia(
                                          texto: u.solvente
                                              ? 'Solvente'
                                              : 'Sin solvencia',
                                          color: u.solvente
                                              ? ColoresSaman.verde
                                              : ColoresSaman.ambar,
                                          icono: u.solvente
                                              ? Icons.verified
                                              : Icons.hourglass_empty,
                                        ),
                                      if (u is Entrenador)
                                        Insignia(
                                          texto: u.especialidad,
                                          color: ColoresSaman.cielo,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Acciones',
                              icon: const Icon(
                                Icons.more_vert,
                                color: ColoresSaman.textoSecundario,
                              ),
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
                                          ? 'Marcar sin solvencia'
                                          : 'Marcar solvente',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'convertir',
                                    child: Text('Convertir en entrenador'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
