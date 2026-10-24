/// Convierte una fecha leída de la base de datos en un [DateTime].
///
/// Acepta los formatos que pueden llegar desde un repositorio: un [DateTime],
/// un texto ISO 8601, milisegundos desde 1970 o un Timestamp de Firestore.
/// El Timestamp se convierte con su método toDate() para que los modelos no
/// dependan del paquete de Firebase.
DateTime leerFecha(Object? valor) {
  if (valor is DateTime) return valor;
  if (valor is String) return DateTime.parse(valor);
  if (valor is int) return DateTime.fromMillisecondsSinceEpoch(valor);
  if (valor != null) {
    try {
      return (valor as dynamic).toDate() as DateTime;
    } on NoSuchMethodError {
      // Se reporta abajo como formato no válido.
    }
  }
  throw FormatException('Fecha no válida: $valor');
}

/// Busca un valor de [valores] por su nombre y lanza un error claro si no existe.
T leerEnum<T extends Enum>(List<T> valores, Object? nombre, String campo) {
  for (final valor in valores) {
    if (valor.name == nombre) return valor;
  }
  throw FormatException('Valor no válido para "$campo": $nombre');
}
