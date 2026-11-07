/// Nombres de las rutas de navegación de la aplicación.
///
/// Las pantallas navegan con estos nombres, por ejemplo
/// `Navigator.pushNamed(context, Rutas.registro)`, en lugar de crear la
/// pantalla de destino, para no depender unas de otras. La relación entre
/// cada nombre y su pantalla está en main.dart, así core no depende de las
/// vistas.
abstract final class Rutas {
  static const String bienvenida = '/bienvenida';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const String perfil = '/perfil';
  static const String editarPerfil = '/perfil/editar';

  /// Pantalla de inicio de cada actor, a la que se llega al entrar.
  static const String inicio = '/inicio';

  // Entradas de cada módulo desde el inicio. Mientras un módulo no registre
  // su pantalla en main.dart, la ruta muestra «En construcción».
  static const String catalogo = '/estudiante/catalogo';
  static const String misDisciplinas = '/estudiante/mis-disciplinas';

  /// Detalle de una disciplina del catálogo; recibe el id del deporte.
  static const String detalleDisciplina = '/estudiante/disciplina';

  /// Confirmar la inscripción en una disciplina; recibe el Deporte elegido.
  static const String confirmarInscripcion = '/estudiante/inscripcion';
  static const String inscripcionConfirmada =
      '/estudiante/inscripcion/confirmada';
  static const String disciplinasEntrenador = '/entrenador';

  /// Nómina, asistencia e historial de una disciplina del entrenador;
  /// cada una recibe el Deporte elegido.
  static const String nominaEntrenador = '/entrenador/nomina';
  static const String asistenciaEntrenador = '/entrenador/asistencia';
  static const String historialEntrenador = '/entrenador/historial';

  static const String adminDeportes = '/admin/deportes';
  static const String adminUsuarios = '/admin/usuarios';

  /// Pantalla que se muestra al abrir la aplicación.
  static const String inicial = bienvenida;
}
