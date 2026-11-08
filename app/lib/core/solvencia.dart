/// Datos fijos del pago de solvencia deportiva.
///
/// Mientras no esté la integración real con PayPal (Hito 4), el pago se
/// simula: el estudiante confirma, se genera una referencia y el pago queda
/// en revisión hasta que el administrador lo aprueba o lo rechaza.
abstract final class Solvencia {
  /// Cuota de solvencia deportiva del trimestre, en dólares.
  static const double monto = 20;

  static const String concepto = 'Solvencia deportiva del trimestre';

  /// «$20,00», con coma decimal como se escribe en Venezuela.
  static String formatoMonto(double monto) =>
      '\$${monto.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Fecha y hora para el historial de pagos: «08/11/2026 15:42».
  static String formatoFechaHora(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}
