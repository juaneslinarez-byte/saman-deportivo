import 'package:flutter/material.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';

/// Página de bienvenida (landing), según la pantalla «Landing» del prototipo
/// en Figma: barra de navegación, portada, disciplinas, tarjetas por actor,
/// los tres pasos para inscribirse, un llamado a registrarse y el pie.
///
/// Es una página informativa: las disciplinas que muestra son ejemplos del
/// prototipo. El catálogo real, con los cupos de Firestore, está después de
/// iniciar sesión.
class BienvenidaView extends StatefulWidget {
  const BienvenidaView({super.key});

  @override
  State<BienvenidaView> createState() => _BienvenidaViewState();
}

class _BienvenidaViewState extends State<BienvenidaView> {
  // Secciones a las que lleva el menú de la barra superior.
  final _claveInicio = GlobalKey();
  final _claveDisciplinas = GlobalKey();
  final _claveComoFunciona = GlobalKey();
  final _claveContacto = GlobalKey();

  void _irA(GlobalKey clave) {
    final destino = clave.currentContext;
    if (destino == null) return;
    Scrollable.ensureVisible(
      destino,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _iniciarSesion() => Navigator.pushNamed(context, Rutas.login);

  void _registrarse() => Navigator.pushNamed(context, Rutas.registro);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.blanco,
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final ancho = restricciones.maxWidth;
          return Column(
            children: [
              _BarraSuperior(
                ancho: ancho,
                alInicio: () => _irA(_claveInicio),
                aDisciplinas: () => _irA(_claveDisciplinas),
                aComoFunciona: () => _irA(_claveComoFunciona),
                aContacto: () => _irA(_claveContacto),
                alIniciarSesion: _iniciarSesion,
                alRegistrarse: _registrarse,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _Portada(
                        key: _claveInicio,
                        ancho: ancho,
                        alRegistrarse: _registrarse,
                        alIniciarSesion: _iniciarSesion,
                      ),
                      _SeccionDisciplinas(
                        key: _claveDisciplinas,
                        ancho: ancho,
                        alVerTodas: _iniciarSesion,
                      ),
                      _SeccionActores(ancho: ancho, alEntrar: _iniciarSesion),
                      _SeccionPasos(key: _claveComoFunciona, ancho: ancho),
                      _Llamado(ancho: ancho, alRegistrarse: _registrarse),
                      _Pie(
                        key: _claveContacto,
                        ancho: ancho,
                        aDisciplinas: () => _irA(_claveDisciplinas),
                        aComoFunciona: () => _irA(_claveComoFunciona),
                        alIniciarSesion: _iniciarSesion,
                        alRegistrarse: _registrarse,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Utilidades de diseño comunes a las secciones
// ---------------------------------------------------------------------------

/// Ancho máximo del contenido, como el margen de 120 px del prototipo.
const double _anchoContenido = 1200;

/// Centra el contenido de una sección y le da los márgenes laterales.
class _Contenido extends StatelessWidget {
  const _Contenido({required this.child, this.vertical = 0});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: vertical),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _anchoContenido),
          child: child,
        ),
      ),
    );
  }
}

/// Etiqueta naranja en mayúsculas que va sobre el título de cada sección.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: ColoresSaman.naranja,
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto, {this.centrado = false});

  final String texto;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: centrado ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ColoresSaman.azulOscuro,
      ),
    );
  }
}

/// Enlace naranja con flecha, como «Ver todas las disciplinas →».
class _EnlaceFlecha extends StatelessWidget {
  const _EnlaceFlecha({required this.texto, required this.alPulsar});

  final String texto;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPulsar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColoresSaman.naranja,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: ColoresSaman.naranja,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón naranja en forma de pastilla con sombra naranja suave.
class _BotonNaranja extends StatelessWidget {
  const _BotonNaranja({
    required this.texto,
    required this.alPulsar,
    this.grande = false,
  });

