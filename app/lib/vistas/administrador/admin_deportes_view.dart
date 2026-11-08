import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../modelos/deporte.dart';
import '../../repositorios/deporte_repository.dart';
import '../../viewmodels/admin_deportes_viewmodel.dart';
import '../comun/campos_formulario.dart';
import 'deporte_form_view.dart';

/// Pantalla de gestión de deportes para el administrador (RF-ADM-01, RF-ADM-02).
class AdminDeportesView extends StatelessWidget {
  const AdminDeportesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminDeportesViewModel>(
      create: (context) =>
          AdminDeportesViewModel(context.read<DeporteRepository>()),
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
    final tieneEntrenador =
        deporte.idEntrenador != null && deporte.idEntrenador!.isNotEmpty;

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
              Row(
                children: [
                  Icon(
                    tieneEntrenador ? Icons.how_to_reg : Icons.person_add,
                    size: 18,
                    color: tieneEntrenador
                        ? ColoresSaman.verde
                        : ColoresSaman.textoTenue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tieneEntrenador ? 'Entrenador asignado' : 'Sin entrenador',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tieneEntrenador
                          ? ColoresSaman.verde
                          : ColoresSaman.textoTenue,
                    ),
                  ),
                ],
              ),
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
            ],
          ),
        ],
      ),
    );
  }
}
