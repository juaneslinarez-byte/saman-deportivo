import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_view.dart';

class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color orangeUnimet = Color(0xFFF37021);
    const Color greyBg = Color(0xFFF1F2F4);

    User? usuarioActual = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: usuarioActual == null
                ? _buildPerfilDemo(
                    context: context,
                    orangeUnimet: orangeUnimet,
                    greyBg: greyBg,
                  )
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(usuarioActual.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: CircularProgressIndicator(color: orangeUnimet),
                          ),
                        );
                      }

                      Map<String, dynamic> datos = snapshot.hasData && snapshot.data!.exists
                          ? snapshot.data!.data() as Map<String, dynamic>
                          : {};

                      String rol = datos['rol'] ?? 'Estudiante';
                      String nombre = datos['nombre'] ?? (usuarioActual.displayName ?? 'Usuario');
                      String apellido = datos['apellido'] ?? '';
                      String correo = datos['correo'] ?? (usuarioActual.email ?? 'usuario@correo.unimet.edu.ve');
                      String carnet = datos['carnet'] ?? datos['cedula'] ?? 'Sin registrar';
                      String carrera = datos['carrera'] ?? 'Estudiante UNIMET';

                      return _buildPerfilContent(
                        context: context,
                        nombre: '$nombre $apellido'.trim(),
                        correo: correo,
                        carnet: carnet,
                        carrera: carrera,
                        rol: rol,
                        orangeUnimet: orangeUnimet,
                        greyBg: greyBg,
                      );
                    },
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
        // Avatar circular con inicial
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFFFF3EC),
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

        // Nombre Completo
        Text(
          nombre,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Badge de Rol
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: orangeUnimet,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            rol,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Datos del Usuario
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

        // Botón Cerrar Sesión
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}

              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Color(0xFFEF4444),
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
          Icon(icon, color: const Color(0xFF64748B), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
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

  // Vista de prueba cuando aún no hay sesión activa
  Widget _buildPerfilDemo({
    required BuildContext context,
    required Color orangeUnimet,
    required Color greyBg,
  }) {
    return _buildPerfilContent(
      context: context,
      nombre: 'Juan Linarez',
      correo: 'juan.linarez@correo.unimet.edu.ve',
      carnet: '20231110245',
      carrera: 'Ing. de Sistemas',
      rol: 'Estudiante',
      orangeUnimet: orangeUnimet,
      greyBg: greyBg,
    );
  }
}