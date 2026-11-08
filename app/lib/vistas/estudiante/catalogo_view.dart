import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/formatos.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/catalogo_viewmodel.dart';

/// Catálogo de disciplinas del estudiante (RF-EST-02, RF-EST-03): buscador,
/// filtros por cupos, día y franja, y una tarjeta por disciplina.
///
/// No muestra el nombre del entrenador: el estudiante no puede leer los
/// perfiles de otros usuarios.
class CatalogoView extends StatelessWidget {
  const CatalogoView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CatalogoViewModel>(
      create: (context) => CatalogoViewModel(
        deporteRepository: context.read<DeporteRepository>(),
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatefulWidget {
  const _Pantalla();

  @override
  State<_Pantalla> createState() => _PantallaState();
}

class _PantallaState extends State<_Pantalla> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Borra también el texto del buscador, que vive en esta pantalla.
  void _limpiar(CatalogoViewModel viewModel) {
    _controlador.clear();
    viewModel.limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CatalogoViewModel>();

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Catálogo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: switch (viewModel.estado) {
            CatalogoEstado.cargando => const Center(
              child: CircularProgressIndicator(color: ColoresSaman.naranja),
            ),
            CatalogoEstado.error => _MensajeError(
              alReintentar: viewModel.cargar,
            ),
            CatalogoEstado.listo => _Listado(
              viewModel: viewModel,
              controlador: _controlador,
              alLimpiar: () => _limpiar(viewModel),
            ),
          },
        ),
      ),
    );
  }
}

class _Listado extends StatelessWidget {
  const _Listado({
    required this.viewModel,
    required this.controlador,
    required this.alLimpiar,
  });

  final CatalogoViewModel viewModel;
  final TextEditingController controlador;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    final deportes = viewModel.deportesFiltrados;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Disciplinas deportivas',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Encuentra tu disciplina por nombre, cupos, día u horario.',
          style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 13),
        ),
        const SizedBox(height: 18),
        _Buscador(viewModel: viewModel, controlador: controlador),
        const SizedBox(height: 12),
        _Filtros(viewModel: viewModel, alLimpiar: alLimpiar),
        const SizedBox(height: 20),
        if (deportes.isEmpty)
          _Vacio(hayDeportes: viewModel.totalDeportes > 0, alLimpiar: alLimpiar)
        else
          LayoutBuilder(
            builder: (context, restricciones) {
              // Dos columnas en pantalla ancha, una en el teléfono.
              const espacio = 16.0;
              final columnas = restricciones.maxWidth >= 640 ? 2 : 1;
              final ancho =
                  (restricciones.maxWidth - espacio * (columnas - 1)) /
                  columnas;
              return Wrap(
                spacing: espacio,
                runSpacing: espacio,
                children: [
                  for (final deporte in deportes)
                    SizedBox(
                      width: ancho,
                      child: _TarjetaDisciplina(
                        deporte: deporte,
                        sesiones: viewModel.sesionesDe(deporte.id),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Búsqueda por nombre, código o descripción, sin importar mayúsculas ni
/// tildes.
class _Buscador extends StatelessWidget {
  const _Buscador({required this.viewModel, required this.controlador});

  final CatalogoViewModel viewModel;
  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: ColoresSaman.textoDiscreto.withValues(alpha: 0.4),
      ),
    );

    return TextField(
      controller: controlador,
      inputFormatters: Entradas.busqueda,
      onChanged: viewModel.cambiarBusqueda,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: ColoresSaman.azulOscuro, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o código',
        prefixIcon: const Icon(
          Icons.search,
          color: ColoresSaman.textoSecundario,
        ),
        suffixIcon: viewModel.busqueda.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: ColoresSaman.textoSecundario,
                ),
                onPressed: () {
                  controlador.clear();
                  viewModel.cambiarBusqueda('');
                },
              ),
        filled: true,
        fillColor: ColoresSaman.blanco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: borde,
        enabledBorder: borde,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: ColoresSaman.naranja),
        ),
      ),
    );
  }
}

