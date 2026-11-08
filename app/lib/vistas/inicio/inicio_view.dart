import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../comun/disenio.dart';

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
            titulo: 'Mi resumen',
            descripcion: 'Próxima clase, asistencia y pendientes',
            icono: Icons.insights_outlined,
            ruta: Rutas.panelEstudiante,
          ),
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
            titulo: 'Mi resumen',
            descripcion: 'Inscritos, asistencia y próxima clase',
            icono: Icons.insights_outlined,
            ruta: Rutas.panelEntrenador,
          ),
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
            titulo: 'Panel resumen',
            descripcion: 'Cifras del club y lo que requiere atención',
            icono: Icons.insights_outlined,
            ruta: Rutas.adminPanel,
          ),
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
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/imagenes/logo_saman.jpg',
                height: 32,
                width: 32,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('Samán Deportivo', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Cualquier actor puede volver a la página principal (landing).
          // En el teléfono queda solo el ícono para no apretar la barra.
          if (MediaQuery.sizeOf(context).width >= 600)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: ColoresSaman.blanco),
              onPressed: () => Navigator.pushNamed(context, Rutas.bienvenida),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Página principal'),
            )
          else
            IconButton(
              tooltip: 'Página principal',
              icon: const Icon(Icons.home_outlined),
              onPressed: () => Navigator.pushNamed(context, Rutas.bienvenida),
            ),
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

  static const _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// «Domingo, 8 de noviembre».
  static String _hoy() {
    final ahora = DateTime.now();
    return '${_dias[ahora.weekday - 1]}, ${ahora.day} de '
        '${_meses[ahora.month - 1]}';
  }

  /// Frase de bienvenida de cada actor, debajo del saludo.
  static String _frase(Persona persona) => switch (persona) {
    Estudiante() => '¿Qué entrenamos hoy?',
    Entrenador() => 'Tus grupos te esperan.',
    Administrador() => 'Así va el club hoy.',
    _ => 'Bienvenido.',
  };

  static IconData _iconoActor(Persona persona) => switch (persona) {
    Estudiante() => Icons.school_outlined,
    Entrenador() => Icons.sports_outlined,
    Administrador() => Icons.admin_panel_settings_outlined,
    _ => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    // Sin solvencia el estudiante no puede inscribirse (RF-SIS-02): se le
    // avisa desde el inicio, antes de que lo intente.
    final sinSolvencia = switch (persona) {
      Estudiante(:final solvente) => !solvente,
      _ => false,
    };

    return SingleChildScrollView(
      child: Column(
        children: [
          PortadaDegradado(
            anchoMaximo: 900,
            espacioInferior: 80,
            encima: Row(
              children: [
                AvatarIniciales(nombre: persona.nombreCompleto, tamano: 48),
                const SizedBox(width: 12),
                PildoraClara(texto: actor, icono: _iconoActor(persona)),
              ],
            ),
            titulo: 'Hola, ${persona.nombre}',
            subtitulo: '${_hoy()} · ${_frase(persona)}',
          ),
          // Las tarjetas suben y se montan sobre el borde de la portada.
          Transform.translate(
            offset: const Offset(0, -56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sinSolvencia) ...[
                        const Aparecer(child: _AvisoSolvencia()),
                        const SizedBox(height: 16),
                      ],
                      LayoutBuilder(
                        builder: (context, restricciones) {
                          // Tres columnas en pantalla ancha, dos en tableta
                          // y una en el teléfono.
                          const espacio = 16.0;
                          final columnas = restricciones.maxWidth >= 760
                              ? 3
                              : restricciones.maxWidth >= 480
                              ? 2
                              : 1;
                          final ancho =
                              (restricciones.maxWidth -
                                  espacio * (columnas - 1)) /
                              columnas;
                          return Wrap(
                            spacing: espacio,
                            runSpacing: espacio,
                            children: [
                              for (final (i, seccion) in secciones.indexed)
                                SizedBox(
                                  width: ancho,
                                  child: Aparecer(
                                    retraso: Aparecer.escalonado(
                                      i + 1,
                                      pasoMs: 70,
                                    ),
                                    child: _TarjetaSeccion(
                                      seccion: seccion,
                                      color:
                                          ColoresSaman.acentos[i %
                                              ColoresSaman.acentos.length],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaSeccion extends StatelessWidget {
  const _TarjetaSeccion({required this.seccion, required this.color});

  final SeccionInicio seccion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      alTocar: () => Navigator.pushNamed(context, seccion.ruta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconoAcento(icono: seccion.icono, color: color),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            seccion.titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            seccion.descripcion,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: ColoresSaman.textoSecundario,
            ),
          ),
        ],
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
        gradient: LinearGradient(
          colors: [
            ColoresSaman.ambar.withValues(alpha: 0.95),
            ColoresSaman.naranja,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ColoresSaman.naranja.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: ColoresSaman.blanco),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Aún no estás solvente. Paga la cuota del trimestre y podrás '
              'inscribirte cuando el administrador confirme tu pago.',
              style: TextStyle(
                color: ColoresSaman.blanco,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresSaman.blanco,
              foregroundColor: ColoresSaman.naranja,
              elevation: 0,
            ),
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
