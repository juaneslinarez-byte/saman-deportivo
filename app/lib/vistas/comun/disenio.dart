/// Piezas del diseño de la app: animaciones de entrada, tarjetas que
/// reaccionan al pasar el ratón, avatares con iniciales, insignias de
/// estado y la portada en degradado de cada pantalla.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/colores.dart';

/// Hace aparecer a su hijo subiendo y desvaneciéndose, después de
/// [retraso]. En una lista, un retraso que crece con el índice da el efecto
/// escalonado de las apps grandes.
class Aparecer extends StatefulWidget {
  const Aparecer({
    super.key,
    required this.child,
    this.retraso = Duration.zero,
    this.duracion = const Duration(milliseconds: 450),
    this.desplazamiento = 24,
  });

  /// Retraso escalonado para el elemento [indice] de una lista, con un tope
  /// para que las listas largas no tarden en aparecer.
  static Duration escalonado(int indice, {int pasoMs = 60}) =>
      Duration(milliseconds: math.min(indice, 8) * pasoMs);

  final Widget child;
  final Duration retraso;
  final Duration duracion;
  final double desplazamiento;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control;
  late final Animation<double> _avance;

  @override
  void initState() {
    super.initState();
    final total = widget.retraso + widget.duracion;
    _control = AnimationController(vsync: this, duration: total);
    // El retraso es la primera parte de la animación: así no quedan
    // temporizadores pendientes si la pantalla se cierra antes.
    final inicio = total.inMilliseconds == 0
        ? 0.0
        : widget.retraso.inMilliseconds / total.inMilliseconds;
    _avance = CurvedAnimation(
      parent: _control,
      curve: Interval(inicio, 1, curve: Curves.easeOutCubic),
    );
    _control.forward();
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _avance,
      builder: (context, hijo) => Opacity(
        opacity: _avance.value,
        child: Transform.translate(
          offset: Offset(0, widget.desplazamiento * (1 - _avance.value)),
          child: hijo,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Tarjeta blanca que se eleva al pasar el ratón y se hunde un poco al
/// tocarla. Si no tiene [alTocar], es una tarjeta normal.
class TarjetaInteractiva extends StatefulWidget {
  const TarjetaInteractiva({
    super.key,
    required this.child,
    this.alTocar,
    this.relleno = const EdgeInsets.all(20),
    this.radio = 20,
    this.colorBorde,
  });

  final Widget child;
  final VoidCallback? alTocar;
  final EdgeInsetsGeometry relleno;
  final double radio;
  final Color? colorBorde;

  @override
  State<TarjetaInteractiva> createState() => _TarjetaInteractivaState();
}

class _TarjetaInteractivaState extends State<TarjetaInteractiva> {
  bool _encima = false;
  bool _presionada = false;

  @override
  Widget build(BuildContext context) {
    final activa = widget.alTocar != null;
    final elevada = activa && _encima;
    return MouseRegion(
      cursor: activa ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() {
        _encima = false;
        _presionada = false;
      }),
      child: GestureDetector(
        onTapDown: activa ? (_) => setState(() => _presionada = true) : null,
        onTapCancel: activa ? () => setState(() => _presionada = false) : null,
        onTapUp: activa ? (_) => setState(() => _presionada = false) : null,
        onTap: widget.alTocar,
        child: AnimatedScale(
          scale: _presionada ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, elevada ? -4 : 0, 0),
            padding: widget.relleno,
            decoration: BoxDecoration(
              color: ColoresSaman.blanco,
              borderRadius: BorderRadius.circular(widget.radio),
              border: Border.all(
                color:
                    widget.colorBorde ??
                    (elevada
                        ? ColoresSaman.indigo.withValues(alpha: 0.25)
                        : ColoresSaman.borde),
              ),
              boxShadow: [
                BoxShadow(
                  color: ColoresSaman.azulNoche.withValues(
                    alpha: elevada ? 0.12 : 0.05,
                  ),
                  blurRadius: elevada ? 28 : 14,
                  offset: Offset(0, elevada ? 14 : 6),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Círculo con las iniciales y un color fijo por persona.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.nombre, this.tamano = 44});

  final String nombre;
  final double tamano;

  /// El mismo nombre siempre da el mismo color.
  static Color colorDe(String nombre) {
    var suma = 0;
    for (final c in nombre.codeUnits) {
      suma = (suma * 31 + c) & 0x7fffffff;
    }
    return ColoresSaman.acentos[suma % ColoresSaman.acentos.length];
  }

  static String inicialesDe(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (p) => p.isNotEmpty && RegExp(r'[A-Za-zÁÉÍÓÚÑáéíóúñ]').hasMatch(p[0]),
        )
        .toList();
    if (partes.isEmpty) return '?';
    final primera = partes.first[0];
    final segunda = partes.length > 1 ? partes.last[0] : '';
    return (primera + segunda).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorDe(nombre);
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        inicialesDe(nombre),
        style: TextStyle(
          color: ColoresSaman.blanco,
          fontWeight: FontWeight.w800,
          fontSize: tamano * 0.36,
        ),
      ),
    );
  }
}

/// Etiqueta de estado en forma de pastilla, con fondo suave del mismo color.
class Insignia extends StatelessWidget {
  const Insignia({
    super.key,
    required this.texto,
    required this.color,
    this.icono,
  });

  final String texto;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícono dentro de un cuadro redondeado con degradado del color dado.
class IconoAcento extends StatelessWidget {
  const IconoAcento({
    super.key,
    required this.icono,
    required this.color,
    this.tamano = 48,
  });

  final IconData icono;
  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamano * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.2)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icono, color: ColoresSaman.blanco, size: tamano * 0.5),
    );
  }
}

/// Portada en verde Samán que continúa la barra superior. Lleva un título,
/// un subtítulo y lo que se ponga debajo.
///
/// Con [imagen], la foto ocupa la portada y se funde poco a poco con el
/// fondo crema de la pantalla, sin un corte brusco; sin ella, es un
/// degradado verde con círculos de luz.
class PortadaDegradado extends StatelessWidget {
  const PortadaDegradado({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.encima,
    this.debajo,
    this.anchoMaximo = 1000,
    this.espacioInferior = 28,
    this.imagen,
  });

