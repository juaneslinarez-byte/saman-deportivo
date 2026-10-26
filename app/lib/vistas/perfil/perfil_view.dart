import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';

class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color orangeUnimet = ColoresSaman.naranja;
    const Color greyBg = ColoresSaman.gris;
    // El perfil llega en tiempo real desde Firestore a través del ViewModel.
    final perfilViewModel = context.watch<PerfilViewModel>();
    final persona = perfilViewModel.perfil;

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
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
                : _buildPerfil(
                    context: context,
                    persona: persona,
                    orangeUnimet: orangeUnimet,
                    greyBg: greyBg,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilContent({
    required BuildContext context,
    required String nombre,
    required String correo,
    required String carnet,
    required String carrera,
    required String rol,
    required Color orangeUnimet,
    required Color greyBg,
  }) {
    String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: ColoresSaman.naranjaSuave,
          child: Text(
            inicial,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: orangeUnimet,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          nombre,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColoresSaman.azulOscuro,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: orangeUnimet,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            rol,
            style: const TextStyle(
              color: ColoresSaman.blanco,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 28),

        _buildInfoTile(
          label: 'Correo Institucional',
          value: correo,
          icon: Icons.email_outlined,
          bg: greyBg,
        ),
        const SizedBox(height: 12),

        _buildInfoTile(
          label: 'Carnet / Identificación',
          value: carnet,
          icon: Icons.badge_outlined,
          bg: greyBg,
        ),
        const SizedBox(height: 12),

        _buildInfoTile(
          label: 'Carrera / Programa',
          value: carrera,
          icon: Icons.school_outlined,
          bg: greyBg,
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: ColoresSaman.rojo),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              await context.read<AuthViewModel>().cerrarSesion();
              if (!context.mounted) return;
              // Vuelve al inicio de sesión sin dejar el perfil en el historial.
              Navigator.pushNamedAndRemoveUntil(
                context,
                Rutas.login,
                (ruta) => false,
              );
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: ColoresSaman.rojo,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColoresSaman.textoSecundario, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ColoresSaman.textoSecundario,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColoresSaman.azulOscuro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mientras el perfil carga muestra un indicador; si no existe, un aviso.
  Widget _buildSinPerfil(PerfilViewModel perfilViewModel) {
    if (perfilViewModel.estado == PerfilEstado.cargando) {
      return const Center(
        child: CircularProgressIndicator(color: ColoresSaman.naranja),
      );
    }
    return Text(
      perfilViewModel.error ?? 'No se encontró tu perfil.',
      style: const TextStyle(color: ColoresSaman.textoSecundario),
      textAlign: TextAlign.center,
    );
  }

  /// Muestra los datos que corresponden a cada actor.
  Widget _buildPerfil({
    required BuildContext context,
    required Persona persona,
    required Color orangeUnimet,
    required Color greyBg,
  }) {
    final (rol, dato1, dato2) = switch (persona) {
      Estudiante e => ('Estudiante', e.carnet, e.carrera),
      Entrenador e => ('Entrenador', e.cedula, e.especialidad),
      Administrador a => ('Administrador', a.cedula, a.cargo),
      _ => ('Usuario', persona.cedula, ''),
    };
    return _buildPerfilContent(
      context: context,
      nombre: persona.nombreCompleto,
      correo: persona.correo,
      carnet: dato1,
      carrera: dato2,
      rol: rol,
      orangeUnimet: orangeUnimet,
      greyBg: greyBg,
    );
  }
}