/// Chips de filtro: cupos, día de la semana y franja horaria.
class _Filtros extends StatelessWidget {
  const _Filtros({required this.viewModel, required this.alLimpiar});

  final CatalogoViewModel viewModel;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    final dia = viewModel.dia;
    final franja = viewModel.franja;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => viewModel.cambiarSoloConCupos(!viewModel.soloConCupos),
          child: _Pildora(
            texto: 'Con cupos',
            activa: viewModel.soloConCupos,
            icono: Icons.check_circle_outline,
          ),
        ),
        PopupMenuButton<int>(
          tooltip: 'Filtrar por día',
          initialValue: dia?.index ?? -1,
          color: ColoresSaman.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (valor) =>
              viewModel.cambiarDia(valor < 0 ? null : DiaSemana.values[valor]),
          itemBuilder: (context) => [
            const PopupMenuItem(value: -1, child: Text('Cualquier día')),
            for (final opcion in DiaSemana.values)
              PopupMenuItem(
                value: opcion.index,
                child: Text(_nombreDia(opcion)),
              ),
          ],
          child: _Pildora(
            texto: dia == null ? 'Día' : _nombreDia(dia),
            activa: dia != null,
            icono: Icons.calendar_today_outlined,
            conFlecha: true,
          ),
        ),
        PopupMenuButton<int>(
          tooltip: 'Filtrar por franja horaria',
          initialValue: franja?.index ?? -1,
          color: ColoresSaman.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (valor) => viewModel.cambiarFranja(
            valor < 0 ? null : FranjaHoraria.values[valor],
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: -1, child: Text('Cualquier horario')),
            for (final opcion in FranjaHoraria.values)
              PopupMenuItem(
                value: opcion.index,
                child: Text(_detalleFranja(opcion)),
              ),
          ],
          child: _Pildora(
            texto: franja == null ? 'Horario' : _nombreFranja(franja),
            activa: franja != null,
            icono: Icons.schedule,
            conFlecha: true,
          ),
        ),
        if (viewModel.hayFiltros)
          TextButton(
            onPressed: alLimpiar,
            child: const Text(
              'Limpiar filtros',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

String _nombreDia(DiaSemana dia) => switch (dia) {
  DiaSemana.lunes => 'Lunes',
  DiaSemana.martes => 'Martes',
  DiaSemana.miercoles => 'Miércoles',
  DiaSemana.jueves => 'Jueves',
  DiaSemana.viernes => 'Viernes',
  DiaSemana.sabado => 'Sábado',
  DiaSemana.domingo => 'Domingo',
};

String _nombreFranja(FranjaHoraria franja) => switch (franja) {
  FranjaHoraria.manana => 'Mañana',
  FranjaHoraria.tarde => 'Tarde',
  FranjaHoraria.noche => 'Noche',
};

String _detalleFranja(FranjaHoraria franja) => switch (franja) {
  FranjaHoraria.manana => 'Mañana (antes de 12:00)',
  FranjaHoraria.tarde => 'Tarde (12:00 a 18:00)',
  FranjaHoraria.noche => 'Noche (después de 18:00)',
};

/// Aspecto de un chip de filtro. No es tocable por sí mismo: quien lo usa lo
/// envuelve en un InkWell o en un menú.
class _Pildora extends StatelessWidget {
  const _Pildora({
    required this.texto,
    required this.activa,
    required this.icono,
    this.conFlecha = false,
  });

  final String texto;
  final bool activa;
  final IconData icono;
  final bool conFlecha;

  @override
  Widget build(BuildContext context) {
    final color = activa ? ColoresSaman.blanco : ColoresSaman.textoCampo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: activa ? ColoresSaman.naranja : ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activa
              ? ColoresSaman.naranja
              : ColoresSaman.textoDiscreto.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (conFlecha) Icon(Icons.arrow_drop_down, size: 20, color: color),
        ],
      ),
    );
  }
}

