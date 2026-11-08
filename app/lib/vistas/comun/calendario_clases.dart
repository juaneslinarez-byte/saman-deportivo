import 'package:flutter/material.dart';

import '../../core/colores.dart';

/// Calendario mensual para elegir una clase, como en las apps de agenda:
/// solo se pueden tocar los días permitidos (por ejemplo, los días en que
/// tocó la sesión y que no están en el futuro), el día elegido se resalta y
/// los días que ya tienen algo registrado llevan un punto verde.
class CalendarioClases extends StatefulWidget {
  const CalendarioClases({
    super.key,
    required this.seleccionado,
    required this.habilitado,
    required this.alElegir,
    required this.primerDia,
    required this.hoy,
    this.marcados = const {},
    this.leyendaMarcados = 'Asistencia tomada',
    this.activo = true,
  });

  final DateTime? seleccionado;

  /// ¿Se puede elegir este día?
  final bool Function(DateTime dia) habilitado;
  final ValueChanged<DateTime> alElegir;

  /// No se puede retroceder antes del mes de este día.
  final DateTime primerDia;
  final DateTime hoy;

  /// Días con un punto verde, sin hora.
  final Set<DateTime> marcados;
  final String leyendaMarcados;

  /// Mientras se guarda no se puede cambiar de día.
  final bool activo;

  @override
  State<CalendarioClases> createState() => _CalendarioClasesState();
}

class _CalendarioClasesState extends State<CalendarioClases> {
  late DateTime _mes;

  /// Para animar el cambio de mes hacia la izquierda o la derecha.
  int _direccion = 1;

  static const _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  static const _dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final base = widget.seleccionado ?? widget.hoy;
    _mes = DateTime(base.year, base.month);
  }

  @override
  void didUpdateWidget(CalendarioClases anterior) {
    super.didUpdateWidget(anterior);
    // Si la clase elegida cambia desde fuera (otra sesión), se muestra su mes.
    final elegido = widget.seleccionado;
    if (elegido != null &&
        elegido != anterior.seleccionado &&
        (elegido.year != _mes.year || elegido.month != _mes.month)) {
      _mes = DateTime(elegido.year, elegido.month);
    }
  }

  DateTime get _primerMes =>
      DateTime(widget.primerDia.year, widget.primerDia.month);
  DateTime get _ultimoMes => DateTime(widget.hoy.year, widget.hoy.month);

  bool get _puedeAtras => _mes.isAfter(_primerMes);
  bool get _puedeAdelante => _mes.isBefore(_ultimoMes);

  void _cambiarMes(int delta) {
    setState(() {
      _direccion = delta;
      _mes = DateTime(_mes.year, _mes.month + delta);
    });
  }

  static bool _mismoDia(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // En pantalla ancha el calendario no se estira: queda del tamaño de
    // uno de bolsillo, centrado.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _contenido(),
      ),
    );
  }

  Widget _contenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: _puedeAtras ? () => _cambiarMes(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  '${_meses[_mes.month - 1]} ${_mes.year}',
                  key: ValueKey(_mes),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mes siguiente',
              onPressed: _puedeAdelante ? () => _cambiarMes(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final d in _dias)
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColoresSaman.textoTenue,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (hijo, animacion) {
            final entra = hijo.key == ValueKey(_mes);
            final desde = Offset(
              (entra ? 0.25 : -0.25) * _direccion.toDouble(),
              0,
            );
            return FadeTransition(
              opacity: animacion,
              child: SlideTransition(
                position: Tween(
                  begin: desde,
                  end: Offset.zero,
                ).animate(animacion),
                child: hijo,
              ),
            );
          },
          child: _Cuadricula(
            key: ValueKey(_mes),
            mes: _mes,
            hoy: widget.hoy,
            seleccionado: widget.seleccionado,
            habilitado: widget.habilitado,
            marcados: widget.marcados,
            mismoDia: _mismoDia,
            alElegir: widget.activo ? widget.alElegir : null,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            const _Leyenda(
              color: ColoresSaman.naranja,
              texto: 'Clase elegida',
              relleno: true,
            ),
            const _Leyenda(
              color: ColoresSaman.azulOscuro,
              texto: 'Día de clase',
            ),
            _Leyenda(
              color: ColoresSaman.verde,
              texto: widget.leyendaMarcados,
              punto: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Cuadricula extends StatelessWidget {
  const _Cuadricula({
    super.key,
    required this.mes,
    required this.hoy,
    required this.seleccionado,
    required this.habilitado,
    required this.marcados,
    required this.mismoDia,
    required this.alElegir,
  });

  final DateTime mes;
  final DateTime hoy;
  final DateTime? seleccionado;
  final bool Function(DateTime) habilitado;
  final Set<DateTime> marcados;
  final bool Function(DateTime?, DateTime) mismoDia;
  final ValueChanged<DateTime>? alElegir;

  @override
  Widget build(BuildContext context) {
    final diasDelMes = DateTime(mes.year, mes.month + 1, 0).day;
    // weekday: 1 = lunes. Celdas vacías antes del día 1.
    final vacias = DateTime(mes.year, mes.month).weekday - 1;
    final celdas = vacias + diasDelMes;
    final filas = (celdas / 7).ceil();

    return Column(
      children: [
        for (var fila = 0; fila < filas; fila++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: () {
                      final indice = fila * 7 + col - vacias + 1;
                      if (indice < 1 || indice > diasDelMes) {
                        return const SizedBox.shrink();
                      }
                      final dia = DateTime(mes.year, mes.month, indice);
                      return _Dia(
                        dia: dia,
                        habilitado: habilitado(dia),
                        elegido: mismoDia(seleccionado, dia),
                        esHoy: mismoDia(hoy, dia),
                        marcado: marcados.contains(dia),
                        alElegir: alElegir,
                      );
                    }(),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.dia,
    required this.habilitado,
    required this.elegido,
    required this.esHoy,
    required this.marcado,
    required this.alElegir,
  });

  final DateTime dia;
  final bool habilitado;
  final bool elegido;
  final bool esHoy;
  final bool marcado;
  final ValueChanged<DateTime>? alElegir;

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color texto;
    if (elegido) {
      fondo = ColoresSaman.naranja;
      texto = ColoresSaman.blanco;
    } else if (habilitado) {
      fondo = ColoresSaman.azulOscuro.withValues(alpha: 0.08);
      texto = ColoresSaman.azulOscuro;
    } else {
      fondo = Colors.transparent;
      texto = ColoresSaman.textoTenue.withValues(alpha: 0.6);
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: habilitado && alElegir != null ? () => alElegir!(dia) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(12),
              border: esHoy && !elegido
                  ? Border.all(color: ColoresSaman.naranja, width: 1.5)
                  : null,
              boxShadow: elegido
                  ? [
                      BoxShadow(
                        color: ColoresSaman.naranja.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: habilitado || elegido
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: texto,
                  ),
                ),
                if (marcado)
                  Positioned(
                    bottom: 5,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: elegido
                            ? ColoresSaman.blanco
                            : ColoresSaman.verde,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({
    required this.color,
    required this.texto,
    this.relleno = false,
    this.punto = false,
  });

  final Color color;
  final String texto;
  final bool relleno;
  final bool punto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: punto ? 8 : 14,
          height: punto ? 8 : 14,
          decoration: BoxDecoration(
            color: relleno || punto ? color : color.withValues(alpha: 0.08),
            shape: punto ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: punto ? null : BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            color: ColoresSaman.textoSecundario,
          ),
        ),
      ],
    );
  }
}
