import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/validadores.dart';
import '../../modelos/deporte.dart';
import '../../viewmodels/admin_deportes_viewmodel.dart';
import '../comun/campos_formulario.dart';

/// Formulario para crear o editar un deporte (RF-ADM-01).
class DeporteFormView extends StatefulWidget {
  const DeporteFormView({super.key, this.deporte});

  final Deporte? deporte;

  @override
  State<DeporteFormView> createState() => _DeporteFormViewState();
}

class _DeporteFormViewState extends State<DeporteFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _lugarController;
  late final TextEditingController _cupoMaximoController;

  bool get esEdicion => widget.deporte != null;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(
      text: widget.deporte?.codigo ?? '',
    );
    _nombreController = TextEditingController(
      text: widget.deporte?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.deporte?.descripcion ?? '',
    );
    _lugarController = TextEditingController(text: widget.deporte?.lugar ?? '');
    _cupoMaximoController = TextEditingController(
      text: widget.deporte != null ? widget.deporte!.cupoMaximo.toString() : '',
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _lugarController.dispose();
    _cupoMaximoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AdminDeportesViewModel>();
    final cupoParsed = int.parse(_cupoMaximoController.text.trim());

    final exito = await viewModel.guardarDeporte(
      id: widget.deporte?.id,
      codigo: _codigoController.text,
      nombre: Formatos.textoDescriptivo(_nombreController.text),
      descripcion: Formatos.textoDescriptivo(_descripcionController.text),
      lugar: Formatos.textoDescriptivo(_lugarController.text),
      cupoMaximo: cupoParsed,
    );

    if (!mounted) return;

    if (exito) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Deporte actualizado correctamente.'
                : 'Deporte creado correctamente (permanecerá oculto).',
          ),
          backgroundColor: ColoresSaman.verde,
        ),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error!),
          backgroundColor: ColoresSaman.rojo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.watch<AdminDeportesViewModel>().cargando;
    final inscritosActuales = widget.deporte?.inscritos ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ColoresSaman.blanco,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      esEdicion ? 'Editar Deporte' : 'Nuevo Deporte',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColoresSaman.azulOscuro,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: ColoresSaman.textoSecundario,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Código único',
                  controller: _codigoController,
                  pista: 'Ej. FUT-01',
                  ayuda: 'Código único para identificar la disciplina',
                  habilitado: !cargando,
                  validator: (val) {
                    final req = Validadores.requerido(val);
                    if (req != null) return req;
                    final texto = val!.trim();
                    if (texto.length < 3 || texto.length > 10) {
                      return 'El código debe tener entre 3 y 10 caracteres';
                    }
                    final viewModel = context.read<AdminDeportesViewModel>();
                    if (!viewModel.esCodigoUnico(
                      texto,
                      idDeporteActual: widget.deporte?.id,
                    )) {
                      return 'Este código ya pertenece a otro deporte';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  etiqueta: 'Nombre de la disciplina',
                  controller: _nombreController,
                  pista: 'Ej. Fútbol Campo',
                  formateadores: Entradas.nombre,
                  habilitado: !cargando,
                  validator: (val) =>
                      Validadores.textoDescriptivo(val, campo: 'el nombre'),
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  etiqueta: 'Lugar de entrenamiento',
                  controller: _lugarController,
                  pista: 'Ej. Cancha de Grama Sintética',
                  formateadores: Entradas.textoDescriptivo,
                  habilitado: !cargando,
                  validator: (val) =>
                      Validadores.textoDescriptivo(val, campo: 'el lugar'),
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  etiqueta: 'Cupo máximo de estudiantes',
                  controller: _cupoMaximoController,
                  pista: 'Ej. 30',
                  teclado: TextInputType.number,
                  formateadores: Entradas.digitos(3),
                  habilitado: !cargando,
                  validator: (val) {
                    final req = Validadores.requerido(val);
                    if (req != null) return req;
                    final numero = int.tryParse(val!.trim());
                    if (numero == null || numero <= 0) {
                      return 'El cupo debe ser mayor a 0';
                    }
                    if (esEdicion && numero < inscritosActuales) {
                      return 'No puede ser menor a los inscritos actuales ($inscritosActuales)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  etiqueta: 'Descripción / Requisitos (Opcional)',
                  controller: _descripcionController,
                  pista:
                      'Detalles sobre la disciplina o equipamiento requerido',
                  habilitado: !cargando,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresSaman.naranja,
                      foregroundColor: ColoresSaman.blanco,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: cargando ? null : _guardar,
                    child: cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: ColoresSaman.blanco,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            esEdicion ? 'Guardar Cambios' : 'Crear Deporte',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
