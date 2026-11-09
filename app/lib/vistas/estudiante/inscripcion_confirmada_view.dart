import 'package:flutter/material.dart';

import '../../core/colores.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../viewmodels/inscripcion_viewmodel.dart';

/// «Inscripción confirmada» (CU-03): se muestra después de reservar el cupo.
/// Recibe como argumento de la ruta el [ResumenInscripcion].
class InscripcionConfirmadaView extends StatelessWidget {
  const InscripcionConfirmadaView({super.key});

  @override
  Widget build(BuildContext context) {
    final argumento = ModalRoute.of(context)?.settings.arguments;
    final resumen = argumento is ResumenInscripcion ? argumento : null;

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Inscripción',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // Se sale con los botones de la tarjeta, no con la flecha.
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: ColoresSaman.blanco,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: resumen == null
                ? const _SinResumen()
                : _Confirmada(resumen: resumen),
          ),
        ),
      ),
    );
  }
}

class _Confirmada extends StatelessWidget {
  const _Confirmada({required this.resumen});

  final ResumenInscripcion resumen;

  @override
  Widget build(BuildContext context) {
    final deporte = resumen.deporte;
    final horario = Horarios.resumen(resumen.sesiones, abreviado: false);
    final detalle = [...horario, if (deporte.lugar.isNotEmpty) deporte.lugar];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: ColoresSaman.verde.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check, color: ColoresSaman.verde, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          '¡Inscripción confirmada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Quedaste inscrito en ${deporte.nombre}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ColoresSaman.textoSecundario,
            fontSize: 13,
          ),
        ),
        if (detalle.isNotEmpty)
          Text(
            detalle.join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: ColoresSaman.verde.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Cupos restantes: ${deporte.cuposDisponibles} / '
            '${deporte.cupoMaximo}',
            style: const TextStyle(
              color: ColoresSaman.verde,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _Botones(),
      ],
    );
  }
}

/// Se muestra si la pantalla se abre sin una inscripción que mostrar.
class _SinResumen extends StatelessWidget {
  const _SinResumen();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No hay una inscripción para mostrar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 14),
        ),
        SizedBox(height: 16),
        _Botones(),
      ],
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones();

  // Se vuelve al inicio del estudiante, sin dejar la confirmación en el
  // historial.
  void _ir(BuildContext context, String ruta) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      ruta,
      ModalRoute.withName(Rutas.inicio),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresSaman.naranja,
            foregroundColor: ColoresSaman.blanco,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          onPressed: () => _ir(context, Rutas.catalogo),
          child: const Text(
            'Volver al catálogo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ColoresSaman.naranja,
            side: const BorderSide(color: ColoresSaman.naranja),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const StadiumBorder(),
          ),
          onPressed: () => _ir(context, Rutas.misDisciplinas),
          child: const Text(
            'Ver mis disciplinas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
