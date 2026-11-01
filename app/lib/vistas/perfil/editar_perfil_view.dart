import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/validadores.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/perfil_viewmodel.dart';

/// Formulario para que cada usuario edite los datos de su perfil.
///
/// Muestra los campos comunes (nombre, apellido y cédula) y los propios de
/// cada actor. El correo no se edita porque es el de la cuenta, y el actor,
/// la solvencia y la habilitación solo los cambia el administrador.
class EditarPerfilView extends StatefulWidget {
  const EditarPerfilView({super.key});

  @override
  State<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends State<EditarPerfilView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();

  // Campos propios de cada actor: carnet y carrera del estudiante,
  // especialidad y años de experiencia del entrenador, cargo del
  // administrador.
  final _dato1Controller = TextEditingController();
  final _dato2Controller = TextEditingController();

  /// Id del perfil cuyos datos ya se copiaron a los campos.
  String? _idCargado;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _dato1Controller.dispose();
    _dato2Controller.dispose();
    super.dispose();
  }

  /// Copia el perfil a los campos una sola vez, para no borrar lo que el
  /// usuario esté escribiendo cuando el perfil se actualice en tiempo real.
  void _cargarDatos(Persona persona) {
    if (_idCargado == persona.id) return;
    _idCargado = persona.id;
    _nombreController.text = persona.nombre;
    _apellidoController.text = persona.apellido;
    _cedulaController.text = persona.cedula;
    switch (persona) {
      case Estudiante e:
        _dato1Controller.text = e.carnet;
        _dato2Controller.text = e.carrera;
      case Entrenador e:
        _dato1Controller.text = e.especialidad;
        _dato2Controller.text = e.aniosExperiencia.toString();
      case Administrador a:
        _dato1Controller.text = a.cargo;
    }
  }

  /// Arma el perfil con los cambios, conservando lo que el usuario no edita.
  Persona _conCambios(Persona actual) {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final cedula = _cedulaController.text.trim();
    final dato1 = _dato1Controller.text.trim();
    final dato2 = _dato2Controller.text.trim();
    return switch (actual) {
      Estudiante e => Estudiante(
        id: e.id,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: e.correo,
        habilitado: e.habilitado,
        carnet: dato1,
        carrera: dato2,
        solvente: e.solvente,
      ),
      Entrenador e => Entrenador(
        id: e.id,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: e.correo,
        habilitado: e.habilitado,
        especialidad: dato1,
        aniosExperiencia: int.parse(dato2),
      ),
      Administrador a => Administrador(
        id: a.id,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: a.correo,
        habilitado: a.habilitado,
        cargo: dato1,
      ),
      _ => actual,
    };
  }

  Future<void> _guardar(Persona actual) async {
    if (!_formKey.currentState!.validate()) return;

    final perfilViewModel = context.read<PerfilViewModel>();
    final exito = await perfilViewModel.guardarCambios(_conCambios(actual));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? 'Perfil actualizado.'
              : perfilViewModel.error ?? 'No se pudieron guardar los cambios.',
        ),
        backgroundColor: exito ? ColoresSaman.verde : ColoresSaman.rojo,
      ),
    );
    if (exito) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final persona = perfilViewModel.perfil;
    if (persona != null) _cargarDatos(persona);

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ColoresSaman.blanco,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: persona == null
                ? _buildSinPerfil(perfilViewModel)
                : _buildFormulario(persona, perfilViewModel.cargando),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario(Persona persona, bool cargando) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            controller: _nombreController,
            etiqueta: 'Nombre',
            validator: Validadores.nombrePropio,
          ),
          _campo(
            controller: _apellidoController,
            etiqueta: 'Apellido',
            validator: Validadores.nombrePropio,
          ),
          _campo(
            controller: _cedulaController,
            etiqueta: 'Cédula',
            validator: Validadores.cedula,
          ),
          ..._camposDelActor(persona),
          _campoFijo('Correo institucional', persona.correo),
          const SizedBox(height: 16),
          cargando
              ? const Center(
                  child: CircularProgressIndicator(color: ColoresSaman.naranja),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresSaman.naranja,
                    foregroundColor: ColoresSaman.blanco,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => _guardar(persona),
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }

  /// Campos que dependen del actor del usuario.
  List<Widget> _camposDelActor(Persona persona) => switch (persona) {
    Estudiante() => [
      _campo(
        controller: _dato1Controller,
        etiqueta: 'Carnet',
        validator: Validadores.carnet,
      ),
      _campo(
        controller: _dato2Controller,
        etiqueta: 'Carrera',
        validator: Validadores.textoDescriptivo,
      ),
    ],
    Entrenador() => [
      _campo(
        controller: _dato1Controller,
        etiqueta: 'Especialidad',
        validator: Validadores.textoDescriptivo,
      ),
      _campo(
        controller: _dato2Controller,
        etiqueta: 'Años de experiencia',
        validator: Validadores.aniosExperiencia,
        teclado: TextInputType.number,
      ),
    ],
    Administrador() => [
      _campo(
        controller: _dato1Controller,
        etiqueta: 'Cargo',
        validator: Validadores.textoDescriptivo,
      ),
    ],
    _ => const [],
  };

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    required FormFieldValidator<String> validator,
    TextInputType teclado = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: teclado,
        decoration: _decoracion(etiqueta),
        validator: validator,
      ),
    );
  }

  /// Dato que se muestra pero no se puede editar.
  Widget _campoFijo(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: valor,
        enabled: false,
        decoration: _decoracion(etiqueta),
      ),
    );
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
    labelText: etiqueta,
    labelStyle: const TextStyle(color: ColoresSaman.textoSecundario),
    filled: true,
    fillColor: ColoresSaman.gris,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );

  Widget _buildSinPerfil(PerfilViewModel perfilViewModel) {
    if (perfilViewModel.estado == PerfilEstado.cargando) {
      return const Center(
        child: CircularProgressIndicator(color: ColoresSaman.naranja),
      );
    }
    return Text(
      perfilViewModel.error ?? 'Inicia sesión para editar tu perfil.',
      style: const TextStyle(color: ColoresSaman.textoSecundario),
      textAlign: TextAlign.center,
    );
  }
}
