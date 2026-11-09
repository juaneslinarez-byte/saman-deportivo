import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalogos.dart';
import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/validadores.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../comun/campos_formulario.dart';

/// Formulario para que cada usuario edite los datos de su perfil.
///
/// Se editan el nombre, el apellido y los datos propios de cada actor. El
/// correo, la cédula y el carnet identifican a la persona y no se cambian
/// desde aquí, como en cualquier sistema universitario; el actor, la
/// solvencia y la habilitación solo los cambia el administrador.
class EditarPerfilView extends StatefulWidget {
  const EditarPerfilView({super.key});

  @override
  State<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends State<EditarPerfilView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();

  /// Cargo del administrador o años de experiencia del entrenador.
  final _datoController = TextEditingController();

  /// Carrera del estudiante o especialidad del entrenador, elegidas de una
  /// lista.
  String? _seleccion;

  /// Id del perfil cuyos datos ya se copiaron a los campos.
  String? _idCargado;

  @override
  void initState() {
    super.initState();
    // El botón de guardar se activa solo cuando hay cambios.
    for (final controller in [
      _nombreController,
      _apellidoController,
      _datoController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _datoController.dispose();
    super.dispose();
  }

  /// Copia el perfil a los campos una sola vez, para no borrar lo que el
  /// usuario esté escribiendo cuando el perfil se actualice en tiempo real.
  void _cargarDatos(Persona persona) {
    if (_idCargado == persona.id) return;
    _idCargado = persona.id;
    _nombreController.text = persona.nombre;
    _apellidoController.text = persona.apellido;
    switch (persona) {
      case Estudiante e:
        // Si la carrera guardada no es de la lista, el usuario debe elegirla.
        _seleccion = Catalogos.carreras.contains(e.carrera) ? e.carrera : null;
      case Entrenador e:
        _seleccion = Catalogos.especialidades.contains(e.especialidad)
            ? e.especialidad
            : null;
        _datoController.text = e.aniosExperiencia.toString();
      case Administrador a:
        _datoController.text = a.cargo;
    }
  }

  /// Arma el perfil con los cambios, ya normalizados, conservando lo que el
  /// usuario no edita.
  Persona _conCambios(Persona actual) {
    final nombre = Formatos.nombrePropio(_nombreController.text);
    final apellido = Formatos.nombrePropio(_apellidoController.text);
    final dato = _datoController.text.trim();
    return switch (actual) {
      Estudiante e => Estudiante(
        id: e.id,
        nombre: nombre,
        apellido: apellido,
        cedula: e.cedula,
        correo: e.correo,
        habilitado: e.habilitado,
        carnet: e.carnet,
        carrera: _seleccion ?? e.carrera,
        solvente: e.solvente,
      ),
      Entrenador e => Entrenador(
        id: e.id,
        nombre: nombre,
        apellido: apellido,
        cedula: e.cedula,
        correo: e.correo,
        habilitado: e.habilitado,
        especialidad: _seleccion ?? e.especialidad,
        aniosExperiencia: int.tryParse(dato) ?? e.aniosExperiencia,
      ),
      Administrador a => Administrador(
        id: a.id,
        nombre: nombre,
        apellido: apellido,
        cedula: a.cedula,
        correo: a.correo,
        habilitado: a.habilitado,
        cargo: Formatos.textoDescriptivo(dato),
      ),
      _ => actual,
    };
  }

  /// Compara lo escrito con el perfil guardado.
  bool _hayCambios(Persona actual) {
    final nuevo = _conCambios(actual).toMap();
    final guardado = actual.toMap();
    return nuevo.keys.any((campo) => nuevo[campo] != guardado[campo]) ||
        (actual is Estudiante && _seleccion == null) ||
        (actual is Entrenador && _seleccion == null);
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

  /// Pregunta antes de salir si hay cambios sin guardar.
  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar los cambios?'),
        content: const Text('Los cambios que hiciste no se guardarán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Descartar',
              style: TextStyle(color: ColoresSaman.rojo),
            ),
          ),
        ],
      ),
    );
    if (salir == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final persona = perfilViewModel.perfil;
    if (persona != null) _cargarDatos(persona);
    final hayCambios = persona != null && _hayCambios(persona);

    return PopScope(
      canPop: !hayCambios,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _confirmarSalida();
      },
      child: Scaffold(
        backgroundColor: ColoresSaman.fondo,
        appBar: AppBar(
          title: const Text(
            'Editar perfil',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(28),
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
                  : _buildFormulario(
                      persona,
                      cargando: perfilViewModel.cargando,
                      hayCambios: hayCambios,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario(
    Persona persona, {
    required bool cargando,
    required bool hayCambios,
  }) {
    const espacio = SizedBox(height: 14);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoTexto(
            etiqueta: 'Nombre',
            controller: _nombreController,
            formateadores: Entradas.nombre,
            validator: (v) => Validadores.nombrePropio(v),
          ),
          espacio,
          CampoTexto(
            etiqueta: 'Apellido',
            controller: _apellidoController,
            formateadores: Entradas.nombre,
            validator: (v) => Validadores.nombrePropio(v, campo: 'apellido'),
          ),
          espacio,
          ..._camposDelActor(persona),
          CampoTexto(
            etiqueta: 'Correo institucional',
            valorInicial: persona.correo,
            habilitado: false,
          ),
          espacio,
          CampoTexto(
            etiqueta: 'Cédula',
            valorInicial: persona.cedula,
            habilitado: false,
          ),
          if (persona is Estudiante) ...[
            espacio,
            CampoTexto(
              etiqueta: 'Carnet',
              valorInicial: persona.carnet,
              habilitado: false,
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'El correo, la cédula y el carnet no se pueden cambiar. Si alguno '
            'está mal, pídele al administrador que lo corrija.',
            style: TextStyle(fontSize: 12, color: ColoresSaman.textoSecundario),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.naranja,
              foregroundColor: ColoresSaman.blanco,
              disabledBackgroundColor: ColoresSaman.gris,
              disabledForegroundColor: ColoresSaman.textoDiscreto,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            // Sin cambios no hay nada que guardar.
            onPressed: hayCambios && !cargando ? () => _guardar(persona) : null,
            child: cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ColoresSaman.naranja,
                    ),
                  )
                : const Text(
                    'Guardar cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  /// Campos que dependen del actor del usuario.
  List<Widget> _camposDelActor(Persona persona) {
    const espacio = SizedBox(height: 14);
    return switch (persona) {
      Estudiante() => [
        CampoSeleccion(
          etiqueta: 'Carrera',
          opciones: Catalogos.carreras,
          valor: _seleccion,
          pista: 'Selecciona tu carrera',
          alCambiar: (valor) => setState(() => _seleccion = valor),
          validator: (v) =>
              Validadores.opcion(v, Catalogos.carreras, campo: 'tu carrera'),
        ),
        espacio,
      ],
      Entrenador() => [
        CampoSeleccion(
          etiqueta: 'Especialidad',
          opciones: Catalogos.especialidades,
          valor: _seleccion,
          pista: 'Selecciona tu especialidad',
          alCambiar: (valor) => setState(() => _seleccion = valor),
          validator: (v) => Validadores.opcion(
            v,
            Catalogos.especialidades,
            campo: 'tu especialidad',
          ),
        ),
        espacio,
        CampoTexto(
          etiqueta: 'Años de experiencia',
          controller: _datoController,
          teclado: TextInputType.number,
          formateadores: Entradas.digitos(2),
          validator: Validadores.aniosExperiencia,
        ),
        espacio,
      ],
      Administrador() => [
        CampoTexto(
          etiqueta: 'Cargo',
          controller: _datoController,
          formateadores: Entradas.textoDescriptivo,
          validator: (v) => Validadores.textoDescriptivo(v, campo: 'tu cargo'),
        ),
        espacio,
      ],
      _ => const [],
    };
  }

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
