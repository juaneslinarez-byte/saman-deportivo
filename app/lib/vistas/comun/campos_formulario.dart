import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colores.dart';
import '../../core/validadores.dart';

/// Estilo común de los campos de los formularios: etiqueta arriba, fondo
/// gris, esquinas redondeadas y borde naranja al escribir.
InputDecoration decoracionCampo({
  String? pista,
  String? ayuda,
  Widget? sufijo,
  bool habilitado = true,
}) {
  OutlineInputBorder borde(Color color, [double ancho = 1.5]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: ancho),
      );
  return InputDecoration(
    hintText: pista,
    hintStyle: const TextStyle(color: ColoresSaman.textoTenue, fontSize: 13),
    helperText: ayuda,
    helperMaxLines: 2,
    errorMaxLines: 2,
    filled: true,
    fillColor: habilitado
        ? ColoresSaman.gris
        : ColoresSaman.gris.withValues(alpha: 0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: sufijo,
    border: borde(Colors.transparent, 0),
    enabledBorder: borde(Colors.transparent, 0),
    disabledBorder: borde(Colors.transparent, 0),
    focusedBorder: borde(ColoresSaman.naranja),
    errorBorder: borde(ColoresSaman.rojo, 1),
    focusedErrorBorder: borde(ColoresSaman.rojo),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: ColoresSaman.textoCampo,
      ),
    ),
  );
}

/// Campo de texto con su etiqueta. Si es una contraseña, trae el botón para
/// mostrarla u ocultarla.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    this.controller,
    this.valorInicial,
    this.pista,
    this.ayuda,
    this.validator,
    this.formateadores,
    this.teclado = TextInputType.text,
    this.esContrasena = false,
    this.accion = TextInputAction.next,
    this.alEnviar,
    this.alCambiar,
    this.autocompletar,
    this.habilitado = true,
  });

  final String etiqueta;
  final TextEditingController? controller;
  final String? valorInicial;
  final String? pista;
  final String? ayuda;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? formateadores;
  final TextInputType teclado;
  final bool esContrasena;
  final TextInputAction accion;
  final ValueChanged<String>? alEnviar;
  final ValueChanged<String>? alCambiar;
  final Iterable<String>? autocompletar;
  final bool habilitado;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  late bool _oculto = widget.esContrasena;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Etiqueta(widget.etiqueta),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.valorInicial : null,
          enabled: widget.habilitado,
          obscureText: _oculto,
          keyboardType: widget.teclado,
          textInputAction: widget.accion,
          onFieldSubmitted: widget.alEnviar,
          onChanged: widget.alCambiar,
          autofillHints: widget.autocompletar,
          inputFormatters: widget.formateadores,
          autocorrect: false,
          enableSuggestions: !widget.esContrasena,
          style: TextStyle(
            fontSize: 14,
            color: widget.habilitado
                ? ColoresSaman.azulOscuro
                : ColoresSaman.textoSecundario,
          ),
          decoration: decoracionCampo(
            pista: widget.pista,
            ayuda: widget.ayuda,
            habilitado: widget.habilitado,
            sufijo: widget.esContrasena
                ? IconButton(
                    tooltip: _oculto
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _oculto
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: ColoresSaman.textoSecundario,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}

/// Lista desplegable con su etiqueta, para datos que se eligen de una lista
/// cerrada como la carrera o la especialidad.
class CampoSeleccion extends StatelessWidget {
  const CampoSeleccion({
    super.key,
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.alCambiar,
    this.pista = 'Selecciona una opción',
    this.validator,
  });

  final String etiqueta;
  final List<String> opciones;
  final String? valor;
  final ValueChanged<String?> alCambiar;
  final String pista;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Etiqueta(etiqueta),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          decoration: decoracionCampo(pista: pista),
          hint: Text(
            pista,
            style: const TextStyle(
              color: ColoresSaman.textoTenue,
              fontSize: 13,
            ),
          ),
          items: [
            for (final opcion in opciones)
              DropdownMenuItem(
                value: opcion,
                child: Text(
                  opcion,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColoresSaman.azulOscuro,
                  ),
                ),
              ),
          ],
          onChanged: alCambiar,
          validator: validator,
        ),
      ],
    );
  }
}

/// Requisitos de la contraseña nueva, marcados a medida que se cumplen.
class RequisitosContrasena extends StatelessWidget {
  const RequisitosContrasena({super.key, required this.contrasena});

  final String contrasena;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final (texto, cumple) in Validadores.requisitosContrasena(
          contrasena,
        ))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cumple ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 15,
                color: cumple ? ColoresSaman.verde : ColoresSaman.textoTenue,
              ),
              const SizedBox(width: 4),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 11.5,
                  color: cumple
                      ? ColoresSaman.verde
                      : ColoresSaman.textoSecundario,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
