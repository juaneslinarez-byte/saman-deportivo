import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/modelos.dart';
import '../repositorios/deporte_repository.dart';

class SesionesCuposViewModel extends ChangeNotifier {
  final DeporteRepository _deporteRepository;
  Deporte deporte;

  StreamSubscription<List<Sesion>>? _sesionesSub;
  List<Sesion> _sesiones = [];
  bool _cargando = true;
  String? _error;

  List<Sesion> get sesiones => _sesiones;
  bool get cargando => _cargando;
  String? get error => _error;

  SesionesCuposViewModel({
    required this.deporte,
    required this._deporteRepository,
  }) {
    _iniciarEscucha();
  }

  void _iniciarEscucha() {
    _cargando = true;
    notifyListeners();

    _sesionesSub = _deporteRepository
        .observarSesiones(deporte.id)
        .listen(
          (lista) {
            _sesiones = List.from(lista)
              ..sort((a, b) {
                final compDia = _pesoDia(a.dia).compareTo(_pesoDia(b.dia));
                if (compDia != 0) return compDia;
                return a.horaInicio.compareTo(b.horaInicio);
              });
            _cargando = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _cargando = false;
            _error = 'No se pudieron cargar las sesiones.';
            notifyListeners();
          },
        );
  }

  int _pesoDia(DiaSemana dia) {
    return dia.index;
  }

  DiaSemana parseDiaSemana(String diaStr) {
    final limpio = diaStr.trim().toLowerCase();
    for (final d in DiaSemana.values) {
      if (d.name.toLowerCase() == limpio) return d;
    }
    if (limpio.contains('mi')) {
      return DiaSemana.values.firstWhere(
        (d) =>
            d.name.toLowerCase().contains('mier') ||
            d.name.toLowerCase().contains('miér'),
        orElse: () => DiaSemana.values[2],
      );
    }
    if (limpio.contains('sab') || limpio.contains('sáb')) {
      return DiaSemana.values.firstWhere(
        (d) =>
            d.name.toLowerCase().contains('sab') ||
            d.name.toLowerCase().contains('sáb'),
        orElse: () => DiaSemana.values[5],
      );
    }
    return DiaSemana.values.firstWhere(
      (d) => d.name.toLowerCase() == limpio,
      orElse: () => DiaSemana.values.first,
    );
  }

  bool _esFormatoHoraValido(String hora) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(hora.trim());
  }

  int _horaAMinutos(String hora) {
    final partes = hora.trim().split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  String? validarSesion({
    required String dia,
    required String horaInicio,
    required String horaFin,
    required String lugar,
    String? idSesionEditar,
  }) {
    if (lugar.trim().isEmpty) {
      return 'El lugar es obligatorio.';
    }
    if (!_esFormatoHoraValido(horaInicio) || !_esFormatoHoraValido(horaFin)) {
      return 'El formato de hora debe ser HH:MM (ej. 08:00, 14:30).';
    }

    final inicioMin = _horaAMinutos(horaInicio);
    final finMin = _horaAMinutos(horaFin);

    if (finMin <= inicioMin) {
      return 'La hora de fin debe ser posterior a la hora de inicio.';
    }

    final diaEnum = parseDiaSemana(dia);

    for (final s in _sesiones) {
      if (idSesionEditar != null && s.id == idSesionEditar) continue;

      if (s.dia == diaEnum) {
        final sInicio = _horaAMinutos(s.horaInicio);
        final sFin = _horaAMinutos(s.horaFin);

        final haySolapamiento = (inicioMin < sFin) && (finMin > sInicio);
        if (haySolapamiento) {
          return 'Se solapa con la sesión existente (${s.horaInicio} -${s.horaFin}) del mismo día.';
        }
      }
    }
    return null;
  }

  Future<void> guardarSesion({
    String? id,
    required String dia,
    required String horaInicio,
    required String horaFin,
    required String lugar,
  }) async {
    final sesion = Sesion(
      id: id ?? '',
      idDeporte: deporte.id,
      dia: parseDiaSemana(dia),
      horaInicio: horaInicio.trim(),
      horaFin: horaFin.trim(),
      lugar: lugar.trim(),
    );

    if (id == null || id.isEmpty) {
      await _deporteRepository.crearSesion(sesion);
    } else {
      await _deporteRepository.actualizarSesion(sesion);
    }
  }

  Future<bool> eliminarSesion(Sesion sesion) async {
    await _deporteRepository.eliminarSesion(sesion.id);

    if (_sesiones.length <= 1 && deporte.visible) {
      deporte = deporte.copyWith(visible: false);
      await _deporteRepository.actualizar(deporte);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> actualizarCupoMaximo(int nuevoCupo) async {
    if (nuevoCupo <= 0) {
      throw Exception('Escribe un cupo mayor que 0.');
    }
    if (nuevoCupo > 999) {
      throw Exception('El cupo máximo es 999.');
    }
    if (nuevoCupo < deporte.inscritos) {
      throw Exception(
        'El cupo máximo no puede ser menor que los inscritos actuales (${deporte.inscritos}).',
      );
    }

    final cuposDisponibles = nuevoCupo - deporte.inscritos;
    final deporteActualizado = deporte.copyWith(
      cupoMaximo: nuevoCupo,
      cuposDisponibles: cuposDisponibles,
    );

    await _deporteRepository.actualizar(deporteActualizado);
    deporte = deporteActualizado;
    notifyListeners();
  }

  @override
  void dispose() {
    _sesionesSub?.cancel();
    super.dispose();
  }
}
