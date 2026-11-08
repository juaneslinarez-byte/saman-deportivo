import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../modelos/deporte.dart';
import '../../repositorios/deporte_repository.dart';
import '../../repositorios/usuario_repository.dart';
import '../../viewmodels/admin_deportes_viewmodel.dart';
import '../comun/campos_formulario.dart';
import 'deporte_form_view.dart';
import 'sesiones_cupos_view.dart';
import 'admin_usuarios_view.dart';

/// Pantalla de gestión de deportes para el administrador (RF-ADM-01, RF-ADM-02).
class AdminDeportesView extends StatelessWidget {
  const AdminDeportesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminDeportesViewModel>(
      create: (context) => AdminDeportesViewModel(
        context.read<DeporteRepository>(),
        context.read<UsuarioRepository>(),
      ),
      child: const _AdminDeportesCuerpo(),
    );
  }
}

class _AdminDeportesCuerpo extends StatelessWidget {
  const _AdminDeportesCuerpo();

  void _abrirFormulario(BuildContext context, [Deporte? deporte]) {
    final viewModel = context.read<AdminDeportesViewModel>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: DeporteFormView(deporte: deporte),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDeportesViewModel>();
    final deportes = viewModel.deportes;

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Gestión de Deportes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Gestión de Usuarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminUsuariosView(idAdminActual: 'admin_id_actual'),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ColoresSaman.naranja,
        foregroundColor: ColoresSaman.blanco,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Deporte'),
        onPressed: () => _abrirFormulario(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampoTexto(
                  etiqueta: 'Buscar deporte',
                  pista: 'Buscar por nombre o por código (ej. FUT-01)',
                  formateadores: Entradas.busqueda,
                  alCambiar: (texto) => viewModel.buscar(texto),
                ),
                const SizedBox(height: 20),
                Expanded(child: _construirLista(context, viewModel, deportes)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirLista(
    BuildContext context,
    AdminDeportesViewModel viewModel,
    List<Deporte> deportes,
  ) {
    if (viewModel.cargando && deportes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ColoresSaman.naranja),
      );
    }

    if (viewModel.error != null && deportes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              viewModel.error!,
              style: const TextStyle(color: ColoresSaman.textoSecundario),
            ),
          ],
        ),
      );
    }

    if (deportes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_outlined,
              size: 48,
              color: ColoresSaman.textoTenue,
            ),
            SizedBox(height: 12),
            Text(
              'No se encontraron disciplinas deportivas.',
              style: TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: deportes.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deporte = deportes[index];
        return _TarjetaDeporte(
          deporte: deporte,
          onEditar: () => _abrirFormulario(context, deporte),
        );
      },
    );
  }
}

class _TarjetaDeporte extends StatelessWidget {
  const _TarjetaDeporte({required this.deporte, required this.onEditar});

