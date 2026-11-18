import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colores.dart';
import '../../core/rutas.dart';
import '../../core/solvencia.dart';
import '../../modelos/modelos.dart';
import '../../repositorios/repositorios.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../../viewmodels/solvencia_viewmodel.dart';
import '../comun/boton_paypal.dart';

/// «Mi solvencia» (CU-12): el estudiante ve si está solvente, paga la cuota
/// del trimestre y sigue el estado de sus pagos.
class SolvenciaView extends StatelessWidget {
  const SolvenciaView({super.key});

  @override
  Widget build(BuildContext context) {
    final perfilViewModel = context.watch<PerfilViewModel>();
    final perfil = perfilViewModel.perfil;

    if (perfil is! Estudiante) {
      final cargando =
          perfilViewModel.estado == PerfilEstado.cargando ||
          perfilViewModel.estado == PerfilEstado.inicial;
      return _Marco(
        child: cargando
            ? const Center(
                child: CircularProgressIndicator(color: ColoresSaman.naranja),
              )
            : const _Mensaje('No se encontró tu perfil de estudiante.'),
      );
    }

    return ChangeNotifierProvider<SolvenciaViewModel>(
      key: ValueKey(perfil.id),
      create: (context) => SolvenciaViewModel(
        pagoRepository: context.read<PagoRepository>(),
        idEstudiante: perfil.id,
      )..cargar(),
      child: const _Pantalla(),
    );
  }
}

class _Pantalla extends StatelessWidget {
  const _Pantalla();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolvenciaViewModel>();
    final perfil = context.watch<PerfilViewModel>().perfil;
    if (perfil is! Estudiante) return const _Marco(child: SizedBox.shrink());

    return _Marco(
      child: switch (vm.estado) {
        SolvenciaEstado.cargando => const Center(
          child: CircularProgressIndicator(color: ColoresSaman.naranja),
        ),
        SolvenciaEstado.error => _Mensaje(
          'No se pudieron cargar tus pagos. Revisa tu conexión.',
          alReintentar: vm.cargar,
        ),
        SolvenciaEstado.listo => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Estado(perfil: perfil, vm: vm),
            if (vm.motivoParaNoPagar(perfil) == null) ...[
              const SizedBox(height: 20),
              _TarjetaPago(perfil: perfil, vm: vm),
            ],
            const SizedBox(height: 28),
            const Text(
              'Historial de pagos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColoresSaman.azulOscuro,
              ),
            ),
            const SizedBox(height: 10),
            if (vm.pagos.isEmpty)
              const Text(
                'Todavía no has hecho ningún pago.',
                style: TextStyle(color: ColoresSaman.textoSecundario),
              )
            else
              for (final pago in vm.pagos) _FilaPago(pago: pago),
          ],
        ),
      },
    );
  }
}

/// Situación actual: solvente, pago en revisión o no solvente.
class _Estado extends StatelessWidget {
  const _Estado({required this.perfil, required this.vm});

  final Estudiante perfil;
  final SolvenciaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final enRevision = vm.pagoEnRevision;
    final (icono, color, titulo, detalle) = perfil.solvente
        ? (
            Icons.verified_outlined,
            ColoresSaman.verde,
            'Estás solvente',
            'Ya puedes inscribirte en las disciplinas del catálogo.',
          )
        : enRevision != null
        ? (
            Icons.hourglass_top_outlined,
            ColoresSaman.naranja,
            'Pago en revisión',
            'Pagaste ${Solvencia.formatoMonto(enRevision.monto)} '
                '(referencia ${enRevision.referencia}). El administrador lo '
                'revisará y, al aprobarlo, quedarás solvente.',
          )
        : (
            Icons.error_outline,
            ColoresSaman.rojo,
            'No estás solvente',
            vm.ultimoRechazado
                ? 'Tu último pago fue rechazado. Puedes pagar de nuevo; si '
                      'crees que es un error, contacta a la coordinación de '
                      'deportes.'
                : 'Paga la cuota del trimestre para poder inscribirte en '
                      'una disciplina.',
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColoresSaman.textoSecundario,
                  ),
                ),
                if (perfil.solvente) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: ColoresSaman.naranja,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, Rutas.catalogo),
                    icon: const Icon(Icons.sports_soccer_outlined),
                    label: const Text('Ir al catálogo'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPago extends StatelessWidget {
  const _TarjetaPago({required this.perfil, required this.vm});

  final Estudiante perfil;
  final SolvenciaViewModel vm;

  /// PayPal ya cobró: se registra el pago con el id de la operación.
  ///
  /// Al registrarse, esta tarjeta desaparece (el pago queda en revisión),
  /// así que los avisos se muestran con el navegador de la pantalla.
  Future<void> _registrar(BuildContext context, String idPayPal) async {
    final navegador = Navigator.of(context);
    final avisos = ScaffoldMessenger.of(context);
    final pago = await vm.pagar(perfil, referencia: idPayPal);
    if (!navegador.mounted) return;
    if (pago == null) {
      avisos.showSnackBar(
        SnackBar(
          content: Text(
            '${vm.error ?? 'No se pudo registrar el pago.'} Guarda tu '
            'referencia de PayPal ($idPayPal) y contacta a la coordinación '
            'de deportes.',
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: ColoresSaman.rojo,
        ),
      );
      return;
    }
    await showDialog<void>(
      context: navegador.context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: ColoresSaman.verde,
          size: 48,
        ),
        title: const Text('Pago recibido'),
        content: Text(
          'Referencia: ${pago.referencia}\n'
          'Monto: ${Solvencia.formatoMonto(pago.monto)}\n\n'
          'Tu pago está en revisión. Te avisaremos aquí mismo cuando el '
          'administrador lo apruebe.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            Solvencia.concepto,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Solvencia.formatoMonto(vm.monto),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: ColoresSaman.azulOscuro,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pago con PayPal en modo de prueba (sandbox): usa una cuenta de '
            'prueba de PayPal; no se cobra dinero real.',
            style: TextStyle(fontSize: 12, color: ColoresSaman.textoSecundario),
          ),
          const SizedBox(height: 16),
          if (vm.pagando)
            const SizedBox(
              height: 56,
              child: Center(
                child: CircularProgressIndicator(color: ColoresSaman.naranja),
              ),
            )
          else
            BotonPayPal(
              monto: vm.monto,
              descripcion: Solvencia.concepto,
              alAprobar: (id) => _registrar(context, id),
              alFallar: (error) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'PayPal no pudo procesar el pago. No se hizo ningún cobro.',
                  ),
                  backgroundColor: ColoresSaman.rojo,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaPago extends StatelessWidget {
  const _FilaPago({required this.pago});

  final Pago pago;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (pago.estado) {
      EstadoPago.pendiente => ('En revisión', ColoresSaman.naranja),
      EstadoPago.aprobado => ('Aprobado', ColoresSaman.verde),
      EstadoPago.rechazado => ('Rechazado', ColoresSaman.rojo),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresSaman.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresSaman.gris),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Solvencia.formatoMonto(pago.monto),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
                Text(
                  '${Solvencia.formatoFechaHora(pago.fecha)} · '
                  '${pago.referencia}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColoresSaman.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: const Text(
          'Mi solvencia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: child,
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto, {this.alReintentar});

  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresSaman.textoSecundario),
            ),
            if (alReintentar != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: alReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
