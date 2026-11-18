import 'horarios.dart';
import 'solvencia.dart';

/// Formatos para mostrar los eventos y sus reservas.
abstract final class FormatoEvento {
  static const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// «sáb 22 nov · 4:00 PM».
  static String fechaHora(DateTime fecha) => '${dia(fecha)} · ${hora(fecha)}';

  /// «sáb 22 nov».
  static String dia(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]} ${fecha.day} ${_meses[fecha.month - 1]}';

  /// «4:00 PM».
  static String hora(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return Horarios.hora12('${dos(fecha.hour)}:${dos(fecha.minute)}');
  }

  /// «30 min», «1 h», «1 h 30 min».
  static String duracion(int minutos) {
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    if (horas == 0) return '$resto min';
    if (resto == 0) return '$horas h';
    return '$horas h $resto min';
  }

  /// «Gratis» o «$10,00».
  static String precio(double monto) =>
      monto <= 0 ? 'Gratis' : Solvencia.formatoMonto(monto);

  /// Convierte el texto del campo de precio («7,50») en número.
  static double leerMonto(String texto) =>
      double.parse(texto.trim().replaceAll(',', '.'));

  /// «1 persona», «3 personas».
  static String personas(int n) => n == 1 ? '1 persona' : '$n personas';
}
