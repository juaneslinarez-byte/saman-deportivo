import 'package:flutter/material.dart';

class RecuperarPasswordView extends StatefulWidget {
  const RecuperarPasswordView({super.key});

  @override
  State<RecuperarPasswordView> createState() => _RecuperarPasswordViewState();
}

class _RecuperarPasswordViewState extends State<RecuperarPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _solicitarRestablecimiento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    try {
      // ----------------------------------------------------------------------
      // TODO (BACKEND): Conectar aquí con Firebase Auth / AuthRepository
      // Ejemplo:
      // await FirebaseAuth.instance.sendPasswordResetEmail(
      //   email: _correoController.text.trim(),
      // );
      // ----------------------------------------------------------------------

      // Simulación de tiempo de respuesta para pruebas de UI
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado un enlace de recuperación a tu correo.'),
          backgroundColor: Colors.green,
        ),
      );

      // Regresa a la pantalla de Login
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Restablece tu contraseña',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Ingresa tu correo institucional. Te enviaremos un enlace para que puedas crear una nueva contraseña.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Institucional',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _solicitarRestablecimiento,
                        child: const Text(
                          'ENVIAR CORREO DE RECUPERACIÓN',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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