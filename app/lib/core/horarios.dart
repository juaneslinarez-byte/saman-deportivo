import '../modelos/modelos.dart';

/// Textos del horario semanal de un deporte, como se ven en el prototipo:
/// «Lun y Mié · 4:00 PM - 6:00 PM».
abstract final class Horarios {
  /// Una línea por cada franja horaria, con los días que la comparten.
  ///
  /// Con [abreviado] los días van como «Lun y Mié»; si no, como «Lunes y
  /// miércoles». Si no hay sesiones devuelve una lista vacía.
  static List<String> resumen(List<Sesion> sesiones, {bool abreviado = true}) {
    final ordenadas = [...sesiones]
      ..sort((a, b) {
        final porDia = a.dia.index.compareTo(b.dia.index);
        return porDia != 0 ? porDia : a.horaInicio.compareTo(b.horaInicio);
      });

    // Los días con la misma hora de inicio y de fin comparten una línea.
    final franjas = <String, List<DiaSemana>>{};
    for (final sesion in ordenadas) {
      final inicio = hora12(sesion.horaInicio);
      final fin = hora12(sesion.horaFin);
      franjas.putIfAbsent('$inicio - $fin', () => []).add(sesion.dia);
    }

    return [
      for (final franja in franjas.entries)
        '${_unirDias(franja.value, abreviado)} · ${franja.key}',
    ];
  }

  /// «16:30» → «4:30 PM». Si el texto no tiene el formato HH:MM, lo deja igual.
  static String hora12(String hora) {
    final partes = hora.split(':');
    if (partes.length != 2) return hora;

    final h = int.tryParse(partes[0]);
    final minutos = partes[1];
    if (h == null || h < 0 || h > 23 || minutos.length != 2) return hora;

    final sufijo = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$minutos $sufijo';
  }

  /// Nombre del día: «lunes» o, con [abreviado], «Lun».
  static String nombreDia(DiaSemana dia, {bool abreviado = false}) =>
      _nombre(dia, abreviado);

  /// Día de la semana de una fecha: DateTime cuenta del 1 (lunes) al 7.
  static DiaSemana diaDe(DateTime fecha) => DiaSemana.values[fecha.weekday - 1];

  /// «Lun», «Lun y Mié», «Lun, Mié y Vie».
  static String _unirDias(List<DiaSemana> dias, bool abreviado) {
    final nombres = [for (final dia in dias) _nombre(dia, abreviado)];

    final String unido;
    if (nombres.length == 1) {
      unido = nombres.first;
    } else {
      final inicio = nombres.sublist(0, nombres.length - 1).join(', ');
      unido = '$inicio y ${nombres.last}';
    }

    // Abreviados ya van en mayúscula; los nombres completos, solo el primero.
    final mayuscula = '${unido[0].toUpperCase()}${unido.substring(1)}';
    return abreviado ? unido : mayuscula;
  }

  static String _nombre(DiaSemana dia, bool abreviado) => switch (dia) {
    DiaSemana.lunes => abreviado ? 'Lun' : 'lunes',
    DiaSemana.martes => abreviado ? 'Mar' : 'martes',
    DiaSemana.miercoles => abreviado ? 'Mié' : 'miércoles',
    DiaSemana.jueves => abreviado ? 'Jue' : 'jueves',
    DiaSemana.viernes => abreviado ? 'Vie' : 'viernes',
    DiaSemana.sabado => abreviado ? 'Sáb' : 'sábado',
    DiaSemana.domingo => abreviado ? 'Dom' : 'domingo',
  };
}
