import 'package:flutter/foundation.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';

class PerfilViewModel extends ChangeNotifier {
  final UsuarioRepository usuarioRepository;

  bool _cargando = false;
  String? _error;

  PerfilViewModel({required this.usuarioRepository});

  bool get cargando => _cargando;
  String? get error => _error;

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
}
