import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../core/validadores.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _carnetController.dispose();
    _carreraController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final authViewModel = context.read<AuthViewModel>();
    // Crea la cuenta en Authentication y el perfil de estudiante en
    // Firestore (usuarios/{uid}).
    final exito = await authViewModel.registrar(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      cedula: _cedulaController.text.trim(),
      carnet: _carnetController.text.trim(),
      carrera: _carreraController.text.trim(),
      correo: _correoController.text.trim(),
      contrasena: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (exito) {
      // Al entrar se borra el historial: «atrás» no vuelve al formulario.
      Navigator.pushNamedAndRemoveUntil(context, Rutas.perfil, (ruta) => false);
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
    const Color greyBg = ColoresSaman.gris;

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
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

                  // Nombre y Apellido (2 Columnas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledInput(
                          label: 'Nombre',
                          hint: 'Juan',
                          controller: _nombreController,
                          bg: greyBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledInput(
                          label: 'Apellido',
                          hint: 'Linarez',
                          controller: _apellidoController,
                          bg: greyBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Correo Institucional
                  _buildLabeledInput(
                    label: 'Correo institucional',
                    hint: 'usuario@correo.unimet.edu.ve',
                    controller: _correoController,
                    bg: greyBg,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validadores.correoInstitucional,
                  ),
                  const SizedBox(height: 14),

                  // Cédula: la pide el perfil del estudiante.
                  _buildLabeledInput(
                    label: 'Cédula',
                    hint: '28123456',
                    controller: _cedulaController,
                    bg: greyBg,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  // Carnet y Carrera (2 Columnas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledInput(
                          label: 'Carnet',
                          hint: '20231110245',
                          controller: _carnetController,
                          bg: greyBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledInput(
                          label: 'Carrera',
                          hint: 'Ing. de Sistemas',
                          controller: _carreraController,
                          bg: greyBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Contraseña y Confirmar contraseña (2 Columnas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledInput(
                          label: 'Contraseña',
                          hint: '••••••••',
                          controller: _passwordController,
                          bg: greyBg,
                          obscureText: true,
                          validator: Validadores.contrasena,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledInput(
                          label: 'Confirmar contraseña',
                          hint: '••••••••',
                          controller: _confirmPasswordController,
                          bg: greyBg,
                          obscureText: true,
                          validator: (valor) => Validadores.confirmacion(
                            valor,
                            _passwordController.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Banner Naranja Informativo
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

                  // Botón Registrarme
                  _cargando
                      ? const Center(
                          child: CircularProgressIndicator(color: orangeUnimet),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeUnimet,
                            foregroundColor: ColoresSaman.blanco,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _registrarse,
                          child: const Text(
                            'Registrarme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // Enlace a Iniciar sesión
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
                          Navigator.pushReplacementNamed(context, Rutas.login);
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
    );
  }

  Widget _buildLabeledInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color bg,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ColoresSaman.textoCampo,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: ColoresSaman.textoTenue,
              fontSize: 13,
            ),
            filled: true,
            fillColor: bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator ?? Validadores.requerido,
        ),
      ],
    );
  }
}
