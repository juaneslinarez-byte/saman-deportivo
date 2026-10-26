/// Nombres de las rutas de navegación de la aplicación.
///
/// Las pantallas navegan con estos nombres, por ejemplo
/// `Navigator.pushNamed(context, Rutas.registro)`, en lugar de crear la
/// pantalla de destino, para no depender unas de otras. La relación entre
/// cada nombre y su pantalla está en main.dart, así core no depende de las
/// vistas.
abstract final class Rutas {
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const String perfil = '/perfil';

  /// Pantalla que se muestra al abrir la aplicación.
  static const String inicial = login;
}
