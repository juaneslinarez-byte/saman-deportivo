import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';

/// Una entrada del inicio: lleva a la pantalla principal de un módulo.
class SeccionInicio {
  const SeccionInicio({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.ruta,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final String ruta;
}

/// Pantalla a la que llega cada actor al entrar: muestra solo las secciones
/// que le corresponden, según el actor de su perfil.
class InicioView extends StatelessWidget {
  const InicioView({super.key});

  static const _miPerfil = SeccionInicio(
    titulo: 'Mi perfil',
    descripcion: 'Tus datos y la edición del perfil',
    icono: Icons.person_outline,
    ruta: Rutas.perfil,
  );

  /// Secciones de cada actor. Cada módulo se abre por su ruta, así el inicio
  /// no depende de las pantallas de los demás.
  static List<SeccionInicio> seccionesPara(Persona persona) =>
      switch (persona) {
        Estudiante() => const [
          SeccionInicio(
            titulo: 'Catálogo de disciplinas',
            descripcion: 'Busca por cupos, días y horarios',
            icono: Icons.sports_soccer_outlined,
            ruta: Rutas.catalogo,
          ),
          SeccionInicio(
            titulo: 'Mis disciplinas',
            descripcion: 'Tus inscripciones y tu asistencia',
            icono: Icons.event_available_outlined,
            ruta: Rutas.misDisciplinas,
          ),
          SeccionInicio(
            titulo: 'Mi solvencia',
            descripcion: 'Paga la cuota y revisa tus pagos',
            icono: Icons.payments_outlined,
            ruta: Rutas.solvencia,
          ),
          _miPerfil,
        ],
        Entrenador() => const [
          SeccionInicio(
            titulo: 'Mis disciplinas',
            descripcion: 'Nómina, asistencia e historial',
            icono: Icons.groups_outlined,
            ruta: Rutas.disciplinasEntrenador,
          ),
          _miPerfil,
        ],
        Administrador() => const [
          SeccionInicio(
            titulo: 'Deportes',
            descripcion: 'Alta, entrenadores, sesiones y cupos',
            icono: Icons.sports_outlined,
            ruta: Rutas.adminDeportes,
          ),
          SeccionInicio(
            titulo: 'Usuarios',
            descripcion: 'Habilitar, solvencia y entrenadores',
            icono: Icons.manage_accounts_outlined,
            ruta: Rutas.adminUsuarios,
          ),
          SeccionInicio(
            titulo: 'Pagos de solvencia',
            descripcion: 'Aprueba o rechaza los pagos en revisión',
            icono: Icons.request_quote_outlined,
            ruta: Rutas.adminPagos,
          ),
          _miPerfil,
        ],
        _ => const [_miPerfil],
      };

  static String _nombreDelActor(Persona persona) => switch (persona) {
    Estudiante() => 'Estudiante',
    Entrenador() => 'Entrenador',
    Administrador() => 'Administrador',
    _ => 'Usuario',
  };

  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AuthViewModel>().cerrarSesion();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (ruta) => false);
  }

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final persona = perfilViewModel.perfil;

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Samán Deportivo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: persona == null
          ? _SinPerfil(
              perfilViewModel: perfilViewModel,
              conSesion: context.watch<AuthViewModel>().estaAutenticado,
            )
          : _Contenido(
              persona: persona,
              actor: _nombreDelActor(persona),
              secciones: seccionesPara(persona),
            ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.persona,
    required this.actor,
    required this.secciones,
  });

  final Persona persona;
  final String actor;
  final List<SeccionInicio> secciones;

  @override
  Widget build(BuildContext context) {
    // Sin solvencia el estudiante no puede inscribirse (RF-SIS-02): se le
    // avisa desde el inicio, antes de que lo intente.
    final sinSolvencia = switch (persona) {
      Estudiante(:final solvente) => !solvente,
      _ => false,
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${persona.nombre}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ColoresSaman.naranja,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actor,
                  style: const TextStyle(
                    color: ColoresSaman.blanco,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (sinSolvencia) ...[
                const SizedBox(height: 20),
                const _AvisoSolvencia(),
              ],
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, restricciones) {
                  // Tres columnas en pantalla ancha, una en el teléfono.
                  const espacio = 16.0;
                  final columnas = restricciones.maxWidth >= 640 ? 3 : 1;
                  final ancho =
                      (restricciones.maxWidth - espacio * (columnas - 1)) /
                      columnas;
                  return Wrap(
                    spacing: espacio,
                    runSpacing: espacio,
                    children: [
                      for (final seccion in secciones)
                        SizedBox(
                          width: ancho,
                          child: _TarjetaSeccion(seccion: seccion),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaSeccion extends StatelessWidget {
  const _TarjetaSeccion({required this.seccion});

  final SeccionInicio seccion;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresSaman.blanco,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, seccion.ruta),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColoresSaman.gris),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ColoresSaman.naranjaSuave,
                child: Icon(seccion.icono, color: ColoresSaman.naranja),
              ),
              const SizedBox(height: 14),
              Text(
                seccion.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                seccion.descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoSolvencia extends StatelessWidget {
  const _AvisoSolvencia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresSaman.naranjaSuave,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: ColoresSaman.naranja),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Aún no estás solvente. Paga la cuota del trimestre y podrás '
              'inscribirte cuando el administrador confirme tu pago.',
              style: TextStyle(color: ColoresSaman.azulOscuro, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ColoresSaman.naranja),
            onPressed: () => Navigator.pushNamed(context, Rutas.solvencia),
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }
}

/// Mientras el perfil carga muestra un indicador; si no hay perfil, un aviso
/// con el camino de vuelta al inicio de sesión.
class _SinPerfil extends StatelessWidget {
  const _SinPerfil({required this.perfilViewModel, required this.conSesion});

  final PerfilViewModel perfilViewModel;

  /// Justo al entrar, el perfil empieza a cargarse un instante después.
  final bool conSesion;

  @override
  Widget build(BuildContext context) {
    final estado = perfilViewModel.estado;
    if (estado == PerfilEstado.cargando ||
        (estado == PerfilEstado.inicial && conSesion)) {
      return const Center(
        child: CircularProgressIndicator(color: ColoresSaman.naranja),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              perfilViewModel.error ?? 'No se encontró tu perfil.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresSaman.textoSecundario),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Rutas.login,
                (ruta) => false,
              ),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
