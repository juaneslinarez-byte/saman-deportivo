import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/validadores.dart';
import '../modelos/modelos.dart';
import '../modelos/resena.dart';
import '../repositorios/repositorios.dart';

enum ResenaEstado { inicial, cargando, listo, error }

class ResenaViewModel extends ChangeNotifier {
  final ResenaRepository _resenaRepository;

  ResenaViewModel(this._resenaRepository);

  ResenaEstado _estado = ResenaEstado.inicial;
  Resena? _miResena;
  int _calificacion = 5;
  String _comentario = '';
  bool _guardando = false;
  String? _error;
  StreamSubscription<Resena?>? _sub;

  ResenaEstado get estado => _estado;
  Resena? get miResena => _miResena;
  int get calificacion => _calificacion;
  String get comentario => _comentario;
  bool get guardando => _guardando;
  String? get error => _error;

  bool get esEdicion => _miResena != null;

  bool get hayCambios {
    if (_miResena == null) {
      return _comentario.trim().isNotEmpty || _calificacion != 5;
    }
    return _miResena!.calificacion != _calificacion ||
        _miResena!.comentario != _comentario.trim();
  }

  bool get puedeGuardar {
    if (_guardando) return false;
    if (_calificacion < 1 || _calificacion > 5) return false;
    final validacion = Validadores.comentarioResena(_comentario);
    if (validacion != null) return false;
    return hayCambios;
  }

  void cargar(String idEstudiante, String idDeporte) {
    _estado = ResenaEstado.cargando;
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _resenaRepository
        .observarMia(idEstudiante, idDeporte)
        .listen(
          (resena) {
            _miResena = resena;
            if (resena != null) {
              _calificacion = resena.calificacion;
              _comentario = resena.comentario;
            }
            _estado = ResenaEstado.listo;
            notifyListeners();
          },
          onError: (Object _) {
            _estado = ResenaEstado.error;
            _error = 'No se pudo cargar tu reseña.';
            notifyListeners();
          },
        );
  }

  void setCalificacion(int nueva) {
    if (_calificacion == nueva) return;
    _calificacion = nueva;
    notifyListeners();
  }

  void setComentario(String nuevo) {
    _comentario = nuevo;
    notifyListeners();
  }

  Future<bool> guardar(String idEstudiante, String idDeporte) async {
    final validacion = Validadores.comentarioResena(_comentario);
    if (validacion != null) {
      _error = validacion;
      notifyListeners();
      return false;
    }

    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _resenaRepository.guardar(
        idEstudiante,
        idDeporte,
        _calificacion,
        _comentario.trim(),
      );
      _guardando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _guardando = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar() async {
    final resena = _miResena;
    if (resena == null) return false;

    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _resenaRepository.eliminar(resena);
      _guardando = false;
      _miResena = null;
      _comentario = '';
      _calificacion = 5;
      notifyListeners();
      return true;
    } catch (e) {
      _guardando = false;
      _error = 'No se pudo eliminar la reseña.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
