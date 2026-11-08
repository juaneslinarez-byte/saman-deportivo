/// Mensaje en español para mostrar al usuario a partir de un error.
///
/// Las validaciones de los ViewModels lanzan `Exception('mensaje')` con un
/// texto pensado para el usuario, y ese se muestra tal cual. Cualquier otro
/// error (de Firebase, de conexión...) se cambia por un mensaje general,
/// para no mostrar textos técnicos.
String mensajeDeError(
  Object error, {
  String porDefecto =
      'No se pudo completar la acción. Revisa tu conexión e inténtalo de '
      'nuevo.',
}) {
  const prefijo = 'Exception: ';
  final texto = error.toString();
  if (error is Exception && texto.startsWith(prefijo)) {
    return texto.substring(prefijo.length);
  }
  return porDefecto;
}