  /// Foto de fondo (ruta de un asset).
  final String? imagen;

  final String titulo;
  final String? subtitulo;

  /// Lo que va antes del título, por ejemplo una etiqueta del actor.
  final Widget? encima;

  /// Lo que va después del subtítulo, por ejemplo indicadores.
  final Widget? debajo;
  final double anchoMaximo;

  /// Espacio debajo, para que las tarjetas puedan montarse sobre el borde.
  final double espacioInferior;

  @override
  Widget build(BuildContext context) {
    final imagen = this.imagen;
    final contenido = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, espacioInferior),
          child: Aparecer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (encima != null) ...[encima!, const SizedBox(height: 12)],
                Text(
                  titulo,
                  style: const TextStyle(
                    color: ColoresSaman.blanco,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitulo!,
                    style: TextStyle(
                      color: ColoresSaman.blanco.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (debajo != null) ...[const SizedBox(height: 18), debajo!],
              ],
            ),
          ),
        ),
      ),
    );

    if (imagen != null) {
      return Stack(
        children: [
          Positioned.fill(child: Image.asset(imagen, fit: BoxFit.cover)),
          // Verde sobre la foto para que el texto se lea, y al final el
          // color del fondo, para que la portada se funda con la pantalla.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.55, 1],
                  colors: [
                    ColoresSaman.azulNoche.withValues(alpha: 0.72),
                    ColoresSaman.azulNoche.withValues(alpha: 0.82),
                    ColoresSaman.fondo,
                  ],
                ),
              ),
            ),
          ),
          contenido,
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: ColoresSaman.degradadoNoche,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Círculos de luz decorativos.
          Positioned(
            right: -60,
            top: -80,
            child: _Circulo(220, ColoresSaman.naranja.withValues(alpha: 0.22)),
          ),
          Positioned(
            right: 140,
            bottom: -90,
            child: _Circulo(180, ColoresSaman.menta.withValues(alpha: 0.18)),
          ),
          Positioned(
            left: -40,
            bottom: -60,
            child: _Circulo(140, ColoresSaman.ambar.withValues(alpha: 0.12)),
          ),
          contenido,
        ],
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo(this.tamano, this.color);

  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Píldora translúcida para usar sobre la portada oscura.
class PildoraClara extends StatelessWidget {
  const PildoraClara({super.key, required this.texto, this.icono, this.color});

  final String texto;
  final IconData? icono;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? ColoresSaman.blanco.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresSaman.blanco.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: ColoresSaman.blanco),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: const TextStyle(
              color: ColoresSaman.blanco,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
