import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/catalogos.dart';
import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/rutas.dart';
import '../../core/validadores.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../comun/campos_formulario.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _carnetController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _prefijoCedula = 'V';
  String? _carrera;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _carnetController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final authViewModel = context.read<AuthViewModel>();
    // Los datos se guardan normalizados: «  juan  PÉREZ » queda «Juan Pérez»
    // y la cédula siempre como «V-28123456».
    final exito = await authViewModel.registrar(
      nombre: Formatos.nombrePropio(_nombreController.text),
      apellido: Formatos.nombrePropio(_apellidoController.text),
      cedula: Formatos.cedula(_prefijoCedula, _cedulaController.text),
      carnet: _carnetController.text.trim(),
      carrera: _carrera!,
      correo: Formatos.correo(_correoController.text),
      contrasena: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (exito) {
      // Al entrar se borra el historial: «atrás» no vuelve al formulario.
      Navigator.pushNamedAndRemoveUntil(context, Rutas.inicio, (ruta) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'No se pudo crear la cuenta.'),
          backgroundColor: ColoresSaman.rojo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeUnimet = ColoresSaman.naranja;
    const espacio = SizedBox(height: 14);

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
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
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                // Cada campo muestra su error en cuanto el usuario lo toca.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColoresSaman.azulOscuro,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registro de estudiantes con correo institucional',
                      style: TextStyle(
                        fontSize: 13,
                        color: ColoresSaman.textoSecundario,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CampoTexto(
                            etiqueta: 'Nombre',
                            pista: 'Juan',
                            controller: _nombreController,
                            formateadores: Entradas.nombre,
                            autocompletar: const [AutofillHints.givenName],
                            validator: (v) => Validadores.nombrePropio(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTexto(
                            etiqueta: 'Apellido',
                            pista: 'Linarez',
                            controller: _apellidoController,
                            formateadores: Entradas.nombre,
                            autocompletar: const [AutofillHints.familyName],
                            validator: (v) =>
                                Validadores.nombrePropio(v, campo: 'apellido'),
                          ),
                        ),
                      ],
                    ),
                    espacio,

                    CampoTexto(
                      etiqueta: 'Correo institucional',
                      pista: 'usuario${Validadores.dominioInstitucional}',
                      controller: _correoController,
                      teclado: TextInputType.emailAddress,
                      formateadores: Entradas.correo,
                      autocompletar: const [AutofillHints.email],
                      validator: Validadores.correoInstitucional,
                    ),
                    espacio,

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 92,
                          child: CampoSeleccion(
                            etiqueta: 'Tipo',
                            opciones: Catalogos.prefijosCedula,
                            valor: _prefijoCedula,
                            pista: 'V',
                            alCambiar: (valor) =>
                                setState(() => _prefijoCedula = valor ?? 'V'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoTexto(
                            etiqueta: 'Cédula',
                            pista: '28123456',
                            controller: _cedulaController,
                            teclado: TextInputType.number,
                            formateadores: Entradas.digitos(9),
                            validator: (v) =>
                                Validadores.cedula(v, prefijo: _prefijoCedula),
                          ),
                        ),
                      ],
                    ),
                    espacio,

                    CampoTexto(
                      etiqueta: 'Carnet',
                      pista: '20231110245',
                      controller: _carnetController,
                      teclado: TextInputType.number,
                      formateadores: Entradas.digitos(Validadores.largoCarnet),
                      validator: Validadores.carnet,
                    ),
                    espacio,

                    CampoSeleccion(
                      etiqueta: 'Carrera',
                      opciones: Catalogos.carreras,
                      valor: _carrera,
                      pista: 'Selecciona tu carrera',
                      alCambiar: (valor) => setState(() => _carrera = valor),
                      validator: (v) => Validadores.opcion(
                        v,
                        Catalogos.carreras,
                        campo: 'tu carrera',
                      ),
                    ),
                    espacio,

                    CampoTexto(
                      etiqueta: 'Contraseña',
                      pista: 'Mínimo 8 caracteres',
                      controller: _passwordController,
                      esContrasena: true,
                      formateadores: Entradas.contrasena,
                      autocompletar: const [AutofillHints.newPassword],
                      // Redibuja los requisitos mientras se escribe.
                      alCambiar: (_) => setState(() {}),
                      validator: (v) => Validadores.contrasenaNueva(
                        v,
                        correo: _correoController.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RequisitosContrasena(contrasena: _passwordController.text),
                    espacio,

                    CampoTexto(
                      etiqueta: 'Confirmar contraseña',
                      pista: 'Repite la contraseña',
                      controller: _confirmPasswordController,
                      esContrasena: true,
                      formateadores: Entradas.contrasena,
                      accion: TextInputAction.done,
                      alEnviar: (_) => _registrarse(),
                      validator: (valor) => Validadores.confirmacion(
                        valor,
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColoresSaman.naranjaSuave,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'El registro es solo para estudiantes de la UNIMET. Las cuentas de entrenador las crea el administrador.',
                        style: TextStyle(
                          fontSize: 12,
                          color: orangeUnimet,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeUnimet,
                        foregroundColor: ColoresSaman.blanco,
                        disabledBackgroundColor: orangeUnimet.withValues(
                          alpha: 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      // Deshabilitado mientras se crea la cuenta, para no
                      // enviarla dos veces.
                      onPressed: _cargando ? null : _registrarse,
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: ColoresSaman.blanco,
                              ),
                            )
                          : const Text(
                              'Registrarme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(
                            color: ColoresSaman.textoSecundario,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              Rutas.login,
                            );
                          },
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: orangeUnimet,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
