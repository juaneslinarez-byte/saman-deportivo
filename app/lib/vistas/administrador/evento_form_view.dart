import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/catalogos.dart';
import '../../core/colores.dart';
import '../../core/eventos.dart';
import '../../core/formatos.dart';
import '../../core/validadores.dart';
import '../../modelos/modelos.dart';
import '../../viewmodels/admin_eventos_viewmodel.dart';
import '../comun/campos_formulario.dart';

/// Formulario para publicar o editar un evento. Todos los datos se validan:
/// la fecha tiene que ser futura, el cupo no puede quedar por debajo de lo
/// ya reservado y lo que se elige de una lista no se escribe a mano.
class EventoFormView extends StatefulWidget {
  const EventoFormView({super.key, this.evento});

  final Evento? evento;

  @override
  State<EventoFormView> createState() => _EventoFormViewState();
}

class _EventoFormViewState extends State<EventoFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late final TextEditingController _cupo;
  late final TextEditingController _monto;

  String? _lugar;
  DateTime? _inicio;
  int? _duracion;
  int _maxPorReserva = 1;
  String? _idDeporte;

  /// Opción «sin disciplina» de la lista de disciplinas.
  static const _ninguna = 'Ninguna';

  bool get _esEdicion => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    _titulo = TextEditingController(text: e?.titulo ?? '');
    _descripcion = TextEditingController(text: e?.descripcion ?? '');
    _cupo = TextEditingController(text: e == null ? '' : '${e.cupo}');
    _monto = TextEditingController(
      text: e == null
          ? ''
          : e.monto == e.monto.roundToDouble()
          ? e.monto.toStringAsFixed(0)
          : e.monto.toStringAsFixed(2).replaceAll('.', ','),
    );
    _lugar = e?.lugar;
    _inicio = e?.inicio;
    _duracion = e?.duracionMinutos;
    _maxPorReserva = e?.maxPorReserva ?? 1;
    _idDeporte = e?.idDeporte;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _cupo.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _elegirInicio(FormFieldState<DateTime> campo) async {
    final ahora = DateTime.now();
    final base = _inicio ?? ahora.add(const Duration(days: 1));
    final dia = await showDatePicker(
      context: context,
      initialDate: base.isBefore(ahora) ? ahora : base,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 365)),
      helpText: 'Fecha del evento',
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio ?? DateTime(0, 1, 1, 16)),
      helpText: 'Hora de inicio',
    );
    if (hora == null) return;
    final elegido = DateTime(
      dia.year,
      dia.month,
      dia.day,
      hora.hour,
      hora.minute,
    );
    setState(() => _inicio = elegido);
    campo.didChange(elegido);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AdminEventosViewModel>();
    final cupo = int.parse(_cupo.text.trim());
    final evento = Evento(
      id: widget.evento?.id ?? '',
      titulo: Formatos.espacios(_titulo.text),
      descripcion: _descripcion.text.trim(),
      lugar: _lugar!,
      inicio: _inicio!,
      duracionMinutos: _duracion!,
      cupo: cupo,
      cuposDisponibles: cupo,
      monto: FormatoEvento.leerMonto(_monto.text),
      maxPorReserva: _maxPorReserva,
      idDeporte: _idDeporte,
    );
    final error = await vm.guardar(evento, nuevo: !_esEdicion);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (_esEdicion ? 'Evento actualizado.' : 'Evento publicado.'),
        ),
        backgroundColor: error == null ? ColoresSaman.verde : ColoresSaman.rojo,
      ),
    );
    if (error == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminEventosViewModel>();
    final reservados = widget.evento?.reservados ?? 0;
    final deportes = vm.deportes;
    final nombresDeportes = [_ninguna, for (final d in deportes) d.nombre];
    String? nombreDeporte;
    for (final d in deportes) {
      if (d.id == _idDeporte) nombreDeporte = d.nombre;
    }

    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar evento' : 'Nuevo evento',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CampoTexto(
                  etiqueta: 'Título',
                  controller: _titulo,
                  pista: 'Ej. Copa UNIMET de fútbol sala',
                  formateadores: [LengthLimitingTextInputFormatter(60)],
                  validator: Validadores.tituloEvento,
                ),
                const SizedBox(height: 16),
                const _Etiqueta('Descripción'),
                TextFormField(
                  controller: _descripcion,
                  minLines: 3,
                  maxLines: 6,
                  inputFormatters: [LengthLimitingTextInputFormatter(300)],
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColoresSaman.azulOscuro,
                  ),
                  decoration: decoracionCampo(
                    pista: 'Qué se hará, para quién es y qué hay que llevar',
                    ayuda: 'De 10 a 300 caracteres',
                  ),
                  validator: Validadores.descripcionEvento,
                ),
                const SizedBox(height: 16),
                CampoSeleccion(
                  etiqueta: 'Lugar',
                  opciones: Catalogos.lugaresEvento,
                  valor: _lugar,
                  alCambiar: (v) => setState(() => _lugar = v),
                  validator: (v) => Validadores.opcion(
                    v,
                    Catalogos.lugaresEvento,
                    campo: 'el lugar',
                  ),
                ),
                const SizedBox(height: 16),
                const _Etiqueta('Fecha y hora de inicio'),
                FormField<DateTime>(
                  initialValue: _inicio,
                  validator: (_) => Validadores.inicioEvento(_inicio),
                  builder: (campo) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _elegirInicio(campo),
                    child: InputDecorator(
                      decoration: decoracionCampo(
                        sufijo: const Icon(Icons.event_outlined),
                      ).copyWith(errorText: campo.errorText),
                      child: Text(
                        _inicio == null
                            ? 'Elige la fecha y la hora'
                            : FormatoEvento.fechaHora(_inicio!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _inicio == null
                              ? ColoresSaman.textoTenue
                              : ColoresSaman.azulOscuro,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CampoSeleccion(
                  etiqueta: 'Duración',
                  opciones: [
                    for (final m in Catalogos.duracionesEvento)
                      FormatoEvento.duracion(m),
                  ],
                  valor: _duracion == null
                      ? null
                      : FormatoEvento.duracion(_duracion!),
                  alCambiar: (v) => setState(() {
                    _duracion = Catalogos.duracionesEvento.firstWhere(
                      (m) => FormatoEvento.duracion(m) == v,
                    );
                  }),
                  validator: (v) => v == null ? 'Selecciona la duración' : null,
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Cupo (personas)',
                  controller: _cupo,
                  pista: 'De 1 a 500',
                  ayuda: reservados > 0
                      ? 'Ya hay $reservados reservados: no puede ser menor.'
                      : null,
                  teclado: TextInputType.number,
                  formateadores: Entradas.digitos(3),
                  validator: (v) {
                    final error = Validadores.enteroEntre(
                      v,
                      minimo: reservados > 0 ? reservados : 1,
                      maximo: 500,
                      campo: 'el cupo',
                    );
                    if (error != null) return error;
                    if (int.parse(v!.trim()) < _maxPorReserva) {
                      return 'Menor que las personas por reserva';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Precio por persona (\$)',
                  controller: _monto,
                  pista: '0 si es gratis',
                  teclado: const TextInputType.numberWithOptions(decimal: true),
                  formateadores: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: Validadores.montoEvento,
                ),
                const SizedBox(height: 16),
                CampoSeleccion(
                  etiqueta: 'Personas por reserva',
                  opciones: [
                    for (final n in Catalogos.personasPorReserva)
                      FormatoEvento.personas(n),
                  ],
                  valor: FormatoEvento.personas(_maxPorReserva),
                  alCambiar: (v) => setState(() {
                    _maxPorReserva = Catalogos.personasPorReserva.firstWhere(
                      (n) => FormatoEvento.personas(n) == v,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                CampoSeleccion(
                  etiqueta: 'Disciplina relacionada (opcional)',
                  opciones: nombresDeportes,
                  valor: nombreDeporte ?? _ninguna,
                  alCambiar: (v) => setState(() {
                    _idDeporte = null;
                    for (final d in deportes) {
                      if (d.nombre == v) _idDeporte = d.id;
                    }
                  }),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresSaman.naranja,
                      foregroundColor: ColoresSaman.blanco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: vm.guardando ? null : _guardar,
                    child: vm.guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ColoresSaman.blanco,
                            ),
                          )
                        : Text(
                            _esEdicion ? 'Guardar cambios' : 'Publicar evento',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}
