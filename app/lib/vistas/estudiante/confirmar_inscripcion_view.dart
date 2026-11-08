import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/horarios.dart';
import '../../core/rutas.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/inscripcion_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';

/// «Confirmar inscripción» (CU-03): resumen de la disciplina antes de
/// reservar el cupo. Se abre desde el detalle de la disciplina, que le pasa
/// el [Deporte] como argumento de la ruta.
class ConfirmarInscripcionView extends StatelessWidget {
  const ConfirmarInscripcionView({super.key});

  @override
  Widget build(BuildContext context) {
    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is! Deporte) {
      return const _Marco(
        child: _MensajeConVolver('No se encontró la disciplina.'),
      );
    }

    return ChangeNotifierProvider<InscripcionViewModel>(
      create: (context) => InscripcionViewModel(
        inscripcionRepository: context.read<InscripcionRepository>(),
        deporteRepository: context.read<DeporteRepository>(),
        deporte: argumento,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InscripcionViewModel>();
    final perfil = context.watch<PerfilViewModel>().perfil;

    return PopScope(
      // No se puede salir mientras se procesa la inscripción.
      canPop: !viewModel.procesando,
      child: _Marco(
        child: switch (viewModel.estado) {
          InscripcionEstado.cargando => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: ColoresSaman.naranja),
            ),
          ),
          InscripcionEstado.error => _MensajeConVolver(
            'No se pudo cargar la disciplina. Intenta de nuevo.',
            alReintentar: viewModel.cargar,
          ),
          InscripcionEstado.listo => _Resumen(
            viewModel: viewModel,
            perfil: perfil,
          ),
        },
      ),
    );
  }
}

/// Fondo, barra superior y tarjeta blanca centrada, como el cuadro de
/// confirmación del prototipo.
class _Marco extends StatelessWidget {
  const _Marco({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Inscripción',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
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
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.viewModel, required this.perfil});

  final InscripcionViewModel viewModel;
  final Persona? perfil;

  Future<void> _confirmar(BuildContext context) async {
    final exito = await viewModel.inscribir(perfil, viewModel.deporte);
    if (!exito || !context.mounted) return;

    // Reemplaza esta pantalla para que «atrás» no vuelva a pedir confirmar.
    Navigator.pushReplacementNamed(
      context,
      Rutas.inscripcionConfirmada,
      arguments: viewModel.resumen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deporte = viewModel.deporte;
    final horario = Horarios.resumen(viewModel.sesiones);
    final bloqueo = viewModel.motivoBloqueo(perfil);
    final error = viewModel.error;
    final procesando = viewModel.procesando;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmar inscripción',
          style: TextStyle(
            color: ColoresSaman.azulOscuro,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Revisa los datos antes de confirmar. Al hacerlo se reservará tu '
          'cupo.',
          style: TextStyle(color: ColoresSaman.textoSecundario, fontSize: 13),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: ColoresSaman.gris,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _Fila('Disciplina', deporte.nombre),
              _Fila(
                'Horario',
                horario.isEmpty ? 'Por confirmar' : horario.join('\n'),
              ),
              _Fila(
                'Lugar',
                deporte.lugar.isEmpty ? 'Por confirmar' : deporte.lugar,
              ),
              _Fila(
                'Cupos',
                '${deporte.cuposDisponibles} / ${deporte.cupoMaximo} '
                    'disponibles',
              ),
            ],
          ),
        ),

        if (bloqueo != null) ...[
          const SizedBox(height: 14),
          _Aviso(mensaje: bloqueo, esError: false),
          // Sin solvencia, el camino es pagar la cuota.
          if (perfil case Estudiante(solvente: false))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: ColoresSaman.naranja,
                ),
                onPressed: () => Navigator.pushNamed(context, Rutas.solvencia),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pagar mi solvencia'),
              ),
            ),
        ],
        if (error != null) ...[
          const SizedBox(height: 14),
          _Aviso(mensaje: error, esError: true),
        ],
        const SizedBox(height: 22),

        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: ColoresSaman.gris,
                foregroundColor: ColoresSaman.azulOscuro,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: const StadiumBorder(),
              ),
              onPressed: procesando ? null : () => Navigator.maybePop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresSaman.naranja,
                foregroundColor: ColoresSaman.blanco,
                disabledBackgroundColor: ColoresSaman.naranja.withValues(
                  alpha: 0.5,
                ),
                disabledForegroundColor: ColoresSaman.blanco,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: (bloqueo != null || procesando)
                  ? null
                  : () => _confirmar(context),
              child: procesando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ColoresSaman.blanco,
                      ),
                    )
                  : const Text(
                      'Confirmar inscripción',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Una fila del resumen: etiqueta a la izquierda y valor a la derecha.
class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              color: ColoresSaman.textoSecundario,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: ColoresSaman.azulOscuro,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso dentro de la tarjeta: naranja si algo impide inscribirse, rojo si la
/// inscripción falló.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje, required this.esError});

  final String mensaje;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final color = esError ? ColoresSaman.rojo : ColoresSaman.naranja;
    final fondo = esError
        ? ColoresSaman.rojo.withValues(alpha: 0.08)
        : ColoresSaman.naranjaSuave;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Mensaje centrado con el botón «Volver» y, si se pasa [alReintentar], también
/// «Reintentar».
class _MensajeConVolver extends StatelessWidget {
  const _MensajeConVolver(this.mensaje, {this.alReintentar});

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ColoresSaman.textoSecundario,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            if (alReintentar != null)
              TextButton(
                onPressed: alReintentar,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: ColoresSaman.naranja),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text(
                'Volver',
                style: TextStyle(color: ColoresSaman.naranja),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