/// Fotos que ya tiene la app; el resto de deportes usa un fondo de color.
const _fotos = [
  ('fútbol', 'assets/imagenes/futbol.jpg'),
  ('futbol', 'assets/imagenes/futbol.jpg'),
  ('baloncesto', 'assets/imagenes/baloncesto.jpg'),
  ('tenis', 'assets/imagenes/tenis.jpg'),
  ('voleibol', 'assets/imagenes/voleibol.jpg'),
];

String? _fotoDe(Deporte deporte) {
  final nombre = deporte.nombre.toLowerCase();
  for (final (clave, ruta) in _fotos) {
    if (nombre.contains(clave)) return ruta;
  }
  return null;
}

class _TarjetaDisciplina extends StatelessWidget {
  const _TarjetaDisciplina({required this.deporte, required this.sesiones});

  final Deporte deporte;
  final List<Sesion> sesiones;

  @override
  Widget build(BuildContext context) {
    final horario = Horarios.resumen(sesiones);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Al tocar la tarjeta se abre el detalle de la disciplina.
          onTap: () => Navigator.pushNamed(
            context,
            Rutas.detalleDisciplina,
            arguments: deporte.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Foto(deporte: deporte),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deporte.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ColoresSaman.azulOscuro,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!deporte.hayCupo) ...[
                          const SizedBox(width: 10),
                          const _EtiquetaSinCupos(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (deporte.lugar.isNotEmpty)
                      _Dato(icono: Icons.place_outlined, texto: deporte.lugar),
                    _Dato(
                      icono: Icons.schedule,
                      texto: horario.isEmpty
                          ? 'Horario por confirmar'
                          : horario.join('\n'),
                    ),
                    _Dato(
                      icono: Icons.group_outlined,
                      texto:
                          '${deporte.cuposDisponibles} de '
                          '${deporte.cupoMaximo} cupos',
                      destacado: deporte.hayCupo,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto del deporte o, si no hay, un fondo de color con un ícono.
class _Foto extends StatelessWidget {
  const _Foto({required this.deporte});

  final Deporte deporte;

  @override
  Widget build(BuildContext context) {
    final foto = _fotoDe(deporte);
    const respaldo = ColoredBox(
      color: ColoresSaman.naranjaSuave,
      child: Center(
        child: Icon(
          Icons.sports_soccer_outlined,
          size: 44,
          color: ColoresSaman.naranja,
        ),
      ),
    );

    return SizedBox(
      height: 130,
      width: double.infinity,
      child: foto == null
          ? respaldo
          : Image.asset(
              foto,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => respaldo,
            ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.texto,
    this.destacado = false,
  });

  final IconData icono;
  final String texto;

  /// Resalta el texto (por ejemplo, los cupos cuando todavía hay).
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: ColoresSaman.textoSecundario),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: destacado
                    ? ColoresSaman.azulOscuro
                    : ColoresSaman.textoSecundario,
                fontSize: 12.5,
                fontWeight: destacado ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta gris para las disciplinas sin cupos.
class _EtiquetaSinCupos extends StatelessWidget {
  const _EtiquetaSinCupos();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: ColoresSaman.textoSecundario.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Sin cupos',
        style: TextStyle(
          color: ColoresSaman.textoSecundario,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Sin resultados: con filtros se ofrece limpiarlos; si no hay ninguna
/// disciplina publicada, solo se avisa.
class _Vacio extends StatelessWidget {
  const _Vacio({required this.hayDeportes, required this.alLimpiar});

  final bool hayDeportes;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 48,
            color: ColoresSaman.textoSecundario,
          ),
          const SizedBox(height: 12),
          Text(
            hayDeportes
                ? 'No hay disciplinas con esos filtros'
                : 'Aún no hay disciplinas disponibles.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 14,
            ),
          ),
          if (hayDeportes) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresSaman.naranja,
                foregroundColor: ColoresSaman.blanco,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: alLimpiar,
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudo cargar el catálogo. Intenta de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColoresSaman.textoSecundario,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: alReintentar,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: ColoresSaman.naranja),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