  final String texto;
  final VoidCallback alPulsar;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: ColoresSaman.naranja.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresSaman.naranja,
          foregroundColor: ColoresSaman.blanco,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: grande ? 24 : 18,
            vertical: grande ? 18 : 12,
          ),
          shape: const StadiumBorder(),
        ),
        onPressed: alPulsar,
        child: Text(
          texto,
          style: TextStyle(
            fontSize: grande ? 15 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Botón blanco en forma de pastilla con texto naranja.
class _BotonBlanco extends StatelessWidget {
  const _BotonBlanco({
    required this.texto,
    required this.alPulsar,
    this.grande = false,
    this.borde = false,
  });

  final String texto;
  final VoidCallback alPulsar;
  final bool grande;
  final bool borde;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.naranja,
        side: BorderSide(
          color: borde ? const Color(0xFFE2E8F0) : ColoresSaman.blanco,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: grande ? 24 : 18,
          vertical: grande ? 18 : 12,
        ),
        shape: grande
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            : const StadiumBorder(),
      ),
      onPressed: alPulsar,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: grande ? 15 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Sombra suave de las tarjetas blancas del prototipo.
final List<BoxShadow> _sombraTarjeta = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

/// Tarjeta blanca con radio 18, borde muy claro y sombra suave.
BoxDecoration _decoracionTarjeta({double radio = 18}) => BoxDecoration(
  color: ColoresSaman.blanco,
  borderRadius: BorderRadius.circular(radio),
  border: Border.all(color: const Color(0xFFEEF0F3)),
  boxShadow: _sombraTarjeta,
);

// ---------------------------------------------------------------------------
// Barra superior
// ---------------------------------------------------------------------------

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({
    required this.ancho,
    required this.alInicio,
    required this.aDisciplinas,
    required this.aComoFunciona,
    required this.aContacto,
    required this.alIniciarSesion,
    required this.alRegistrarse,
  });

  final double ancho;
  final VoidCallback alInicio;
  final VoidCallback aDisciplinas;
  final VoidCallback aComoFunciona;
  final VoidCallback aContacto;
  final VoidCallback alIniciarSesion;
  final VoidCallback alRegistrarse;

  @override
  Widget build(BuildContext context) {
    final conMenu = ancho >= 900;
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: ancho >= 600 ? 40 : 16),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: alInicio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/imagenes/logo_saman.jpg',
                height: 54,
                width: 54,
              ),
            ),
          ),
          if (conMenu) ...[
            const SizedBox(width: 24),
            _OpcionMenu('Inicio', alInicio, activa: true),
            _OpcionMenu('Disciplinas', aDisciplinas),
            _OpcionMenu('Cómo funciona', aComoFunciona),
            _OpcionMenu('Contacto', aContacto),
          ],
          const Spacer(),
          // En el teléfono la portada ya trae los dos botones, así que la
          // barra solo deja «Registrarse».
          if (ancho >= 600) ...[
            _BotonBlanco(
              texto: 'Iniciar sesión',
              alPulsar: alIniciarSesion,
              borde: true,
            ),
            const SizedBox(width: 12),
          ],
          _BotonNaranja(texto: 'Registrarse', alPulsar: alRegistrarse),
        ],
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  const _OpcionMenu(this.texto, this.alPulsar, {this.activa = false});

  final String texto;
  final VoidCallback alPulsar;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: alPulsar,
      style: TextButton.styleFrom(
        foregroundColor: activa
            ? ColoresSaman.naranja
            : ColoresSaman.textoCampo,
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Portada
// ---------------------------------------------------------------------------

class _Portada extends StatelessWidget {
  const _Portada({
    super.key,
    required this.ancho,
    required this.alRegistrarse,
    required this.alIniciarSesion,
  });

  final double ancho;
  final VoidCallback alRegistrarse;
  final VoidCallback alIniciarSesion;

  @override
  Widget build(BuildContext context) {
    final conIlustracion = ancho >= 1000;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/imagenes/portada_pista.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Degradado azul oscuro para que el texto blanco se lea sobre la foto.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0.88),
                  const Color(0xFF0F172A).withValues(alpha: 0.55),
                  const Color(0xFF0F172A).withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
        ),
        _Contenido(
          vertical: ancho >= 600 ? 96 : 56,
          child: Row(
            children: [
              Expanded(child: _textoPortada(ancho)),
              if (conIlustracion) ...[
                const SizedBox(width: 48),
                const _IlustracionPortada(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _textoPortada(double ancho) {
    final tamanoTitulo = ancho >= 600 ? 58.0 : 40.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ColoresSaman.blanco,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: ColoresSaman.naranja),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Inscripciones abiertas · Trimestre 2026–2027–1',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ColoresSaman.naranja,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Vive el deporte',
          style: TextStyle(
            fontSize: tamanoTitulo,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: ColoresSaman.blanco,
          ),
        ),
        Text(
          'en la UNIMET',
          style: TextStyle(
            fontSize: tamanoTitulo,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: ColoresSaman.naranja,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Samán Deportivo reúne todas las disciplinas de la universidad: '
            'consulta horarios y cupos en tiempo real, inscríbete en un '
            'minuto y lleva el control de tu asistencia.',
            style: TextStyle(
              fontSize: 17,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _BotonNaranja(
              texto: 'Crear cuenta de estudiante',
              alPulsar: alRegistrarse,
              grande: true,
            ),
            _BotonBlanco(
              texto: 'Iniciar sesión',
              alPulsar: alIniciarSesion,
              grande: true,
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Wrap(
          spacing: 36,
          runSpacing: 16,
          children: [
            _Cifra('9', 'disciplinas'),
            _Cifra('12', 'entrenadores'),
            _Cifra('+240', 'estudiantes inscritos'),
          ],
        ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra(this.valor, this.texto);

  final String valor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ColoresSaman.blanco,
          ),
        ),
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Aro naranja con el logo y las tarjetas flotantes de la portada.
class _IlustracionPortada extends StatelessWidget {
  const _IlustracionPortada();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 470,
      height: 430,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Aro naranja.
          Positioned(
            left: 60,
            top: 40,
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF59A5B), ColoresSaman.naranja],
                ),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColoresSaman.blanco,
                  border: Border.all(color: ColoresSaman.azulOscuro, width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: _decoracionTarjeta(radio: 20),
                  child: Image.asset('assets/imagenes/logo_saman.jpg'),
                ),
              ),
            ),
          ),
          // Disciplina con su barra de cupos.
          Positioned(
            left: 0,
            top: 20,
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(14),
              decoration: _decoracionTarjeta(radio: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fútbol Campo Masculino',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lun y Mié · 4:00 PM',
                    style: TextStyle(
                      fontSize: 10,
                      color: ColoresSaman.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 18 / 25,
                      minHeight: 5,
                      color: ColoresSaman.verde,
                      backgroundColor: ColoresSaman.gris,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '18 / 25 cupos disponibles',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ColoresSaman.verde,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Asistencia.
          Positioned(
            right: 0,
            top: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: _decoracionTarjeta(radio: 10),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Asistencia',
                    style: TextStyle(
                      fontSize: 10,
                      color: ColoresSaman.textoSecundario,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '8 de 10',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ColoresSaman.naranja,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Inscripción confirmada.
          Positioned(
            right: 0,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: _decoracionTarjeta(radio: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColoresSaman.verde.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: ColoresSaman.verde,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inscripción confirmada',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Baloncesto Mixto',
                        style: TextStyle(
                          fontSize: 10,
                          color: ColoresSaman.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disciplinas
// ---------------------------------------------------------------------------

/// Disciplina de ejemplo de la portada (los datos del prototipo).
class _Disciplina {
  const _Disciplina({
    required this.foto,
    required this.deporte,
    required this.nombre,
    required this.horario,
    required this.cupos,
  });

  final String foto;
  final String deporte;
  final String nombre;
  final String horario;
  final int cupos;
}

const _disciplinas = [
  _Disciplina(
    foto: 'assets/imagenes/futbol.jpg',
    deporte: 'Fútbol',
    nombre: 'Fútbol Campo',
    horario: 'Lun y Mié · 4:00 PM',
    cupos: 18,
  ),
  _Disciplina(
    foto: 'assets/imagenes/baloncesto.jpg',
    deporte: 'Baloncesto',
    nombre: 'Baloncesto',
    horario: 'Mar y Jue · 2:00 PM',
    cupos: 5,
  ),
  _Disciplina(
    foto: 'assets/imagenes/tenis.jpg',
    deporte: 'Tenis',
    nombre: 'Tenis de Campo',
    horario: 'Viernes · 9:00 AM',
    cupos: 0,
  ),
  _Disciplina(
    foto: 'assets/imagenes/voleibol.jpg',
    deporte: 'Voleibol',
    nombre: 'Voleibol Mixto',
    horario: 'Mar y Jue · 6:00 PM',
    cupos: 18,
  ),
];

/// Cantidad de columnas de las cuadrículas según el ancho disponible.
int _columnas(double ancho, {required int maximo}) {
  if (ancho >= 1000) return maximo;
  if (ancho >= 640) return 2;
  return 1;
}

/// Ancho de cada tarjeta para repartir [columnas] en el ancho del contenido.
double _anchoTarjeta(double ancho, int columnas, double separacion) {
  final disponible = (ancho - 48).clamp(0, _anchoContenido).toDouble();
  return (disponible - separacion * (columnas - 1)) / columnas;
}

class _SeccionDisciplinas extends StatelessWidget {
  const _SeccionDisciplinas({
    super.key,
    required this.ancho,
    required this.alVerTodas,
  });

  final double ancho;
  final VoidCallback alVerTodas;

  @override
  Widget build(BuildContext context) {
    final columnas = _columnas(ancho, maximo: 4);
    final anchoTarjeta = _anchoTarjeta(ancho, columnas, 20);
    return _Contenido(
      vertical: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Etiqueta('Disciplinas'),
          const SizedBox(height: 8),
          ancho >= 640
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: _TituloSeccion('Encuentra tu deporte'),
                    ),
                    _EnlaceFlecha(
                      texto: 'Ver todas las disciplinas',
                      alPulsar: alVerTodas,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TituloSeccion('Encuentra tu deporte'),
                    const SizedBox(height: 8),
                    _EnlaceFlecha(
                      texto: 'Ver todas las disciplinas',
                      alPulsar: alVerTodas,
                    ),
                  ],
                ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final disciplina in _disciplinas)
                SizedBox(
                  width: anchoTarjeta,
                  child: _TarjetaDisciplina(disciplina),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaDisciplina extends StatelessWidget {
  const _TarjetaDisciplina(this.disciplina);

  final _Disciplina disciplina;

  @override
  Widget build(BuildContext context) {
    final conCupos = disciplina.cupos > 0;
    final colorCupos = conCupos ? ColoresSaman.verde : ColoresSaman.rojo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(disciplina.foto, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 10,
                    child: Text(
                      disciplina.deporte,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: ColoresSaman.blanco,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            disciplina.nombre,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            disciplina.horario,
            style: const TextStyle(
              fontSize: 12,
              color: ColoresSaman.textoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorCupos.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              conCupos ? '${disciplina.cupos} cupos' : 'Sin cupo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorCupos,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas por actor
// ---------------------------------------------------------------------------

class _Actor {
  const _Actor({
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    required this.titulo,
    required this.descripcion,
    required this.funciones,
    required this.enlace,
  });

  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final String titulo;
  final String descripcion;
  final List<String> funciones;
  final String enlace;
}

const _actores = [
  _Actor(
    icono: Icons.school,
    colorIcono: ColoresSaman.azulOscuro,
    fondoIcono: ColoresSaman.naranjaSuave,
    titulo: 'Estudiantes',
    descripcion:
        'Regístrate con tu correo institucional y gestiona tu vida deportiva.',
    funciones: [
      'Explora disciplinas y solicita unirte',
      'Reporta tu pago de solvencia',
      'Confirma asistencia a eventos',
      'Deja reseñas de la disciplina y del entrenador',
    ],
    enlace: 'Entrar como estudiante',
  ),
  _Actor(
    icono: Icons.military_tech,
    colorIcono: Color(0xFFCA8A04),
    fondoIcono: Color(0xFFEAF6EE),
    titulo: 'Entrenadores',
    descripcion: 'Lleva el control de cada disciplina que tienes a tu cargo.',
    funciones: [
      'Consulta inscritos, solvencia y cupos',
      'Registra la asistencia por sesión',
      'Solicita entrenar otras disciplinas',
      'Tu cuenta la crea el administrador',
    ],
    enlace: 'Entrar como entrenador',
  ),
  _Actor(
    icono: Icons.handyman,
    colorIcono: ColoresSaman.textoCampo,
    fondoIcono: ColoresSaman.gris,
    titulo: 'Administración',
    descripcion: 'La Dirección de Deportes supervisa todo desde un solo panel.',
    funciones: [
      'Resumen de estudiantes, entrenadores y eventos',
      'Valida pagos y solicitudes',
      'Crea, edita, oculta o elimina disciplinas',
      'Habilita o deshabilita usuarios',
    ],
    enlace: 'Entrar como administrador',
  ),
];

class _SeccionActores extends StatelessWidget {
  const _SeccionActores({required this.ancho, required this.alEntrar});

  final double ancho;
  final VoidCallback alEntrar;

  @override
  Widget build(BuildContext context) {
    final columnas = _columnas(ancho, maximo: 3);
    final anchoTarjeta = _anchoTarjeta(ancho, columnas == 2 ? 1 : columnas, 24);
    return _Contenido(
      vertical: 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Etiqueta('Un portal, tres roles'),
          const SizedBox(height: 8),
          const _TituloSeccion('Cada quien ve lo que necesita'),
          const SizedBox(height: 32),
          // En pantallas anchas las tres tarjetas van en fila y con la misma
          // altura, como en el prototipo.
          columnas == 3
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _actores.length; i++) ...[
                        if (i > 0) const SizedBox(width: 24),
                        Expanded(
                          child: _TarjetaActor(
                            actor: _actores[i],
                            alEntrar: alEntrar,
                            estirada: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    for (final actor in _actores)
                      SizedBox(
                        width: anchoTarjeta,
                        child: _TarjetaActor(actor: actor, alEntrar: alEntrar),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _TarjetaActor extends StatelessWidget {
  const _TarjetaActor({
    required this.actor,
    required this.alEntrar,
    this.estirada = false,
  });

  final _Actor actor;
  final VoidCallback alEntrar;

  /// Si la tarjeta ocupa toda la altura de la fila.
  final bool estirada;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: actor.fondoIcono,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(actor.icono, color: actor.colorIcono, size: 26),
          ),
          const SizedBox(height: 24),
          Text(
            actor.titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            actor.descripcion,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: ColoresSaman.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),
          for (final funcion in actor.funciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 16, color: ColoresSaman.verde),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      funcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ColoresSaman.textoCampo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // En la fila de tres tarjetas el enlace queda al fondo de cada una.
          if (estirada) const Spacer(),
          const SizedBox(height: 6),
          _EnlaceFlecha(texto: actor.enlace, alPulsar: alEntrar),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cómo funciona
// ---------------------------------------------------------------------------

class _SeccionPasos extends StatelessWidget {
  const _SeccionPasos({super.key, required this.ancho});

  final double ancho;

  static const _pasos = [
    ('Crea tu cuenta', 'Con tu correo @correo.unimet.edu.ve y tu carnet.'),
    ('Elige tu disciplina', 'Filtra por día, horario y cupos disponibles.'),
    ('Entrena y participa', 'Sigue tu asistencia y apúntate a los eventos.'),
  ];

  @override
  Widget build(BuildContext context) {
    final enFila = ancho >= 800;
    final pasos = [
      for (var i = 0; i < _pasos.length; i++)
        _Paso(numero: i + 1, titulo: _pasos[i].$1, texto: _pasos[i].$2),
    ];
    return _Contenido(
      vertical: 72,
      child: Column(
        children: [
          const _Etiqueta('Cómo funciona'),
          const SizedBox(height: 8),
          const _TituloSeccion('Inscríbete en tres pasos', centrado: true),
          const SizedBox(height: 40),
          enFila
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final paso in pasos) Expanded(child: paso)],
                )
              : Column(
                  children: [
                    for (final paso in pasos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: paso,
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.texto,
  });

  final int numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColoresSaman.naranja,
              boxShadow: [
                BoxShadow(
                  color: ColoresSaman.naranja.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColoresSaman.blanco,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: ColoresSaman.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Llamado a registrarse
// ---------------------------------------------------------------------------

class _Llamado extends StatelessWidget {
  const _Llamado({required this.ancho, required this.alRegistrarse});

  final double ancho;
  final VoidCallback alRegistrarse;

  @override
  Widget build(BuildContext context) {
    final enFila = ancho >= 760;
    const textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Listo para entrenar?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ColoresSaman.blanco,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Las inscripciones del trimestre 2026–2027–1 ya están abiertas.',
          style: TextStyle(fontSize: 14, color: ColoresSaman.blanco),
        ),
      ],
    );
    final boton = _BotonBlanco(
      texto: 'Crear cuenta',
      alPulsar: alRegistrarse,
      grande: true,
    );
    return _Contenido(
      vertical: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        decoration: BoxDecoration(
          color: ColoresSaman.naranja,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: ColoresSaman.naranja.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: enFila
            ? Row(
                children: [
                  const Expanded(child: textos),
                  boton,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [textos, const SizedBox(height: 24), boton],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pie de página
// ---------------------------------------------------------------------------

class _Pie extends StatelessWidget {
  const _Pie({
    super.key,
    required this.ancho,
    required this.aDisciplinas,
    required this.aComoFunciona,
    required this.alIniciarSesion,
    required this.alRegistrarse,
  });

  final double ancho;
  final VoidCallback aDisciplinas;
  final VoidCallback aComoFunciona;
  final VoidCallback alIniciarSesion;
  final VoidCallback alRegistrarse;

  @override
  Widget build(BuildContext context) {
    const marca = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Samán Deportivo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColoresSaman.blanco,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Portal de gestión de clubes deportivos\nUniversidad Metropolitana',
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: ColoresSaman.textoDiscreto,
          ),
        ),
      ],
    );
    final columnas = Wrap(
      spacing: 80,
      runSpacing: 24,
      children: [
        _ColumnaPie(
          titulo: 'Portal',
          enlaces: [
            ('Disciplinas', aDisciplinas),
            ('Cómo funciona', aComoFunciona),
            ('Iniciar sesión', alIniciarSesion),
            ('Registrarse', alRegistrarse),
          ],
        ),
        const _ColumnaPie(
          titulo: 'Contacto',
          enlaces: [
            ('Dirección de Deportes', null),
            ('deportes@unimet.edu.ve', null),
            ('Soporte SIRIUS', null),
          ],
        ),
      ],
    );
    return Container(
      width: double.infinity,
      color: ColoresSaman.azulOscuro,
      margin: const EdgeInsets.only(top: 48),
      child: _Contenido(
        vertical: 48,
        child: ancho >= 760
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: marca),
                  columnas,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [marca, const SizedBox(height: 32), columnas],
              ),
      ),
    );
  }
}

class _ColumnaPie extends StatelessWidget {
  const _ColumnaPie({required this.titulo, required this.enlaces});

  final String titulo;

  /// Texto de cada enlace y su acción; null si solo es informativo.
  final List<(String, VoidCallback?)> enlaces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ColoresSaman.blanco,
          ),
        ),
        const SizedBox(height: 12),
        for (final (texto, accion) in enlaces)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: accion,
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 13,
                  color: ColoresSaman.textoDiscreto,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