  final Deporte deporte;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDeportesViewModel>();
    final tieneEntrenador = deporte.tieneEntrenador;
    final nombres = viewModel.nombresEntrenadores(deporte);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresSaman.gris),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ColoresSaman.naranjaSuave,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deporte.codigo,
                            style: const TextStyle(
                              color: ColoresSaman.naranja,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deporte.nombre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: ColoresSaman.azulOscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: ColoresSaman.textoSecundario,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deporte.lugar,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ColoresSaman.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Visible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColoresSaman.textoCampo,
                    ),
                  ),
                  Switch(
                    value: deporte.visible,
                    activeThumbColor: ColoresSaman.naranja,
                    onChanged: (val) async {
                      final exito = await viewModel.alternarVisibilidad(
                        deporte,
                      );
                      if (!exito &&
                          viewModel.error != null &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(viewModel.error!),
                            backgroundColor: ColoresSaman.rojo,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      tieneEntrenador ? Icons.how_to_reg : Icons.person_add,
                      size: 18,
                      color: tieneEntrenador
                          ? ColoresSaman.verde
                          : ColoresSaman.textoTenue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        !tieneEntrenador
                            ? 'Sin entrenador'
                            : nombres.length == 1
                            ? nombres.first
                            : '${nombres.length} entrenadores: '
                                  '${nombres.join(', ')}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tieneEntrenador
                              ? ColoresSaman.verde
                              : ColoresSaman.textoTenue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Inscritos: ${deporte.inscritos} / ${deporte.cupoMaximo}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColoresSaman.azulOscuro,
                    side: const BorderSide(color: ColoresSaman.gris),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onEditar,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: ColoresSaman.azulOscuro,
                ),
                tooltip: 'Sesiones y Cupos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SesionesCuposView(deporte: deporte),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.person_add_outlined,
                  color: ColoresSaman.azulOscuro,
                ),
                tooltip: 'Entrenadores',
                onPressed: () => _gestionarEntrenadores(
                  context,
                  deporte,
                  context.read<AdminDeportesViewModel>(),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: ColoresSaman.rojo,
                ),
                tooltip: 'Eliminar Deporte',
                onPressed: () => _eliminarDeporte(
                  context,
                  deporte,
                  context.read<AdminDeportesViewModel>(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _eliminarDeporte(
  BuildContext context,
  Deporte deporte,
  AdminDeportesViewModel vm,
) {
  if (deporte.inscritos > 0) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No se puede eliminar'),
        content: Text(
          'El deporte "${deporte.nombre}" tiene ${deporte.inscritos} alumnos inscritos.\n\n'
          '¿Deseas ocultarlo del catálogo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final exito = await vm.ocultarDeporte(deporte);
              if (context.mounted) {
                _avisar(context, exito, 'Deporte ocultado del catálogo.', vm);
              }
            },
            child: const Text('Ocultar'),
          ),
        ],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Deporte'),
        content: Text('¿Seguro que deseas eliminar "${deporte.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColoresSaman.rojo),
            onPressed: () async {
              Navigator.pop(ctx);
              final exito = await vm.eliminarDeporte(deporte);
              if (context.mounted) {
                _avisar(context, exito, 'Deporte eliminado.', vm);
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

/// Diálogo para elegir los entrenadores de la disciplina: se pueden marcar
/// varios, agregar o quitar. Si se desmarcan todos, la disciplina se oculta.
void _gestionarEntrenadores(
  BuildContext context,
  Deporte deporte,
  AdminDeportesViewModel vm,
) async {
  final entrenadores = await vm.obtenerEntrenadores();
  if (!context.mounted) return;

  final elegidos = <String>[
    for (final id in deporte.idsEntrenadores)
      if (entrenadores.any((e) => e.id == id)) id,
  ];
  final iniciales = List<String>.of(elegidos);

  final guardar = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setEstado) {
        final hayCambios =
            elegidos.length != iniciales.length ||
            elegidos.any((id) => !iniciales.contains(id));
        return AlertDialog(
          title: Text('Entrenadores de ${deporte.nombre}'),
          content: SizedBox(
            width: double.maxFinite,
            child: entrenadores.isEmpty
                ? const Text(
                    'No hay entrenadores registrados. Conviértelos desde '
                    'Usuarios.',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Marca quiénes dan esta disciplina. El primero '
                        'marcado queda como entrenador principal.',
                        style: TextStyle(
                          fontSize: 13,
                          color: ColoresSaman.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final e in entrenadores)
                              CheckboxListTile(
                                value: elegidos.contains(e.id),
                                activeColor: ColoresSaman.naranja,
                                title: Text('${e.nombre} ${e.apellido}'),
                                subtitle: Text(
                                  elegidos.isNotEmpty && elegidos.first == e.id
                                      ? '${e.correo} · Principal'
                                      : e.correo,
                                ),
                                onChanged: (marcado) => setEstado(() {
                                  if (marcado ?? false) {
                                    elegidos.add(e.id);
                                  } else {
                                    elegidos.remove(e.id);
                                  }
                                }),
                              ),
                          ],
                        ),
                      ),
                      if (elegidos.isEmpty && deporte.tieneEntrenador)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Sin entrenadores, la disciplina se ocultará '
                            'del catálogo.',
                            style: TextStyle(
                              fontSize: 13,
                              color: ColoresSaman.rojo,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            if (entrenadores.isNotEmpty)
              ElevatedButton(
                onPressed: hayCambios ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Guardar'),
              ),
          ],
        );
      },
    ),
  );

  if (guardar != true || !context.mounted) return;
  final exito = await vm.guardarEntrenadores(deporte, elegidos);
  if (!context.mounted) return;
  _avisar(
    context,
    exito,
    elegidos.isEmpty
        ? 'Entrenadores quitados. La disciplina quedó oculta.'
        : 'Entrenadores de ${deporte.nombre} actualizados.',
    vm,
  );
}

/// Muestra el resultado de una acción: el éxito en verde o el error del
/// ViewModel en rojo.
void _avisar(
  BuildContext context,
  bool exito,
  String mensajeExito,
  AdminDeportesViewModel vm,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        exito
            ? mensajeExito
            : vm.error ?? 'No se pudo completar la acción. Inténtalo de nuevo.',
      ),
      backgroundColor: exito ? ColoresSaman.verde : ColoresSaman.rojo,
    ),
  );
}
