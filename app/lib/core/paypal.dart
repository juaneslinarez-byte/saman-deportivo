/// Datos de la integración con PayPal.
///
/// Se usa el entorno **sandbox** (de prueba): los pagos son reales para
/// PayPal pero con cuentas ficticias, así que no se cobra dinero. El Client
/// ID es público por diseño (va en el navegador); el Secret nunca se guarda
/// en la app.
abstract final class PayPal {
  static const String clientId =
      'BAA5Uz5Jvb1xNVBuyvhweXoIB02WLyzj2dl89w-3Ee0eEAsEOLUSaNjCbq2H9j3a-2WP0CavfPrgRRjj5Q';

  /// Monto con dos decimales y punto, como lo pide la API («7.50»).
  static String monto(double valor) => valor.toStringAsFixed(2);
}
