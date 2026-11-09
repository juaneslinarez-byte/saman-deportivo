import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/validadores.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/resena_viewmodel.dart';

/// «Tu reseña de» una disciplina: el estudiante califica con estrellas y
/// comenta la disciplina en la que se inscribió; puede editarla o borrarla.
class FormularioResenaView extends StatefulWidget {
  final Estudiante estudiante;
  final String idDeporte;
  final String nombreDeporte;

  const FormularioResenaView({
    super.key,
    required this.estudiante,
    required this.idDeporte,
    required this.nombreDeporte,
  });

  /// Abre el formulario con su propio ViewModel.
  static Future<void> abrir(
    BuildContext context, {
    required Estudiante estudiante,
    required String idDeporte,
    required String nombreDeporte,
  }) {
    final repositorio = context.read<ResenaRepository>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<ResenaViewModel>(
          create: (_) => ResenaViewModel(repositorio),
          child: FormularioResenaView(
            estudiante: estudiante,
            idDeporte: idDeporte,
            nombreDeporte: nombreDeporte,
          ),
        ),
      ),
    );
  }

  @override
  State<FormularioResenaView> createState() => _FormularioResenaViewState();
}

class _FormularioResenaViewState extends State<FormularioResenaView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();

  final List<String> _ratingLabels = [
    'Mala',
    'Regular',
    'Buena',
    'Muy buena',
    'Excelente',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ResenaViewModel>(context, listen: false);
      viewModel.cargar(widget.estudiante.id, widget.idDeporte);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _syncComment(String text) {
    _commentController.text = text;
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ResenaViewModel viewModel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar reseña?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final success = await viewModel.eliminar();
      if (success && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Reseña eliminada correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
        navigator.pop();
      }
    }
  }

  Future<void> _submitForm(ResenaViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await viewModel.guardar(
      widget.estudiante,
      widget.idDeporte,
    );

    if (success && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu reseña!'),
          backgroundColor: ColoresSaman.verde,
        ),
      );
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(title: Text('Tu reseña de ${widget.nombreDeporte}')),
      body: Consumer<ResenaViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.estado == ResenaEstado.cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.estado == ResenaEstado.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.error ?? 'Error desconocido',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.cargar(
                      widget.estudiante.id,
                      widget.idDeporte,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (_commentController.text != viewModel.comentario &&
              viewModel.comentario.isNotEmpty &&
              _commentController.text.isEmpty) {
            _syncComment(viewModel.comentario);
          }

          final ratingLabel =
              viewModel.calificacion >= 1 && viewModel.calificacion <= 5
              ? _ratingLabels[viewModel.calificacion - 1]
              : '';

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Calificación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          final isSelected =
                              starValue <= viewModel.calificacion;
                          return IconButton(
                            iconSize: 40,
                            icon: Icon(
                              isSelected ? Icons.star : Icons.star_border,
                              color: isSelected ? Colors.amber : Colors.grey,
                            ),
                            onPressed: viewModel.guardando
                                ? null
                                : () => viewModel.setCalificacion(starValue),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ratingLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _commentController,
                        enabled: !viewModel.guardando,
                        maxLines: 4,
                        maxLength: 300,
                        decoration: InputDecoration(
                          labelText: 'Comentario',
                          hintText: 'Cuéntanos tu experiencia (10 a 300 caracteres)...',
                          border: const OutlineInputBorder(),
                          counterText:
                              '${_commentController.text.trim().length}/300',
                        ),
                        validator: Validadores.comentarioResena,
                        onChanged: (text) {
                          viewModel.setComentario(text);
                          setState(() {});
                        },
                      ),
                      if (viewModel.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          viewModel.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: viewModel.puedeGuardar
                            ? () => _submitForm(viewModel)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: viewModel.guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                viewModel.esEdicion
                                    ? 'Guardar cambios'
                                    : 'Publicar',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                      if (viewModel.esEdicion) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: viewModel.guardando
                              ? null
                              : () => _confirmDelete(context, viewModel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Eliminar mi reseña'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
