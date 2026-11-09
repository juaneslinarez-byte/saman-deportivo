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

  /// Próxima clase a partir de [ahora]: la sesión y el momento en que
  /// empieza. Es null si no hay sesiones.
  static ({Sesion sesion, DateTime inicio})? proximaClase(
    Iterable<Sesion> sesiones,
    DateTime ahora,
  ) {
    ({Sesion sesion, DateTime inicio})? proxima;
    for (final sesion in sesiones) {
      final partes = sesion.horaInicio.split(':');
      final h = int.tryParse(partes.first) ?? 0;
      final m = partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0;
      // weekday va de 1 (lunes) a 7; el índice de DiaSemana, de 0 a 6.
      final dias = (sesion.dia.index + 1 - ahora.weekday) % 7;
      var inicio = DateTime(ahora.year, ahora.month, ahora.day + dias, h, m);
      if (inicio.isBefore(ahora)) {
        inicio = DateTime(inicio.year, inicio.month, inicio.day + 7, h, m);
      }
      if (proxima == null || inicio.isBefore(proxima.inicio)) {
        proxima = (sesion: sesion, inicio: inicio);
      }
    }
    return proxima;
  }

  /// «Hoy, 4:00 PM», «Mañana, 4:00 PM» o «Jueves, 4:00 PM».
  static String cuando(DateTime inicio, DateTime ahora) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(inicio.year, inicio.month, inicio.day);
    final diferencia = dia.difference(hoy).inDays;
    final hora = hora12(
      '${inicio.hour.toString().padLeft(2, '0')}:'
      '${inicio.minute.toString().padLeft(2, '0')}',
    );
    final nombre = switch (diferencia) {
      0 => 'Hoy',
      1 => 'Mañana',
      _ => () {
        final n = nombreDia(diaDe(inicio));
        return n[0].toUpperCase() + n.substring(1);
      }(),
    };
    return '$nombre, $hora';
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
