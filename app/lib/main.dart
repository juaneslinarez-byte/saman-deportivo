import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/repositorios/repositorios.dart';
import 'package:saman_deportivo/vistas/viewmodels/auth_viewmodel.dart';
import 'package:saman_deportivo/vistas/viewmodels/perfil_viewmodel.dart';

void main() {
  runApp(const SamanDeportivoApp());
}

// Implementaciones temporales, que evitan que la aplicaión cierre
class MockAuthRepository implements AuthRepository {
  @override
  //Dice null porque no hay sesion activa inicialmene
  Stream<String?> observarSesion() => Stream.value(null);
  @override
  String? get idUsuarioActual => null;
  @override
  Future<String> registrar({required String correo, required String contrasena}) async => '123';
  @override
  Future<String> iniciarSesion({required String correo, required String contrasena}) async => '123';
  @override
  Future<void> cerrarSesion() async {}
  @override
  Future<void> enviarCorreoRecuperacion(String correo) async {}
}

class MockUsuarioRepository implements UsuarioRepository {
  @override
  Future<Persona?> obtener(String id) async => null;
  @override
  Stream<Persona?> observar(String id) => Stream.value(null);
  @override
  Future<void> crear(Persona persona) async {}
  @override
  Future<void> actualizarPerfil(Persona persona) async {}
  @override
  Future<List<Persona>> listar({Actor? actor}) async => [];
}
//Widget principal
class SamanDeportivoApp extends StatelessWidget {
  const SamanDeportivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //Reemplazamos las implementaciones temporales por las clases reales
        Provider<AuthRepository>(
          create: (_) => MockAuthRepository(),
        ),
        Provider<UsuarioRepository>(
          create: (_) => MockUsuarioRepository(),
        ),
        
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        
        ChangeNotifierProxyProvider<AuthViewModel, PerfilViewModel>(
          create: (context) => PerfilViewModel(
            usuarioRepository: context.read<UsuarioRepository>(),
          ),
          update: (context, authVM, perfilVM) {
            
            Future.microtask(() {
              perfilVM?.actualizarSesion(authVM.idUsuarioActual);
            });
            return perfilVM!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Samán Deportivo',
        home: const Scaffold(
          body: Center(child: Text('App Inicializada Correctamente')),
        ),
      ),
    );
  }
}