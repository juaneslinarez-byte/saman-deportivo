/// Botón de pago con PayPal. En la web pinta el botón oficial de PayPal
/// (sandbox); en las pruebas, que no corren en un navegador, muestra un
/// aviso en su lugar.
library;

export 'boton_paypal_stub.dart'
    if (dart.library.js_interop) 'boton_paypal_web.dart';
