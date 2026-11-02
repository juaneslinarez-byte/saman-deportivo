import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/rutas.dart';
import '../../core/validadores.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../comun/campos_formulario.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final authViewModel = context.read<AuthViewModel>();
    final exito = await authViewModel.iniciarSesion(
      correo: Formatos.correo(_emailController.text),
      contrasena: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (exito) {
      // Al entrar se borra el historial: «atrás» no vuelve al formulario.
      Navigator.pushNamedAndRemoveUntil(context, Rutas.inicio, (ruta) => false);
    } else {
      // El ViewModel ya trae el mensaje en español (credenciales
      // incorrectas, cuenta deshabilitada, sin conexión...).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'No se pudo iniciar sesión.'),
          backgroundColor: ColoresSaman.rojo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeUnimet = ColoresSaman.naranja;

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
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
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Bienvenido a Samán Deportivo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ColoresSaman.azulOscuro,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    const Text(
                      'Ingresa tu cuenta institucional',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColoresSaman.textoSecundario,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    CampoTexto(
                      etiqueta: 'Correo institucional',
                      pista: 'usuario@correo.unimet.edu.ve',
                      controller: _emailController,
                      teclado: TextInputType.emailAddress,
                      formateadores: Entradas.correo,
                      autocompletar: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      validator: Validadores.correoInstitucional,
                    ),
                    const SizedBox(height: 14),

                    CampoTexto(
                      etiqueta: 'Contraseña',
                      pista: 'Tu contraseña',
                      controller: _passwordController,
                      esContrasena: true,
                      formateadores: Entradas.contrasena,
                      autocompletar: const [AutofillHints.password],
                      accion: TextInputAction.done,
                      // Enter inicia sesión, como en cualquier página.
                      alEnviar: (_) => _iniciarSesion(),
                      validator: Validadores.contrasenaIngreso,
                    ),
                    const SizedBox(height: 22),

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
                      onPressed: _cargando ? null : _iniciarSesion,
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
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Rutas.recuperar);
                        },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: orangeUnimet,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta? ',
                          style: TextStyle(
                            color: ColoresSaman.textoSecundario,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, Rutas.registro);
                          },
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: orangeUnimet,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          Rutas.bienvenida,
                          (ruta) => false,
                        ),
                        child: const Text(
                          '← Volver al inicio',
                          style: TextStyle(
                            color: ColoresSaman.textoDiscreto,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
