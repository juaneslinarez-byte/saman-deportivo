import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/validadores.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../comun/campos_formulario.dart';

class RecuperarPasswordView extends StatefulWidget {
  const RecuperarPasswordView({super.key});

  @override
  State<RecuperarPasswordView> createState() => _RecuperarPasswordViewState();
}

class _RecuperarPasswordViewState extends State<RecuperarPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  bool _cargando = false;

  /// Correo al que se envió el enlace; mientras es null se muestra el
  /// formulario.
  String? _enviadoA;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _solicitarRestablecimiento() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final authViewModel = context.read<AuthViewModel>();
    final correo = Formatos.correo(_correoController.text);
    final exito = await authViewModel.recuperarPassword(correo);

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (exito) _enviadoA = correo;
    });

    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authViewModel.error ??
                'No se pudo enviar el correo de recuperación.',
          ),
          backgroundColor: ColoresSaman.rojo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
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
            child: _enviadoA == null ? _formulario() : _confirmacion(),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: ColoresSaman.naranjaSuave,
            child: Icon(
              Icons.lock_reset,
              size: 34,
              color: ColoresSaman.naranja,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Restablece tu contraseña',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Escribe tu correo institucional y te enviaremos un enlace para '
            'crear una contraseña nueva.',
            style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CampoTexto(
            etiqueta: 'Correo institucional',
            pista: 'usuario${Validadores.dominioInstitucional}',
            controller: _correoController,
            teclado: TextInputType.emailAddress,
            formateadores: Entradas.correo,
            autocompletar: const [AutofillHints.email],
            accion: TextInputAction.send,
            alEnviar: (_) => _solicitarRestablecimiento(),
            validator: Validadores.correoInstitucional,
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.naranja,
              foregroundColor: ColoresSaman.blanco,
              disabledBackgroundColor: ColoresSaman.naranja.withValues(
                alpha: 0.6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _cargando ? null : _solicitarRestablecimiento,
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
                    'Enviar enlace',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  /// Por seguridad no se dice si el correo tiene cuenta: así nadie puede
  /// averiguar qué correos están registrados.
  Widget _confirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: ColoresSaman.naranjaSuave,
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 34,
            color: ColoresSaman.naranja,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Revisa tu correo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColoresSaman.azulOscuro,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Si $_enviadoA tiene una cuenta en Samán Deportivo, te llegará un '
          'enlace para crear una contraseña nueva. Revisa también la carpeta '
          'de correo no deseado.',
          style: const TextStyle(
            color: ColoresSaman.textoSecundario,
            fontSize: 13,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ColoresSaman.naranja,
            side: const BorderSide(color: ColoresSaman.naranja),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Volver a iniciar sesión',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
