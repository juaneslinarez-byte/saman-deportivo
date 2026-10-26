import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  //Guarda la suscripción en caso de destrucción del Viewmodel
  StreamSubscription<String?>? _sesionSubscription;
  //Guarda el Id del usuario
  String? _idUsuarioActual;

  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    //Actualiza constantemente los cambio en la sesión
    _sesionSubscription = _authRepository.observarSesion().listen((id) {
      _idUsuarioActual = id;
      //En caso de cambio, notifica a la interfaz
      notifyListeners();
    });
  }
  //Muestra el Id a otras partes de la app
  String? get idUsuarioActual => _idUsuarioActual;
  //confirma sí hay un usuario activo
  bool get estaAutenticado => _idUsuarioActual != null;

  @override
  void dispose() {
    _sesionSubscription?.cancel();
    super.dispose();
  }
}
