import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

/// Estado de la carga del perfil.
enum PerfilEstado { inicial, cargando, exito, error }

class PerfilViewModel extends ChangeNotifier {
  final UsuarioRepository usuarioRepository;

  bool _cargando = false;
  String? _error;

  // Patrón Observador: el perfil llega en tiempo real desde Firestore.
  StreamSubscription<Persona?>? _perfilSubscription;
  String? _idUsuario;
  Persona? _perfil;
  PerfilEstado _estado = PerfilEstado.inicial;

  PerfilViewModel({required this.usuarioRepository});

  bool get cargando => _cargando;
  String? get error => _error;
  Persona? get perfil => _perfil;
  PerfilEstado get estado => _estado;

  /// La llama el ProxyProvider de main.dart cada vez que cambia la sesión.
  void actualizarSesion(String? idUsuario) {
    // Si el usuario no cambió, el perfil ya se está observando.
    if (idUsuario == _idUsuario && _estado != PerfilEstado.inicial) return;
    _idUsuario = idUsuario;
    _perfilSubscription?.cancel();

    // Al cerrar la sesión se limpian los datos.
    if (idUsuario == null) {
      _perfil = null;
      _estado = PerfilEstado.inicial;
      notifyListeners();
      return;
    }

    _estado = PerfilEstado.cargando;
    notifyListeners();
    _perfilSubscription = usuarioRepository
        .observar(idUsuario)
        .listen(
          (persona) {
            _perfil = persona;
            _estado = PerfilEstado.exito;
            notifyListeners();
          },
          onError: (Object e) {
            _error = 'No se pudo cargar el perfil.';
            _estado = PerfilEstado.error;
            notifyListeners();
          },
        );
  }

  Future<bool> guardarCambios(Persona persona) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await usuarioRepository.actualizarPerfil(persona);
      return true;
    } on ErrorAutenticacion catch (e) {
      _error = e.mensaje;
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _perfilSubscription?.cancel();
    super.dispose();
  }
}
