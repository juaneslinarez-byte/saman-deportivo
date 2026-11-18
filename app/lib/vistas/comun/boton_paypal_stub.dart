import 'package:flutter/material.dart';

/// Versión sin navegador del botón de PayPal (pruebas).
class BotonPayPal extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      const Text('PayPal solo está disponible en el navegador.');
}
