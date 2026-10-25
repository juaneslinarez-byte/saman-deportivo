import 'package:flutter/material.dart';
import 'registro_view.dart';
import 'recuperar_password_vista.dart'; // Import corregido con 'vista'
import '../perfil/perfil_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Rol activo: 'Estudiante' o 'Entrenador'
  String _rolSeleccionado = 'Estudiante';
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _cargando = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PerfilView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeUnimet = Color(0xFFF37021);
    const Color greyBg = Color(0xFFF1F2F4);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), // Sin deprecación
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
                  // Título principal
                  const Text(
                    'Bienvenido a Samán Deportivo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Subtítulo dinámico según rol
                  Text(
                    _rolSeleccionado == 'Estudiante'
                        ? 'Ingresa tu cuenta institucional'
                        : 'Acceso para entrenadores',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Selector de Rol (Estudiante / Entrenador)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingresar como',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: greyBg,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRoleTab('Estudiante', orangeUnimet),
                            ),
                            Expanded(
                              child: _buildRoleTab('Entrenador', orangeUnimet),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Campo Correo
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Correo institucional (@unimet.edu.ve)',
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                      filled: true,
                      fillColor: greyBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Ingresa tu correo' : null,
                  ),
                  const SizedBox(height: 12),

                  // Campo Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                      filled: true,
                      fillColor: greyBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Ingresa tu contraseña' : null,
                  ),
                  const SizedBox(height: 20),

                  // Botón Iniciar Sesión
                  _cargando
                      ? const Center(child: CircularProgressIndicator(color: orangeUnimet))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeUnimet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _iniciarSesion,
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Olvidaste contraseña
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecuperarPasswordView(),
                          ),
                        );
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

                  // Enlace a Registro (Solo para Estudiante)
                  if (_rolSeleccionado == 'Estudiante') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta? ',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegistroView(),
                              ),
                            );
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
                  ] else ...[
                    // Aviso para Entrenador
                    const Text(
                      'Las cuentas de entrenador las crea el administrador',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Volver al inicio
                  Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        '← Volver al inicio',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
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
    );
  }

  Widget _buildRoleTab(String rol, Color activeColor) {
    final bool isSelected = _rolSeleccionado == rol;
    return GestureDetector(
      onTap: () {
        setState(() {
          _rolSeleccionado = rol;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          rol,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}