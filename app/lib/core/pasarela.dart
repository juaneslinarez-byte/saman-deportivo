import 'dart:math';

/// Pasarela de pago simulada: espera como lo haría PayPal y devuelve una
/// referencia con el mismo formato que los pagos de solvencia.
abstract final class PasarelaSimulada {
  static final Random _azar = Random.secure();

  /// Cobra [monto] y devuelve la referencia de la operación, como
  /// «PAYPAL-7KQ2M9XA4T1B».
  static Future<String> cobrar(double monto) async {
    if (monto <= 0) throw Exception('El monto del pago no es válido.');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final codigo = List.generate(
      12,
      (_) => caracteres[_azar.nextInt(caracteres.length)],
    ).join();
    return 'PAYPAL-$codigo';
  }
}
