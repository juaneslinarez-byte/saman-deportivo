import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../core/colores.dart';
import '../../core/paypal.dart';

@JS('samanPayPal.cargar')
external JSPromise<JSAny?> _cargar(String clientId);

@JS('samanPayPal.pintar')
external void _pintar(
  web.HTMLElement contenedor,
  String monto,
  String descripcion,
  JSFunction alAprobar,
  JSFunction alCancelar,
  JSFunction alFallar,
);

/// Botón oficial de PayPal (sandbox). Al aprobar el pago en la ventana de
/// PayPal, la orden se captura y [alAprobar] recibe el id de la operación,
/// que se guarda como referencia del pago.
class BotonPayPal extends StatefulWidget {
  const BotonPayPal({
    super.key,
    required this.monto,
    required this.descripcion,
    required this.alAprobar,
    this.alCancelar,
    this.alFallar,
  });

  final double monto;
  final String descripcion;
  final ValueChanged<String> alAprobar;
  final VoidCallback? alCancelar;
  final ValueChanged<String>? alFallar;

  @override
  State<BotonPayPal> createState() => _BotonPayPalState();
}

class _BotonPayPalState extends State<BotonPayPal> {
  late Future<void> _sdk;

  @override
  void initState() {
    super.initState();
    _sdk = _cargar(PayPal.clientId).toDart;
  }

  void _alCrear(Object elemento) {
    final contenedor = elemento as web.HTMLElement;
    contenedor.style.width = '100%';
    contenedor.style.height = '100%';
    _pintar(
      contenedor,
      PayPal.monto(widget.monto),
      widget.descripcion,
      ((JSString id) {
        if (mounted) widget.alAprobar(id.toDart);
      }).toJS,
      (() {
        if (mounted) widget.alCancelar?.call();
      }).toJS,
      ((JSString error) {
        if (mounted) widget.alFallar?.call(error.toDart);
      }).toJS,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sdk,
      builder: (context, estado) {
        if (estado.hasError) {
          return Column(
            children: [
              const Text(
                'No se pudo cargar PayPal. Revisa tu conexión.',
                style: TextStyle(color: ColoresSaman.rojo),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _sdk = _cargar(PayPal.clientId).toDart;
                }),
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        if (estado.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 50,
            child: Center(
              child: CircularProgressIndicator(color: ColoresSaman.naranja),
            ),
          );
        }
        return SizedBox(
          height: 56,
          // Cambia de clave si cambia el monto, para volver a pintar el botón.
          child: HtmlElementView.fromTagName(
            key: ValueKey('${widget.monto}-${widget.descripcion}'),
            tagName: 'div',
            onElementCreated: _alCrear,
          ),
        );
      },
    );
  }
}
