import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

enum PerfilEstado { inicial, cargando, exito, error }

class PerfilViewModel extends ChangeNotifier {
  final UsuarioRepository _usuarioRepository;
  StreamSubscription<Persona?>? _perfilSubscription;

  Persona? _perfil;
  PerfilEstado _estado = PerfilEstado.inicial;
  String? _error;

  PerfilViewModel({required UsuarioRepository usuarioRepository})
    : _usuarioRepository = usuarioRepository;

  Persona? get perfil => _perfil;
  PerfilEstado get estado => _estado;
  String? get error => _error;

  //Es usado por ProxyProvider cuando cambia laautenticación
  void actualizarSesion(String? idUsuario) {
    _perfilSubscription?.cancel();
    //Le avisa a la interfaz que se cerró la sesión, además limpia los dato
    if (idUsuario == null) {
      _perfil = null;
      _estado = PerfilEstado.inicial;
      notifyListeners();
      return;
    }

    _estado = PerfilEstado.cargando;
    notifyListeners();

    _perfilSubscription = _usuarioRepository
        .observar(idUsuario)
        .listen(
          (persona) {
            _perfil = persona;
            _estado = PerfilEstado.exito;
            notifyListeners();
          },
          onError: (e) {
            //Se usa solo en caso de falla
            _error = e.toString();
            _estado = PerfilEstado.error;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _perfilSubscription?.cancel();
    super.dispose();
  }
}
